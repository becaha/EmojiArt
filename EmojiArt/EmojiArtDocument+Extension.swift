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
                    "Faces" : "๐๐๐๐๐คฃ๐๐๐คจ๐๐ฅบ๐ข๐ก๐ฅต๐ฅถ๐ฑ๐ค๐ค๐ฌ๐คข๐๐คก๐ฝ๐ค๐๐",
                    "Food" : "๐๐๐๐๐๐๐๐๐๐๐๐๐ฅญ๐๐ฅฅ๐ฅ๐๐ฅจ๐ง๐ฅ๐ฅฉ๐ญ๐๐๐๐ฎ",
                    "Animals" : "๐ถ๐ฆ๐ผ๐จ๐ธ๐ต๐๐๐๐๐ฅ๐ฆ๐ฆ๐๐๐ฆ๐๐๐ข๐ฆ๐ฌ๐๐๐ฆ๐ฆง๐ซ๐๐๐๐ฆ๐๐ฆ๐ฆ๐ฆข๐ฆจ๐ฟ",
                    "Activities" : "โฝ๏ธ๐โพ๏ธ๐พ๐๐โณ๏ธ๐ฅโท๐ดโโโ๐ณ๐ญ"
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
