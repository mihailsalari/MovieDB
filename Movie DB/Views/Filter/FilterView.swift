//
//  FilterView.swift
//  Movie DB
//
//  Created by Jonas Frey on 30.11.19.
//  Copyright © 2019 Jonas Frey. All rights reserved.
//

import CoreData
import SwiftUI

struct FilterView: View {
    static let nilString = "any"
    
    @EnvironmentObject var filterSetting: FilterSetting
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var managedObjectContext
        
    var body: some View {
        NavigationStack {
            Form {
                FilterUserDataSection()
                FilterInformationSection()
                FilterShowSpecificSection()
            }
            .environmentObject(filterSetting)
            .navigationTitle(Strings.Library.Filter.navBarTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.filterSetting.reset()
                        self.dismiss()
                    } label: {
                        Text(Strings.Library.Filter.navBarButtonReset)
                    }
                }
                ToolbarItem(placement: ToolbarItemPlacement.confirmationAction) {
                    Button {
                        self.dismiss()
                    } label: {
                        Text(Strings.Library.Filter.navBarButtonApply)
                    }
                }
            }
        }
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView()
            .environmentObject(FilterSetting(context: PersistenceController.createDisposableContext()))
    }
}
