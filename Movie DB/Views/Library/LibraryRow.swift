//
//  LibraryRow.swift
//  Movie DB
//
//  Created by Jonas Frey on 01.07.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI

// TODO: Rework navigation with NavigationLinks
// TODO: NavigationLink not necessary anymore? List handles selection on its own

/// Represents the label of a list displaying media objects.
/// Presents various data about the media object, e.g. the thumbnail image, title and year
/// Requires the displayed media object as an `EnvironmentObject`.
struct LibraryRow: View {
    @EnvironmentObject var mediaObject: Media
    
    let movieSymbol = Strings.Library.movieSymbolName
    let seriesSymbol = Strings.Library.showSymbolName
    
    var body: some View {
        if mediaObject.isFault {
            // This will be displayed while the object is being deleted
            EmptyView()
        } else {
            HStack {
                Image(uiImage: mediaObject.thumbnail, defaultImage: JFLiterals.posterPlaceholderName)
                    .thumbnail()
                VStack(alignment: .leading, spacing: 4) {
                    Text(mediaObject.title)
                        .lineLimit(2)
                        .font(.headline)
                    // Under the title
                    HStack {
                        // MARK: Type
                        if mediaObject.type == .movie {
                            Image(systemName: movieSymbol)
                        } else {
                            Image(systemName: seriesSymbol)
                        }
                        // MARK: FSK Rating
                        if let rating = mediaObject.parentalRating {
                            rating.symbol
                                .font(.caption2)
                        }
                        // MARK: Year
                        if mediaObject.year != nil {
                            Text(mediaObject.year!.description)
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

struct LibraryRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                ForEach(ParentalRating.fskRatings, id: \.label) { rating in
                    let movie: Media = {
                        // swiftlint:disable:next force_cast
                        let movie = PlaceholderData.movie.copy() as! Movie
                        movie.parentalRating = rating
                        return movie
                    }()
                    // TODO: Rework navigation
                    NavigationLink(value: movie as Media) {
                        LibraryRow()
                            .environmentObject(movie)
                    }
                }
            }
            .navigationTitle(Text(verbatim: "Library"))
        }
    }
}
