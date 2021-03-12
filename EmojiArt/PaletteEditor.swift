//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Rebecca Nybo on 10/29/20.
//

import SwiftUI

struct PaletteEditor: View {

    @EnvironmentObject var document: EmojiArtDocument

    @Binding var chosenPalette: String
    @Binding var isShowing: Bool

    @State private var emojisToAdd = ""
    @State private var paletteName = ""

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                Form {
                    Section {
                        TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                            if !began {
                                document.rename(palette: chosenPalette, to: paletteName)
                                chosenPalette = paletteName
                            }
                        })
                        TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                            document.add(emoji: emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        })
                    }
                    Section(header: Text("Remove Emoji")) {
                        LazyVGrid(columns: emojiColumns(in: geometry.size)) {
                            ForEach((document.palettes[chosenPalette] ?? "").map { String($0) }, id: \.self) { emoji in
                                Text(emoji)
                                    .font(Font.system(size: fontSize))
                                    .onTapGesture {
                                        document.remove(emojis: emoji, fromPalette: chosenPalette)
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .navigationBarTitle("Palette Editor", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: { isShowing = false }, label: {Text("Done") }))
            }
        }
        .onAppear {
            paletteName = chosenPalette
        }
    }

    // MARK: - Drawing constants

    private func emojiColumns(in size: CGSize) -> [GridItem] {
        Array(repeating: .init(.flexible()), count: Int(size.width / 80.0))
    }

    private let emojiColumnCount = 5
    private let emojiPadding: CGFloat = 10
    private let fontSize: CGFloat = 40
}
