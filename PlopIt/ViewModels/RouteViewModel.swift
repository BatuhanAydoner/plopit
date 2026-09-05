import Foundation
import SwiftData
import SwiftUI

@Observable
final class RouteViewModel {
    var navigationPath = NavigationPath()
    
    func navigateToGame(levelId: Int) {
        navigationPath.append(Routes.Game(levelId: levelId))
    }
    
    func navigateToSettings() {
        navigationPath.append(Routes.Settings)
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func navigateToLevels() {
        navigationPath.append(Routes.Levels)
    }

    func navigateToEditor() {
        navigationPath.append(Routes.Editor)
    }
}
