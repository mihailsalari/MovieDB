//
//  Utils.swift
//  Movie DB
//
//  Created by Jonas Frey on 24.06.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CoreData
import StoreKit
import JFUtils

/// Throws a fatal error when called. Used for setting undefined values temporarily to make the code compile
///
/// Example:
///
///     let value: String = undefined() // Will compile as a String
///     print(value.components(separatedBy: " ") // Will not throw any compiler errors
// swiftlint:disable:next unavailable_function
func undefined<T>(_ message: String = "") -> T {
    fatalError(message)
}

struct Utils {
    static var posterDenyList = UserDefaults.standard.array(forKey: JFLiterals.Keys.posterDenyList) as? [String] ?? []
    
    /// The URL describing the documents directory of the app
    static var documentsPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Returns a date formatter to display `Date` values.
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = .utc
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
    
    /// Returns a number formatter to display money values
    static var moneyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    private init() {}
    
    /// Convenience function to execute a HTTP GET request.
    /// Ignores errors and just passes nil to the completion handler, if the request failed.
    /// - Parameters:
    ///   - urlString: The URL string of the request
    ///   - parameters: The parameters for the request
    ///   - completion: The closure to execute on completion of the request
    static func getRequest(_ urlString: String, parameters: [String: Any?], completion: @escaping (Data?) -> Void) {
        getRequest(urlString, parameters: parameters) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                print("error", error ?? "Unknown error")
                completion(nil)
                return
            }
            
