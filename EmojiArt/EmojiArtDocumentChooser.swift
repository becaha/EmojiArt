//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Rebecca Nybo on 10/29/20.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    
    @EnvironmentObject var store: EmojiArtDocumentStore
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavLink(document, editMode: editMode)
                }
                .onDelete { indexSet in
                    indexSet.map{ store.documents[$0] }.forEach { document in
                        store.removeDocument(document)
                    }
                }
            }
            .listStyle(InsetListStyle())
            .navigationBarTitle(store.name)
            .navigationBarItems(
                leading: Button(action: {
                    store.addDocument()
                }) {
                    Image(systemName: "plus").imageScale(.large)
                },
                trailing: EditButton()
            )
            .environment(\.editMode, $editMode)
        }
    }
}

@ViewBuilder
func NavLink(_ document: EmojiArtDocument, editMode: EditMode) -> some View {
    NavigationLink(
        destination:
            EmojiArtDocumentView()
                .environmentObject(document)
                .navigationBarTitle(store.name(for: document))
    ) {
        EditableText(store.name(for: document),
                     isEditing: editMode.isEditing) { name in
            store.setName(name, for: document)
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser()
    }
}
