//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Steve Liddle on 10/8/20.
//

import SwiftUI

let store = EmojiArtDocumentStore()

@main
struct EmojiArtApp: App {
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
//            EmojiArtDocumentView().environmentObject(EmojiArtDocument())
        }
    }
}
