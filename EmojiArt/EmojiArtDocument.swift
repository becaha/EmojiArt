//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Steve Liddle on 10/8/20.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Equatable, Identifiable {
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Properties

    @Published private var emojiArt = EmojiArt()
    @Published private(set) var backgroundImage: UIImage?
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published var steadyStateZoomScale: CGFloat = 1.0

    private var autosaveCancellable: AnyCancellable?

    private var fetchImageCancellable: AnyCancellable?

    // MARK: - Initialization

    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        
//        let defaultKey = "EmojiArtDocument.\(self.id.uuidString)"
        
//        let jsonData = UserDefaults.standard.data(forKey: defaultKey)

//        emojiArt = EmojiArt(json: jsonData) ?? EmojiArt()
//        autosaveCancellable = $emojiArt.sink { emojiArt in
//            UserDefaults.standard.set(emojiArt.json, forKey: defaultKey)
//        }
        // get json document data
        let jsonData = readFileContents(withName: self.id.uuidString)
        
        // get emoji art from json document data
        emojiArt = EmojiArt(json: jsonData) ?? EmojiArt()
        // save emoji art json
        autosaveCancellable = $emojiArt.sink { emojiArt in
            self.writeDocument(emojiArt, withName: self.id.uuidString)
        }
        fetchBackgroundImageData()
    }
    
    // MARK: - Document file system storage
    
    private func readFileContents(withName fileName: String) -> Data? {
        if let url = urlForFile(name: fileName) {
            if let jsonData = try? Data(contentsOf: url) {
                return jsonData
            }
        }
        return nil
    }
    
    private func urlForFile(name: String) -> URL? {
        return try? FileManager.default.url(
            for: FileManager.SearchPathDirectory.documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent(name)
        .appendingPathExtension("txt")
    }
    
    private func writeHomeDirectoryFile(withContents contents: Data, withName fileName: String) {
        do {
            if let url = urlForFile(name: fileName) {
                // atomic = write it all or nothing
                try contents.write(to: url, options: .atomic)
                
                print("Success" + url.absoluteString)
            }
        }
        catch {
            print("Error")
        }
    }
    
    func writeDocument(_ emojiArt: EmojiArt, withName documentName: String) {
        if let contents = emojiArt.json {
            writeHomeDirectoryFile(withContents: contents, withName: documentName)
        }
    }

    // MARK: - Model access

    var backgroundUrl: URL? {
        emojiArt.backgroundUrl
    }

    var emojis: [EmojiArt.Emoji] {
        emojiArt.emojis
    }

    // MARK: - Intents

    func add(emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }

    func delete(matching emoji: EmojiArt.Emoji) {
        emojiArt.delete(matching: emoji)
    }

    func move(emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }

    func scale(emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }

    func setBackground(url: URL?) {
        emojiArt.backgroundUrl = url?.imageURL
        fetchBackgroundImageData()
    }

    // MARK: - Private helpers

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let imageUrl = emojiArt.backgroundUrl {
            fetchImageCancellable?.cancel()
            fetchImageCancellable = URLSession.shared
                .dataTaskPublisher(for: imageUrl)
                .map { data, response in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil)
                .assign(to: \EmojiArtDocument.backgroundImage, on: self)
        }
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y))}
}
