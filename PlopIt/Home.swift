//
//  Home.swift
//  PlopIt
//
//  Created by Batuhan Aydöner on 30.08.2026.
//

import SwiftUI

struct Home: View {
    @Environment(RouteViewModel.self) var routeView: RouteViewModel
    @Environment(LevelRepository.self) var levelRepo: LevelRepository

    @State private var isVisible = false
    @State private var toysBounce = false
    @State private var playPulse = false

    private var completedCount: Int {
        levelRepo.levels.filter(\.completed).count
    }

    var body: some View {
        ZStack {
            CosmicTheme.screenBackground
            floatingToys
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()
                titleBlock
                scoreBadge
                    .padding(.top, 22)
                Spacer()
                actionButtons
                    .padding(.horizontal, 32)
                Spacer(minLength: 36)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.68)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                toysBounce = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                playPulse = true
            }
        }
    }

    private var floatingToys: some View {
        ZStack {
            cosmicOrb(size: 92, colors: [CosmicTheme.holeBlack, CosmicTheme.neonPurple.opacity(0.8)])
                .overlay {
                    Circle()
                        .stroke(CosmicTheme.lilac.opacity(0.5), lineWidth: 2)
                        .frame(width: 118, height: 118)
                }
                .offset(x: -130, y: toysBounce ? -210 : -248)

            cosmicOrb(size: 54, colors: [CosmicTheme.cyan, CosmicTheme.electricBlue])
                .shadow(color: CosmicTheme.cyan.opacity(0.55), radius: 14, y: 0)
                .offset(x: 128, y: toysBounce ? -188 : -150)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(CosmicTheme.lilac, lineWidth: 2)
                }
                .frame(width: 92, height: 22)
                .shadow(color: CosmicTheme.neonPurple.opacity(0.45), radius: 8, y: 0)
                .rotationEffect(.degrees(toysBounce ? 16 : -10))
                .offset(x: 118, y: toysBounce ? 210 : 178)

            cosmicOrb(size: 36, colors: [CosmicTheme.holeBlack, CosmicTheme.neonPink.opacity(0.7)])
                .offset(x: -150, y: toysBounce ? 160 : 190)

            cosmicOrb(size: 28, colors: [CosmicTheme.cyan.opacity(0.9), CosmicTheme.lilac])
                .offset(x: -40, y: toysBounce ? -300 : -270)
        }
        .opacity(isVisible ? 1 : 0)
    }

    private func cosmicOrb(size: CGFloat, colors: [Color]) -> some View {
        Circle()
            .fill(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .fill(.white.opacity(0.35))
                    .frame(width: size * 0.28, height: size * 0.28)
                    .offset(x: -size * 0.18, y: -size * 0.18)
            }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("PlopIt!")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(CosmicTheme.titleGradient)
                .shadow(color: CosmicTheme.cyan.opacity(0.55), radius: 16, y: 0)
                .shadow(color: CosmicTheme.neonPurple.opacity(0.35), radius: 28, y: 8)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -5)
        .scaleEffect(isVisible ? 1 : 0.86)
    }

    private var scoreBadge: some View {
        HStack(spacing: 18) {
            badgeChip(icon: "star.fill", value: "\(levelRepo.totalScore)", label: "SCORE", tint: CosmicTheme.lilac)
            badgeChip(icon: "flag.fill", value: "\(completedCount)", label: "LEVELS", tint: CosmicTheme.cyan)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
    }

    private func badgeChip(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.black))
                Text(label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cosmicGlass(cornerRadius: 22, stroke: tint.opacity(0.45))
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                if let id = levelRepo.firstPlayableLevelId() {
                    routeView.navigateToGame(levelId: id)
                }
            } label: {
                Text("PLAY")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(CosmicTheme.playGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    }
                    .shadow(color: CosmicTheme.cyan.opacity(0.55), radius: 16, y: 0)
                    .shadow(color: CosmicTheme.electricBlue.opacity(0.35), radius: 0, y: 8)
            }
            .buttonStyle(ShrinkButtonStyle())
            .scaleEffect(playPulse ? 1.04 : 0.98)

            secondaryButton("Levels") {
                routeView.navigateToLevels()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 90)
    }

    private func secondaryButton(_ title: String, stroke: Color = CosmicTheme.neonPurple.opacity(0.6), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(stroke, lineWidth: 1.5)
                }
        }
        .buttonStyle(ShrinkButtonStyle())
    }
}

#Preview {
    Home()
        .environment(RouteViewModel())
        .environment(LevelRepository())
}
