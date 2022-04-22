//
//  MediaDetail.swift
//  Movie DB
//
//  Created by Jonas Frey on 06.07.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import SwiftUI

struct MediaDetail: View {
    @ObservedObject private var library = MediaLibrary.shared
    @EnvironmentObject private var mediaObject: Media
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        if mediaObject.isFault {
            Text("Error loading media")
                .navigationTitle("Error")
        } else {
            List {
                TitleView(title: mediaObject.title, year: mediaObject.year, thumbnail: mediaObject.thumbnail)
                UserData()
                BasicInfo()
                ExtendedInfo()
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text(mediaObject.title), displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
            .task {
                // If there is no thumbnail, try to download it again
                // If a media object really has no thumbnail (e.g., link broken), this may be a bit too much...
                if mediaObject.thumbnail == nil {
                    await mediaObject.loadThumbnail()
                }
            }
        }
    }
}

#if DEBUG
struct MediaDetail_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetail()
            .environmentObject(PlaceholderData.movie as Media)
    }
}
#endif
