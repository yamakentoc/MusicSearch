//
//  ArtistSearchRow.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/04.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct ArtistSearchRowReducer: Reducer {
    public struct State: Equatable, Identifiable {
        let artist: Artist
        public var id: UUID { artist.id }
    }
    
    public enum Action: Equatable {
        case rowTapped
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case rowTapped
        }
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .rowTapped:
                return .send(.delegate(.rowTapped))
            case .delegate:
                return .none
            }
        }
    }
}

struct ArtistSearchRow: View {
    let store: StoreOf<ArtistSearchRowReducer>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Button {
                viewStore.send(.rowTapped)
            } label: {
                Text(viewStore.artist.name)
            }
        }
    }
}

#Preview {
    ArtistSearchRow(store: Store(initialState: ArtistSearchRowReducer.State(artist: .mock(id: UUID(1)))) {
        ArtistSearchRowReducer()
    })
}
