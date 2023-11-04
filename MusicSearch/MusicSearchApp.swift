//
//  MusicSearchApp.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/03.
//

import SwiftUI
import ComposableArchitecture

@main
struct MusicSearchApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(store: Store(initialState: Search.State()) {
                Search()
                    ._printChanges()
            })
        }
    }
}
