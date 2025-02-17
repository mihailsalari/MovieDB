//
//  ResolveProblemsView.swift
//  Movie DB
//
//  Created by Jonas Frey on 26.04.22.
//  Copyright © 2022 Jonas Frey. All rights reserved.
//

import SwiftUI

struct ResolveProblemsView: View {
    @Binding var problems: [Problem]
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    @State private var selectedMedia: Media?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMedia) {
                ForEach(problems) { problem in
                    Section(problem.type.localized) {
                        Text(problem.type.recovery)
                        ForEach(problem.associatedMedias) { media in
                            NavigationLink(value: media) {
                                LibraryRow()
                                    .environmentObject(media)
                            }
                        }
                        .onDelete { indexSet in
                            for offset in indexSet {
                                let media = problem.associatedMedias[offset]
                                problems.removeAll(where: { $0.id == problem.id })
                                self.managedObjectContext.delete(media)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.ResolveProblems.navBarTitle)
        } detail: {
            if let selectedMedia {
                MediaDetail()
                    .environmentObject(selectedMedia)
            } else {
                Text(Strings.ResolveProblems.detailPlaceholder)
            }
        }
    }
}

struct ResolveProblemsView_Previews: PreviewProvider {
    static var previews: some View {
        ResolveProblemsView(problems: .constant([]))
    }
}