            // Check for http errors
            guard (200 ... 299) ~= response.statusCode else {
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                print("headerFields = \(String(describing: response.allHeaderFields))")
                print("data = \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(nil)
                return
            }
            
            completion(data)
        }
    }
    
    // TODO: Remove
    /// Executes a HTTP GET request
    /// - Parameters:
    ///   - urlString: The URL string of the request
    ///   - parameters: The parameters for the request
    ///   - completion: The closure to execute on completion of the request
    static func getRequest(
        _ urlString: String,
        parameters: [String: Any?],
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var urlStringWithParameters = "\(urlString)"
        // We should only append the '?', if we really have parameters
        if !parameters.isEmpty {
            urlStringWithParameters += "?\(parameters.percentEscaped())"
        }
        var request = URLRequest(url: URL(string: urlStringWithParameters)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Making GET Request to \(urlStringWithParameters)")
        #if DEBUG
        // In Debug mode, always load the URL, never use the cache
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        #endif
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
    
    /// Returns an URL describing the directory with the given name in the documents directory and creates it, if neccessary
    /// - Parameter directory: The name of the folder in the documents directory
    static func url(for directory: String) -> URL {
        let url = documentsPath.appendingPathComponent(directory)
        // Create the directory, if it not already exists
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print("Error creating folder in documents directory: \(error)")
        }
        return url
    }
    
    /// Returns either black or white, depending on the color scheme
    /// - Parameter colorScheme: The current color scheme environment variable
    static func primaryUIColor(_ colorScheme: ColorScheme) -> UIColor {
        colorScheme == .light ? .black : .white
    }
    
    static func loadImage(urlString: String, completion: @escaping (UIImage?) -> Void) {
        print("Loading image from \(urlString)")
        Self.getRequest(urlString, parameters: [:]) { data in
            guard let data = data else {
                print("Unable to get image")
                completion(nil)
                return
            }
            completion(UIImage(data: data))
        }
    }
    
    /// Returns a closed range containing the years of all media objects in the library
    static func yearBounds(context: NSManagedObjectContext) -> ClosedRange<Int> {
        let minShow = fetchMinMaxShow(key: "firstAirDate", ascending: true, context: context)
        let minMovie = fetchMinMaxMovie(key: "releaseDate", ascending: true, context: context)
        let maxShow = fetchMinMaxShow(key: "firstAirDate", ascending: false, context: context)
        let maxMovie = fetchMinMaxMovie(key: "releaseDate", ascending: false, context: context)
        
        let currentYear = Calendar.current.dateComponents([.year], from: Date()).year!
        let lowerBound: Int = min(minShow?.year, minMovie?.year) ?? currentYear
        let upperBound: Int = max(maxShow?.year, maxMovie?.year) ?? currentYear
        
        assert(lowerBound <= upperBound, "The fetch request returned wrong results. " +
               "Try inverting the ascending/descending order of the fetch requests")
        
        return lowerBound ... upperBound
    }
    
    /// Returns a closed range containing the season counts from all media objects in the library
    static func numberOfSeasonsBounds(context: NSManagedObjectContext) -> ClosedRange<Int> {
        let min = fetchMinMaxShow(key: "numberOfSeasons", ascending: true, context: context)
        let max = fetchMinMaxShow(key: "numberOfSeasons", ascending: false, context: context)
        
        if min?.numberOfSeasons == nil {
            return 0 ... (max?.numberOfSeasons ?? 0)
        }
        return min!.numberOfSeasons! ... (max?.numberOfSeasons ?? min!.numberOfSeasons!)
    }
    
    /// Returns a list of all genres existing in the viewContext, sorted by id and not including duplicates.
    static func allGenres(context: NSManagedObjectContext) -> [Genre] {
        allObjects(entityName: "Genre", context: context)
            .removingDuplicates { $0.id == $1.id && $0.name == $1.name }
            .sorted(by: \.name)
    }
    
    /// Returns a list of all media objects existing in the viewContext.
    static func allMedias(context: NSManagedObjectContext) -> [Media] {
        allObjects(entityName: "Media", context: context)
            .removingDuplicates(key: \.id)
            .sorted(by: \.id)
    }
    
    /// Returns a list of all entities with the given name in the given context.
    static func allObjects<T: NSManagedObject>(entityName: String, context: NSManagedObjectContext) -> [T] {
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
        let objects = try? context.fetch(fetchRequest)
        return objects ?? []
    }
    
    private static func fetchMinMaxMovie(key: String, ascending: Bool, context: NSManagedObjectContext) -> Movie? {
        fetchMinMax(fetchRequest: Movie.fetchRequest(), key: key, ascending: ascending, context: context)
    }
    
    private static func fetchMinMaxShow(key: String, ascending: Bool, context: NSManagedObjectContext) -> Show? {
        fetchMinMax(fetchRequest: Show.fetchRequest(), key: key, ascending: ascending, context: context)
    }
    
    private static func fetchMinMax<T>(
        fetchRequest: NSFetchRequest<T>,
        key: String,
        ascending: Bool,
        context: NSManagedObjectContext
    ) -> T? {
        let fetchRequest = fetchRequest
        fetchRequest.predicate = NSPredicate(format: "%K != nil", key)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
        fetchRequest.fetchLimit = 1
        return try? context.fetch(fetchRequest).first
    }
    
    /// An ISO8601 time string representing the current date and time. Safe to use in filenames
    /// - Parameter withTime: Whether to include the time
    /// - Returns: The date (and possibly time) string
    static func isoDateString(withTime: Bool = false) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate]
        if withTime {
            formatter.formatOptions.formUnion([.withFullTime, .withTimeZone])
        }
        return formatter.string(from: Date())
    }
    
    static func share(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        DispatchQueue.main.async {
            guard let source = UIApplication.shared.windows.last?.rootViewController else {
                return
            }
            let vc = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            vc.excludedActivityTypes = excludedActivityTypes
            vc.popoverPresentationController?.sourceView = source.view
            source.present(vc, animated: true)
        }
    }
}

