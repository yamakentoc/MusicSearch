//
//  ArtistDetailView.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/04.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct ArtistDetailReducer: Reducer {
    struct State: Equatable {
        var artist: Artist
        var results: [Album] = []
    }
    
    enum Action: Equatable {
        case fetchAlbum
        case fetchAlbumResponse(TaskResult<[Album]>)
    }
    
    @Dependency(\.itunesClient) var itunesClient
    
    private enum CancelID {
        case fetchAlbum
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .fetchAlbum:
         //   return .run { [artistName = "Hilcrhyme"] send in
           //     await send(.fetchAlbumResponse(TaskResult { try await self.itunesClient.fetchAlbum(artistName) }))
         //   }
          //  .cancellable(id: CancelID.fetchAlbum)
            return .none
        case let .fetchAlbumResponse(.success(response)):
          //  state.results = response.results
            return .none
        case .fetchAlbumResponse(.failure):
            state.results = []
            return .none
        }
    }
    
}

struct ArtistDetailView: View {
    let store: StoreOf<ArtistDetailReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Text(viewStore.artist.name)
        }
    }
}

#Preview {
    ArtistDetailView(store: Store(initialState: ArtistDetailReducer.State(artist: .mock(id: UUID(1)))) {
        ArtistDetailReducer()
    })
}
