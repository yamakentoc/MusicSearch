//
//  ItunesClient.swift
//  MusicSearch
//
//  Created by 山口賢登 on 2023/11/03.
//

import Foundation
import ComposableArchitecture

// MARK: - API models

struct ArtistSearchResult: Codable {
    var results: [Artist]
}

struct Artist: Codable, Equatable {
    var name: String
    var id = UUID()
}

extension Artist {
    private enum CodingKeys: String, CodingKey {
        case name = "artistName"
    }
}

struct FetchAlbumResult: Codable {
    var results: [Album]
}

struct Album: Codable, Equatable {
    var name: String
    var artworkURL: String
    var id = UUID()
}

extension Album {
    private enum CodingKeys: String, CodingKey {
        case name = "collectionName"
        case artworkURL = "artworkUrl100"
    }
}

// MARK: - API client interface

struct ItunesClient {
    var searchArtist: @Sendable (String) async throws -> [Artist]
    var fetchAlbum: @Sendable (String) async throws -> [Album]
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
                URLQueryItem(name: "country", value: "jp"),
                URLQueryItem(name: "lang", value: "ja_jp"),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "musicArtist"),
                URLQueryItem(name: "attribute", value: "artistTerm"),
                URLQueryItem(name: "limit", value: "10"),
                URLQueryItem(name: "term", value: artistName),
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try JSONDecoder().decode(ArtistSearchResult.self, from: data).results
        },
        fetchAlbum: { artistName in
            var components = URLComponents(string: "https://itunes.apple.com/search")!
            components.queryItems = [
                URLQueryItem(name: "country", value: "jp"),
                URLQueryItem(name: "lang", value: "ja_jp"),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "album"),
                URLQueryItem(name: "attribute", value: "artistTerm"),
                URLQueryItem(name: "term", value: artistName),
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try JSONDecoder().decode(FetchAlbumResult.self, from: data).results
        }
    )
    
}

// MARK: - Preview data

extension ItunesClient: TestDependencyKey {
    static let previewValue = Self(
        searchArtist: { _ in [] },
        fetchAlbum: { _ in [] }
    )
    
    static let testValue = Self(
        searchArtist: unimplemented("\(Self.self).searchArtist"),
        fetchAlbum: unimplemented("\(Self.self).fetchAlbum")
    )
}

extension Artist {
    static func mock(id: UUID) -> Self {
        .init(name: "artist", id: id)
    }
}

extension Album {
    static func mock(id: UUID) -> Self {
        .init(name: "album", artworkURL: "sample.com", id: id)
    }
}