// MARK: - TMDB API
extension Utils {
    /// The `DateFormatter` for translating to and from TMDB date representation
    static var tmdbDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = .utc
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    /// Builds the URL for an TMDB image
    /// - Parameters:
    ///   - path: The path of the image
    ///   - size: The size of the image
    static func getTMDBImageURL(path: String, size: Int = 500) -> URL {
        // Don't load images on the deny list (should be checked before calling this function and replace with a placeholder image)
        guard !posterDenyList.contains(path) else {
            print("Poster path \(path) is on deny list. Not fetching.")
            assertionFailure("This should have been prevented from being called for poster paths on the deny list " +
                             "in the first place.")
            // As a fallback, load the placeholder as thumbnail
            return URL(string: "https://www.jonasfrey.de/appdata/PosterPlaceholder.png")!
        }
        return URL(string: "https://image.tmdb.org/t/p/w\(size)/\(path)")!
    }
    
    /// Returns the human readable language name from the given locale string consisting of an ISO-639-1 language string and possibly an ISO-3166-1 region string
    ///
    ///     languageString("pt-BR") // Returns "Portuguese (Brazil)"
    ///     languageString("de") // Returns "German"
    static func languageString(for code: String, locale: Locale = Locale.current) -> String? {
        locale.localizedString(forIdentifier: code)
    }
    
    @discardableResult
    static func updateTMDBLanguages() async throws -> [String] {
        let codes = try await TMDBAPI.shared.getTMDBLanguageCodes()
        // Sort the codes by the actual string that will be displayed, not the code itself
        let sortedCodes = codes.sorted { code1, code2 in
            guard let displayString1 = Locale.current.localizedString(forIdentifier: code1) else {
                return false
            }
            guard let displayString2 = Locale.current.localizedString(forIdentifier: code2) else {
                return true
            }
            
            return displayString1.lexicographicallyPrecedes(displayString2)
        }
        // TODO: Executed on correct thread?
        // TODO: Make JFConfig an actor
        JFConfig.shared.availableLanguages = sortedCodes
        return sortedCodes
    }
    
    static func purchasedPro() -> Bool {
        return true // swiftlint:disable:this implicit_return
        UserDefaults.standard.bool(forKey: JFLiterals.inAppPurchaseIDPro)
    }
}

// MARK: - FSK Rating
extension Utils {
    static func fskColor(_ rating: FSKRating) -> Color {
        switch rating {
        case .noRestriction:
            return Color("NoRestriction")
        case .ageSix:
            return Color("AgeSix")
        case .ageTwelve:
            return Color("AgeTwelve")
        case .ageSixteen:
            return Color("AgeSixteen")
        case .ageEighteen:
            return Color("AgeEighteen")
        }
    }
    
    static func fskLabel(_ rating: FSKRating) -> some View {
        Image(systemName: "\(rating.rawValue).square")
            .foregroundColor(fskColor(rating))
    }
    
    enum FSKRating: String, CaseIterable {
        case noRestriction = "0"
        case ageSix = "6"
        case ageTwelve = "12"
        case ageSixteen = "16"
        case ageEighteen = "18"
    }
}

/// Returns the smaller non-nil object of the given two objects
/// - Parameters:
///   - x: The first object to compare
///   - y: The second object to compare
/// - Returns: The smaller non-nil object. If both objects are nil, the function returns nil.
func min<T>(_ x: T?, _ y: T?) -> T? where T: Comparable {
    if x == nil {
        return y
    }
    if y == nil {
        return x
    }
    return min(x!, y!)
}

/// Returns the bigger non-nil object of the given two objects
/// - Parameters:
///   - x: The first object to compare
///   - y: The second object to compare
/// - Returns: The bigger non-nil object. If both objects are nil, the function returns nil.
func max<T>(_ x: T?, _ y: T?) -> T? where T: Comparable {
    if x == nil {
        return y
    }
    if y == nil {
        return x
    }
    return max(x!, y!)
}

/// Array extension to make all arrays with hashable elements identifiable
extension Array: Identifiable where Element: Hashable {
    public var id: Int { self.hashValue }
}

/// Overload of the default NSLocalizedString function that uses an empty comment
public func NSLocalizedString(_ key: String, tableName: String? = nil) -> String {
    NSLocalizedString(key, tableName: tableName, comment: "")
}
