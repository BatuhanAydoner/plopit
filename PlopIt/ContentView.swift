//
//  ContentView.swift
//  PlopIt
//
//  Created by Batuhan Aydöner on 30.08.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(RouteViewModel.self) var routeView: RouteViewModel

    var body: some View {
        @Bindable var bindableRouteView = routeView
        
        NavigationStack(path: $bindableRouteView.navigationPath) {
            Home()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(for: Routes.self) { route in
                    switch route {
                        case .Game(let levelId):
                            GameContentView(levelId: levelId)
                        case .Settings:
                            Text("Settings")
                    case .Levels:
                        Levels()
                    case .Editor:
                        LevelEditorView()
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(RouteViewModel())
        .environment(LevelRepository())
}
