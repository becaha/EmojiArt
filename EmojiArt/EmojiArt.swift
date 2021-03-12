//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Steve Liddle on 10/13/20.
//

import Foundation

struct EmojiArt: Codable {
    var backgroundUrl: URL?
    var emojis = [Emoji]()

    init() { }

    init?(json: Data?) {
        if let jsonData = json,
           let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: jsonData) {
            self = newEmojiArt
        } else {
            return nil
        }
    }

    struct Emoji: Identifiable, Codable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id: Int

        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }

    var json: Data? {
        try? JSONEncoder().encode(self)
    }

    private var uniqueEmojiId = 0

    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: x, y: y, size: size, id: uniqueEmojiId))
    }

    mutating func delete(matching emoji: Emoji) {
        if let index = emojis.firstIndex(matching: emoji) {
            emojis.remove(at: index)
        }
    }
}
