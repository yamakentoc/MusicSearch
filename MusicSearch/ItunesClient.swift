//
//  ItunesClient.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/03.
//

import Foundation
import ComposableArchitecture

// MARK: - API models

struct ArtistSearch: Decodable, Equatable, Sendable {
    var results: [Result]
    
    struct Result: Decodable, Equatable, Identifiable, Sendable {
        var name: String
        var id = UUID()
    }
}

extension ArtistSearch.Result {
    private enum CodingKeys: String, CodingKey {
        case name = "artistName"
    }
}

// MARK: - API client interface

struct ItunesClient {
    var searchArtist: @Sendable (String) async throws -> ArtistSearch
}

extension DependencyValues {
    var itunesClient: ItunesClient {
        get { self[ItunesClient.self] }
        set { self[ItunesClient.self] = newValue }
    }
}

// MARK: - Live API implementation

extension ItunesClient: DependencyKey {
    static let liveValue = Self(
        searchArtist: { artistName in
            var components = URLComponents(string: "https://itunes.apple.com/search")!
            components.queryItems = [
                URLQueryItem(name: "term", value: artistName),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "musicArtist"),
                URLQueryItem(name: "attribute", value: "artistTerm"),
                URLQueryItem(name: "lang", value: "ja_jp"),
                URLQueryItem(name: "limit", value: "10")
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try JSONDecoder().decode(ArtistSearch.self, from: data)
        }
    )
    
}

// MARK: - Preview data

extension ItunesClient: TestDependencyKey {
    static let previewValue = Self(
        searchArtist: { _ in .mock }
    )
    
    static let testValue = Self(
        searchArtist: unimplemented("\(Self.self).searchArtist")
    )
}

extension ArtistSearch {
    static let mock = Self(
        results: [
            ArtistSearch.Result(name: "ArtistName1", id: UUID(1)),
            ArtistSearch.Result(name: "ArtistName2", id: UUID(2)),
            ArtistSearch.Result(name: "ArtistName3", id: UUID(3))
        ]
    )
}
