//
//  RaccApp.swift
//  Racc
//
//  Created by Erik Werner on 23.05.25.
//

import SwiftUI

@main
struct DJApp: App {
    @StateObject private var audioManager = AudioManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .background(Theme.background.ignoresSafeArea())
                .tint(Theme.deckA)
        }
    }
}

