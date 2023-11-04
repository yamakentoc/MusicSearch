//
//  ArtistSearchView.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/03.
//

import SwiftUI
import ComposableArchitecture

struct ArtistSearchReducer: Reducer {
    struct State: Equatable {
        var artistSearchName = ""
        var artistSearchRows: IdentifiedArrayOf<ArtistSearchRowReducer.State> = []
        var path = StackState<Path.State>()
    }
    
    enum Action: Equatable {
        case searchArtistNameChanged(String)
        case searchArtist
        case searchArtistResponse(TaskResult<[Artist]>)
        case artistSearchRows(id: ArtistSearchRowReducer.State.ID, action: ArtistSearchRowReducer.Action)
        case path(StackAction<Path.State, Path.Action>)
    }
    
    @Dependency(\.itunesClient) var itunesClient
    @Dependency(\.mainQueue) var mainQueue
    private enum CancelID { case searchArtist }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .searchArtistNameChanged(artistName):
                state.artistSearchName = artistName
                guard !artistName.isEmpty else {
                    state.artistSearchRows = []
                    return .cancel(id: CancelID.searchArtist)
                }
                return .run { send in
                    await send(.searchArtist)
                }
                .debounce(id: CancelID.searchArtist, for: .seconds(0.5), scheduler: mainQueue)
            case .searchArtist:
                guard !state.artistSearchName.isEmpty else {
                    return .none
                }
                return .run { [artistName = state.artistSearchName] send in
                    await send(.searchArtistResponse(TaskResult { try await itunesClient.searchArtist(artistName) }))
                }
                .cancellable(id: CancelID.searchArtist)
            case let .searchArtistResponse(.success(artists)):
                state.artistSearchRows = IdentifiedArray(uniqueElements: artists.map { .init(artist: $0) })
                return .none
            case .searchArtistResponse(.failure):
                state.artistSearchRows = []
                return .none
            case let .artistSearchRows(id, .delegate(.rowTapped)):
                guard let artist = state.artistSearchRows[id: id]?.artist else { return .none }
                state.path.append(.artistDetail(.init(artist: artist)))
                return .none
            case .artistSearchRows, .path:
                return .none
            }
        }
        .forEach(\.artistSearchRows, action: /Action.artistSearchRows(id:action:)) {
            ArtistSearchRowReducer()
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
}

extension ArtistSearchReducer {
    public struct Path: Reducer {
        public enum State: Equatable {
            case artistDetail(ArtistDetailReducer.State)
        }
        
        public enum Action: Equatable {
            case artistDetail(ArtistDetailReducer.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.artistDetail, action: /Action.artistDetail) {
                ArtistDetailReducer()
            }
        }
    }
}

struct ArtistSearchView: View {
    let store: StoreOf<ArtistSearchReducer>
    
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                List {
                    ForEachStore(store.scope(state: \.artistSearchRows, action: { .artistSearchRows(id: $0, action: $1)}), content: ArtistSearchRow.init(store:))
                }
                .searchable(text: viewStore.binding(get: \.artistSearchName, send: ArtistSearchReducer.Action.searchArtistNameChanged), prompt: "Artist")
                .navigationTitle("Search")
            }
        }  destination: { state in
            switch state {
            case .artistDetail:
                CaseLet(
                    /ArtistSearchReducer.Path.State.artistDetail,
                     action: ArtistSearchReducer.Path.Action.artistDetail,
                     then: ArtistDetailView.init(store:)
                )
            }
        }
    }
}

#Preview {
    ArtistSearchView(store: Store(initialState: ArtistSearchReducer.State()) {
        ArtistSearchReducer()
    })
}
