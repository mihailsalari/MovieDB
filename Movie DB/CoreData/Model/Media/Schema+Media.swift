//
//  Schema+Media.swift
//  Movie DB
//
//  Created by Jonas Frey on 04.03.23.
//  Copyright © 2023 Jonas Frey. All rights reserved.
//

protocol SchemaEntityKey: CVarArg {
    static var _entityName: String { get }
    var rawValue: String { get }
}

extension SchemaEntityKey {
    var _cVarArgEncoding: [Int] {
        self.rawValue._cVarArgEncoding
    }
}

extension Schema {
    enum Media: String, SchemaEntityKey {
        static let _entityName = "Media"
        
        // MARK: Attributes
        case id
        case type
        case personalRating
        case watchAgain
        case notes
        case tmdbID
        case title
        case originalTitle
        case imagePath
        case overview
        case tagline
        case status
        case originalLanguage
        case homepageURL
        case productionCountries
        case popularity
        case voteAverage
        case voteCount
        case keywords
        case translations
        case creationDate
        case modificationDate
        case releaseDateOrFirstAired
        case isFavorite
        case isOnWatchlist
        
        // MARK: Relationships
        case genres
        case tags
        case userLists
        case productionCompanies
        case videos
        case watchProviders
        case parentalRating
    }
}
