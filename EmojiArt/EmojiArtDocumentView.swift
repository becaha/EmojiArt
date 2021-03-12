//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Steve Liddle on 10/8/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {

    // MARK: - Properties

    @EnvironmentObject var document: EmojiArtDocument

    @State private var chosenPalette: String = ""
    @State private var confirmBackgroundPaste = false
    @State private var explainBackgroundPaste = false
    @State private var selectedEmojis = Set<EmojiArt.Emoji>()
    @State private var showPaletteEditor = false

    private var isLoading: Bool {
        document.backgroundUrl != nil && document.backgroundImage == nil
    }

    // MARK: - Drag selection

    @GestureState private var gestureSelectionOffset: CGSize = .zero

    private var selectionOffset: CGSize {
        gestureSelectionOffset * zoomScale
    }

    private var selectionDragGesture: some Gesture {
        DragGesture()
            .updating($gestureSelectionOffset) { latestDragGestureValue, gestureSelectionOffset, transaction in
                gestureSelectionOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                selectedEmojis.forEach { emoji in
                    document.move(emoji: emoji, by: finalDragGestureValue.translation / zoomScale)
                }
            }
    }

    // MARK: - Pan document

    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                document.steadyStatePanOffset = document.steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }

    // MARK: - Zoom document
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0

    private var selectionZoomScale: CGFloat {
        selectedEmojis.count > 0
            ? gestureZoomScale
            : 1.0
    }

    private var zoomScale: CGFloat {
        selectedEmojis.count > 0
            ? document.steadyStateZoomScale
            : document.steadyStateZoomScale * gestureZoomScale
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                if selectedEmojis.count > 0 {
                    selectedEmojis.forEach { emoji in
                        document.scale(emoji: emoji, by: finalGestureScale)
                    }
                } else {
                    document.steadyStateZoomScale *= finalGestureScale
                }
            }
    }

    // MARK: - View body

    var body: some View {
        VStack {
            HStack {
                PaletteChooser(chosenPalette: $chosenPalette)

                Button(action: {
                    showPaletteEditor = true
                }) {
                    Image(systemName: "pencil").imageScale(.large)
                }
                .popover(isPresented: $showPaletteEditor) {
                    PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                        .frame(minWidth: 300, minHeight: 500)
                }
                .environmentObject(document)

                ScrollView(.horizontal) {
                    HStack {
                        ForEach((document.palettes[chosenPalette] ?? "").map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag {
                                    NSItemProvider(object: emoji as NSString)
                                }
                        }
                    }
                }

                Spacer()

                Button(action: {
                    deleteSelectedEmojis()
                }) {
                    Image(systemName: "trash").imageScale(.large)
                }
            }
            .padding(.trailing)

            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )

                    if isLoading {
                        ProgressView()
                    } else {
                        ForEach(document.emojis) { emoji in
                            ZStack {
                                Rectangle()
                                    .stroke(selectedEmojis.contains(matching: emoji) ? Color.blue : Color.clear,
                                            lineWidth: 3)
                                    .frame(width: selectionBoxSize(for: emoji), height: selectionBoxSize(for: emoji))
                                Text(emoji.text)
                            }
                            .font(animatableWithSize: fontSize(for: emoji))
                            .position(position(for: emoji, in: geometry.size))
                            .gesture(selectedEmojis.contains(matching: emoji) ? selectionDragGesture : nil)
                            .gesture(singleTapToSelect(emoji))
                        }
                    }
                }
                .clipped()
                .gesture(
                    doubleTapToZoom(in: geometry.size)
                        .simultaneously(with: singleTapToDeselect())
                        .exclusively(before: panGesture)
                        .exclusively(before: zoomGesture)
                )
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(document.$backgroundImage.dropFirst()) { image in
                    withAnimation {
                        zoomToFit(image, in: geometry.size)
                    }
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)

                    location = location - (geometry.size / 2)
                    location = location - panOffset
                    location = location / zoomScale

                    return drop(providers: providers, location: location)
                }
            }
            .zIndex(-1)
            .navigationBarItems(trailing: Button(action: {
                if UIPasteboard.general.url != nil {
                    confirmBackgroundPaste = true
                } else {
                    explainBackgroundPaste = true
                }
            }) {
                Image(systemName: "doc.on.clipboard").imageScale(.large)
                    .alert(isPresented: $explainBackgroundPaste) {
                        Alert(title: Text("Paste Background"),
                              message: Text("Copy the URL of an image to the clipboard and tap this button to make it the background of your document"),
                              dismissButton: .default(Text("Ok")))
                    }
            })
            .alert(isPresented: $confirmBackgroundPaste) {
                Alert(title: Text("Paste Background"),
                      message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                      primaryButton: .default(Text("Ok")) {
                        document.setBackground(url: UIPasteboard.general.url)
                      },
                      secondaryButton: .cancel())
            }
            .onAppear {
                chosenPalette = document.defaultPaletteName
            }
        }
    }

    // MARK: - Private helpers

    private func clearSelection() {
        selectedEmojis.removeAll()
    }

    private func deleteSelectedEmojis() {
        selectedEmojis.forEach { emoji in
            document.delete(matching: emoji)
        }

        clearSelection()
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    private func drop(providers: [NSItemProvider], location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            document.setBackground(url: url)
        }

        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                document.add(emoji: string, at: location, size: defaultEmojiSize)
            }
        }

        return found
    }

    private func fontSize(for emoji: EmojiArt.Emoji) -> CGFloat {
        if selectedEmojis.contains(matching: emoji) {
            return emoji.fontSize * zoomScale * selectionZoomScale
        } else {
            return emoji.fontSize * zoomScale
        }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location

        location = location * zoomScale
        location = location + (size / 2)
        location = location + panOffset

        if selectedEmojis.contains(matching: emoji) {
            location = location + selectionOffset
        }

        return location
    }

    private func selectionBoxSize(for emoji: EmojiArt.Emoji) -> CGFloat {
        emoji.fontSize * selectionBoxSizeFactor * zoomScale * selectionZoomScale
    }

    private func singleTapToDeselect() -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation {
                    clearSelection()
                }
            }
    }

    private func singleTapToSelect(_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture()
            .onEnded {
                withAnimation {
                    selectedEmojis.toggle(matching: emoji)
                }
            }
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let horizontalZoom = size.width / image.size.width
            let verticalZoom = size.height / image.size.height

            document.steadyStateZoomScale = min(horizontalZoom, verticalZoom)
            document.steadyStatePanOffset = .zero
        }
    }

    // MARK: - Drawing constants

    private let defaultEmojiSize: CGFloat = 40
    private let selectionBoxSizeFactor: CGFloat = 1.2
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView().environmentObject(EmojiArtDocument())
    }
}
