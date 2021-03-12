//
//  EmojiArtDocument+Extension.swift
//  EmojiArt
//
//  Created by Steve Liddle on 10/21/20.
//

import Foundation

extension EmojiArtDocument {

    // MARK: - Constants

    private static let palettesKey = "EmojiArtDocument.PalettesKey"

    // MARK: - Computed properties

    private(set) var palettes: [String : String] {
        get {
            UserDefaults.standard.object(forKey: EmojiArtDocument.palettesKey) as? [String:String]
                ??
                [
                    "Faces" : "😀😆😅😂🤣😇😜🤨😎🥺😢😡🥵🥶😱🤗🤔😬🤢😈🤡👽🤖🎃🙀",
                    "Food" : "🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑🥭🍍🥥🥝🍅🥨🧀🥓🥩🌭🍔🍟🍕🌮",
                    "Animals" : "🐶🦊🐼🐨🐸🐵🙈🙉🙊🐒🐥🦆🦉🐝🐛🦋🐌🐞🐢🦕🐬🐋🐊🦍🦧🐫🐎🐖🐏🦌🐓🦃🦜🦢🦨🐿",
                    "Activities" : "⚽️🏈⚾️🎾🏐🏓⛳️🥌⛷🚴‍♂‍🎳🎭"
                ]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: EmojiArtDocument.palettesKey)
            objectWillChange.send()
        }
    }

    var defaultPaletteName: String {
        sortedPaletteNames.first ?? ""
    }

    var sortedPaletteNames: [String] {
        palettes.keys.sorted { $0 < $1 }
    }

    // MARK: - Palette CRUD

    func add(palette: String, named name: String) {
        palettes[name] = palette
    }

    func add(emoji: String, toPalette paletteName: String) {
        if let palette = palettes[paletteName] {
            palettes[paletteName] = (emoji + palette).uniqued()
        }
    }

    func remove(emojis emojisToRemove: String, fromPalette paletteName: String) {
        if let palette = palettes[paletteName] {
            palettes[paletteName] = palette.filter { !emojisToRemove.contains($0) }
        }
    }

    func remove(palette name: String) {
        palettes.removeValue(forKey: name)
    }

    func rename(palette oldName: String, to newName: String) {
        if let palette = palettes[oldName] {
            palettes.removeValue(forKey: oldName)
            palettes[newName] = palette
        }
    }

    // MARK: - Accessors

    func palette(after otherPalette: String) -> String {
        palette(offsetBy: +1, from: otherPalette)
    }

    func palette(before otherPalette: String) -> String {
        palette(offsetBy: -1, from: otherPalette)
    }

    // MARK: - Private helpers

    private func palette(offsetBy offset: Int, from otherPalette: String) -> String {
        if let index = sortedPaletteNames.firstIndex(of: otherPalette) {
            var offsetIndex = (index + offset) % sortedPaletteNames.count

            if offsetIndex < 0 {
                offsetIndex += palettes.count
            }

            return sortedPaletteNames[offsetIndex]
        }

        return sortedPaletteNames.first ?? ""
    }
}
