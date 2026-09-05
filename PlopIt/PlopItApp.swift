//
//  PlopItApp.swift
//  PlopIt
//
//  Created by Batuhan Aydöner on 30.08.2026.
//

import SwiftUI

@main
struct PlopItApp: App {
    @State private var routeView = RouteViewModel()
    @State private var levelRepository = LevelRepository()

    init() {
        AdsManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
        }
        .environment(routeView)
        .environment(levelRepository)
    }
}
