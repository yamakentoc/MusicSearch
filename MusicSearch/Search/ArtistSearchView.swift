//
//  ContentView.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/03.
//

import SwiftUI
import ComposableArchitecture

struct ArtistSearchReducer: Reducer {
    struct State: Equatable {
        var searchArtistName = ""
        var results: [ArtistSearch.Result] = []
    }
    
    enum Action: Equatable {
        case searchArtistNameChanged(String)
        case searchArtist
        case searchResponse(TaskResult<ArtistSearch>)
    }
    
    @Dependency(\.itunesClient) var itunesClient
    @Dependency(\.mainQueue) var mainQueue
    private enum CancelID { case searchArtist }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .searchArtistNameChanged(artistName):
            state.searchArtistName = artistName
            guard !artistName.isEmpty else {
                state.results = []
                return .cancel(id: CancelID.searchArtist)
            }
            return .run { send in
                await send(.searchArtist)
            }
            .debounce(id: CancelID.searchArtist, for:0.5, scheduler: mainQueue)
        case .searchArtist:
            guard !state.searchArtistName.isEmpty else {
                return .none
            }
            return .run { [artistName = state.searchArtistName] send in
                await send(.searchResponse(TaskResult { try await self.itunesClient.searchArtist(artistName) }))
            }
            .cancellable(id: CancelID.searchArtist)
        case let .searchResponse(.success(response)):
            state.results = response.results
            return .none
        case .searchResponse(.failure):
            state.results = []
            return .none
        }
    }
}

struct ArtistSearchView: View {
    let store: StoreOf<ArtistSearchReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                List {
                    ForEach(viewStore.results) { result in
                        NavigationLink(result.name) {
                            Text(result.name)
                        }
                    }
                }
                .searchable(text: viewStore.binding(get: \.searchArtistName, send: ArtistSearchReducer.Action.searchArtistNameChanged))
            }
            .navigationTitle("Search")
        }
    }
}

#Preview {
    ArtistSearchView(store: Store(initialState: ArtistSearchReducer.State()) {
        ArtistSearchReducer()
    })
}
