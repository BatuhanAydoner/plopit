import Foundation

enum AdMobConfig {
    /// Live units — used in Release / Archive builds.
    private static let productionInterstitialAdUnitID =
        "ca-app-pub-4518174079467228/9000018421"

    private static let productionRewardedAdUnitID =
        "ca-app-pub-4518174079467228/8393513765"

    /// Google sample units — Debug only (never click your own live ads while developing).
    private static let testInterstitialAdUnitID =
        "ca-app-pub-3940256099942544/4411468910"

    private static let testRewardedAdUnitID =
        "ca-app-pub-3940256099942544/1712485313"

#if DEBUG
    static let useTestAds = true
#else
    static let useTestAds = false
#endif

    static var interstitialAdUnitID: String {
        useTestAds ? testInterstitialAdUnitID : productionInterstitialAdUnitID
    }

    static var rewardedAdUnitID: String {
        useTestAds ? testRewardedAdUnitID : productionRewardedAdUnitID
    }

    static let continueThrowBonus = 5
}
