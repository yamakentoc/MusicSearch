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
            ArtistSearchView(store: Store(initialState: ArtistSearchReducer.State()) {
                ArtistSearchReducer()
                    ._printChanges()
            })
        }
    }
}
