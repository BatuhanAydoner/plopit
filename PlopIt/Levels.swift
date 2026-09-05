//
//  Levels.swift
//  PlopIt
//
//  Created by Batuhan Aydöner on 31.08.2026.
//

import SwiftUI

struct Levels: View {
    @Environment(LevelRepository.self) var levelRepo: LevelRepository
    @Environment(RouteViewModel.self) var routeVM: RouteViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    private var completedCount: Int {
        levelRepo.levels.filter(\.completed).count
    }

    private var currentLevelId: Int? {
        levelRepo.firstPlayableLevelId()
    }

    var body: some View {
        ZStack {
            CosmicTheme.screenBackground

            VStack(spacing: 16) {
                header
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(levelRepo.levels) { level in
                            LevelCell(
                                level: level,
                                isUnlocked: levelRepo.isUnlocked(level.id),
                                isCurrent: level.id == currentLevelId
                            ) {
                                routeVM.navigateToGame(levelId: level.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .padding(.top, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(CosmicTheme.dangerGradient, in: Circle())
                        .overlay(Circle().stroke(CosmicTheme.neonPink.opacity(0.7), lineWidth: 1.5))
                        .shadow(color: CosmicTheme.neonPink.opacity(0.35), radius: 8, y: 0)
                }
                .buttonStyle(ShrinkButtonStyle())

                Spacer()

                Text("Levels")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(CosmicTheme.titleGradient)
                    .shadow(color: CosmicTheme.cyan.opacity(0.4), radius: 10, y: 0)

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                headerChip(icon: "star.fill", value: "\(levelRepo.totalScore)", label: "SCORE", tint: CosmicTheme.lilac)
                headerChip(
                    icon: "flag.fill",
                    value: "\(completedCount)/\(levelRepo.levels.count)",
                    label: "DONE",
                    tint: CosmicTheme.cyan
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func headerChip(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.black))
                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cosmicGlass(cornerRadius: 18, stroke: tint.opacity(0.45))
    }
}

private struct LevelCell: View {
    let level: Level
    let isUnlocked: Bool
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(level.id)")
                    .font(.system(.title3, design: .rounded).weight(.black))
                statusLabel
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background {
                Group {
                    if level.completed {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(CosmicTheme.playGradient)
                    } else if isUnlocked {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: isCurrent ? 2.5 : 1.5)
            }
            .shadow(color: glowColor, radius: isCurrent ? 10 : 0, y: 0)
            .opacity(isUnlocked ? 1 : 0.55)
        }
        .buttonStyle(ShrinkButtonStyle())
        .disabled(!isUnlocked)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if level.completed, let throwsUsed = level.throwsToComplete {
            Text("\(throwsUsed) throws")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
        } else if !isUnlocked {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(CosmicTheme.lilac.opacity(0.8))
        } else if isCurrent {
            Text("NOW")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(CosmicTheme.cyan)
        } else {
            Text("OPEN")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .opacity(0.75)
        }
    }

    private var borderColor: Color {
        if isCurrent { return CosmicTheme.cyan }
        if level.completed { return CosmicTheme.cyan.opacity(0.55) }
        if isUnlocked { return CosmicTheme.neonPurple.opacity(0.55) }
        return Color.white.opacity(0.12)
    }

    private var glowColor: Color {
        isCurrent ? CosmicTheme.cyan.opacity(0.45) : .clear
    }
}

#Preview {
    Levels()
        .environment(RouteViewModel())
        .environment(LevelRepository())
}
