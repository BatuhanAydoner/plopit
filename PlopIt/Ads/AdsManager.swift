import GoogleMobileAds
import UIKit

@MainActor
final class AdsManager: NSObject {
    static let shared = AdsManager()

    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?

    private var isLoadingInterstitial = false
    private var isLoadingRewarded = false

    private var pendingInterstitialCompletion: (() -> Void)?
    private var pendingRewardedCompletion: ((Bool) -> Void)?
    private var didEarnRewarded = false

    /// Games finished since the last interstitial.
    private var gamesSinceLastAd = 0
    /// Next interstitial after 2 or 3 games (picked at random each cycle).
    private var gamesUntilNextAd = Int.random(in: 2...3)

    private override init() {
        super.init()
    }

    func start() {
        MobileAds.shared.start { _ in
            Task { @MainActor in
                self.preloadInterstitial()
                self.preloadRewarded()
            }
        }
    }

    // MARK: - Interstitial (periodic end-of-game)

    func preloadInterstitial() {
        guard interstitial == nil, !isLoadingInterstitial else { return }
        isLoadingInterstitial = true

        InterstitialAd.load(
            with: AdMobConfig.interstitialAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingInterstitial = false
                if let error {
                    print("AdMob interstitial failed to load: \(error.localizedDescription)")
                    self.interstitial = nil
                    return
                }
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
            }
        }
    }

    /// Call when a round ends. Shows an interstitial every 2–3 games (random).
    func showEndOfGameAdIfNeeded(completion: @escaping () -> Void) {
        gamesSinceLastAd += 1
        guard gamesSinceLastAd >= gamesUntilNextAd else {
            completion()
            return
        }

        gamesSinceLastAd = 0
        gamesUntilNextAd = Int.random(in: 2...3)
        presentInterstitial(completion: completion)
    }

    func presentInterstitial(completion: @escaping () -> Void) {
        if interstitial != nil {
            presentLoadedInterstitial(completion: completion)
            return
        }

        preloadInterstitial()

        Task { @MainActor in
            for _ in 0..<8 {
                try? await Task.sleep(for: .milliseconds(200))
                if interstitial != nil {
                    presentLoadedInterstitial(completion: completion)
                    return
                }
            }
            completion()
            preloadInterstitial()
        }
    }

    private func presentLoadedInterstitial(completion: @escaping () -> Void) {
        guard let interstitial,
              let root = Self.topViewController() else {
            completion()
            preloadInterstitial()
            return
        }

        pendingInterstitialCompletion = completion
        interstitial.present(from: root)
    }

    // MARK: - Rewarded (+throws continue)

    func preloadRewarded() {
        guard rewarded == nil, !isLoadingRewarded else { return }
        isLoadingRewarded = true

        RewardedAd.load(
            with: AdMobConfig.rewardedAdUnitID,
            request: Request()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingRewarded = false
                if let error {
                    print("AdMob rewarded failed to load: \(error.localizedDescription)")
                    self.rewarded = nil
                    return
                }
                self.rewarded = ad
                self.rewarded?.fullScreenContentDelegate = self
            }
        }
    }

    /// Presents rewarded ad. `completion(true)` only if the user earned the reward.
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        if rewarded != nil {
            presentLoadedRewarded(completion: completion)
            return
        }

        preloadRewarded()

        Task { @MainActor in
            for _ in 0..<10 {
                try? await Task.sleep(for: .milliseconds(200))
                if rewarded != nil {
                    presentLoadedRewarded(completion: completion)
                    return
                }
            }
            completion(false)
            preloadRewarded()
        }
    }

    private func presentLoadedRewarded(completion: @escaping (Bool) -> Void) {
        guard let rewarded,
              let root = Self.topViewController() else {
            completion(false)
            preloadRewarded()
            return
        }

        didEarnRewarded = false
        pendingRewardedCompletion = completion
        rewarded.present(from: root) { [weak self] in
            Task { @MainActor in
                self?.didEarnRewarded = true
            }
        }
    }

    // MARK: - Shared

    private static func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    private func finishInterstitialPending() {
        let completion = pendingInterstitialCompletion
        pendingInterstitialCompletion = nil
        completion?()
        preloadInterstitial()
    }

    private func finishRewardedPending() {
        let earned = didEarnRewarded
        didEarnRewarded = false
        let completion = pendingRewardedCompletion
        pendingRewardedCompletion = nil
        completion?(earned)
        preloadRewarded()
    }
}

extension AdsManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            if ad === interstitial {
                interstitial = nil
                finishInterstitialPending()
            } else if ad === rewarded {
                rewarded = nil
                finishRewardedPending()
            }
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            print("AdMob failed to present: \(error.localizedDescription)")
            if ad === interstitial {
                interstitial = nil
                finishInterstitialPending()
            } else if ad === rewarded {
                rewarded = nil
                finishRewardedPending()
            }
        }
    }
}
