//
//  MediaDetail.swift
//  Movie DB
//
//  Created by Jonas Frey on 06.07.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI

struct MediaDetail : View {
    
    @EnvironmentObject private var mediaObject: Media
    @Environment(\.editMode) private var editMode
    
    /*
     TODO:
     - TMDB Keywords in library suche einbinden
     - Library Suche programmieren
     - ausgewählte Translations anzeigen (in en, de verfügbar?)
     - trailer link + in-app browser
     - Icons bei den Section Headers (Personen-Icon bei User Data, ...)
     - Make Tags fancy in TagListView
     - keywords, cast, translations, videos have to be filled separately by API calls!!!
     - ensure loadThumbnail() does not get called when loading from file
     - Settings
     - Filter UI
     - Base URL in JFLiterals definieren
     */
    
    private var showData: TMDBShowData? {
        mediaObject.tmdbData as? TMDBShowData
    }
    
    var body: some View {
        // Group is needed so swift can infer the return type
        Group {
            List {
                TitleView(title: mediaObject.tmdbData?.title ?? "<ERROR>", year: mediaObject.year, thumbnail: mediaObject.thumbnail)
                UserData()
                BasicInfo()
                ExtendedInfo()
            }
            .listStyle(GroupedListStyle())
        }
        .navigationBarTitle(Text(mediaObject.tmdbData?.title ?? "Loading error!"), displayMode: .inline)
        .navigationBarItems(trailing: EditButton())
    }
}

#if DEBUG
struct MediaDetail_Previews : PreviewProvider {
    static var previews: some View {
        MediaDetail()
            .environmentObject(PlaceholderData.movie as Media)
    }
}
#endif
