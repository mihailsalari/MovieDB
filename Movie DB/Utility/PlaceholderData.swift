//
//  SampleData.swift
//  Movie DB
//
//  Created by Jonas Frey on 08.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation

struct PlaceholderData {
    
    // TODO: Use preview context
    
    static var rawMovieJSON: Data {
        try! Data(contentsOf: Bundle.main.url(forResource: "TMDBMovie", withExtension: "json")!)
    }
    
    static var tmdbMovieData: TMDBData {
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "TMDBMovie", withExtension: "json")!)
        return try! JSONDecoder().decode(TMDBData.self, from: data)
    }
    
    static var tmdbShowData: TMDBData {
        let data = try! Data(contentsOf: Bundle.main.url(forResource: "TMDBShow", withExtension: "json")!)
        return try! JSONDecoder().decode(TMDBData.self, from: data)
    }
    
    static let movie: Movie = {
        let m = Movie(context: CoreDataStack.viewContext, tmdbData: tmdbMovieData)
        m.personalRating = .twoAndAHalfStars
        //m.tags = [Tag(id: <#T##Int#>, name: <#T##String#>, context: <#T##NSManagedObjectContext#>)]
        return m
    }()
    
    static let show: Show = {
        let s = Show(context: CoreDataStack.viewContext, tmdbData: tmdbShowData)
        s.personalRating = .fourStars
        //s.tags = [2, 3]
        return s
    }()
    
    static var mediaLibrary: MediaLibrary {
        let library = MediaLibrary.shared
        try! library.append(movie)
        try! library.append(show)
        return library
    }
    
    static func populateSampleTags() {
//        lib.create(name: "Happy Ending")
//        lib.create(name: "Trashy")
//        lib.create(name: "Time Travel")
//        lib.create(name: "Immortality")
    }
}
