//
//  ImageCarousel.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreData

struct ImageData: Equatable {
    var id = UUID()
    var image : UIImage
    var existingItem : StoredImage? = nil
}

struct ImageCarousel: View {
    @Binding var images: [ImageData]
    var editMode: Bool = false
    var size : Size = Size.medium
    var editExistingImages : Bool = false
    /// Tap for a full-screen zoomable viewer; off where a tap should do something else, like list cards
    var allowsZoom : Bool = false

    @State private var showPhotoPicker : Bool = false
    @State private var viewerStart : PhotoViewerStart? = nil
    @State private var selectedImages = [PhotosPickerItem]()
    @State private var showCamera : Bool = false
    @State private var capturedImage : UIImage? = nil
    @State private var isLoadingPhotos : Bool = false
    @State private var showPhotoOrder : Bool = false
    @State private var page : Int? = 0
    /// The photo being held and slid to a new spot
    @State private var reorder : PhotoReorder? = nil
    @GestureState private var isReorderGestureActive = false
    @State private var carouselWidth : CGFloat = 0
    
    private struct PhotoReorder: Equatable {
        let id : UUID
        let startIndex : Int
        var translation : CGFloat = 0
        var targetIndex : Int
    }
    
    private let reorderSpacing : CGFloat = 8
    /// Turns shown with an animation but not yet drawn into the photo
    @State private var pendingTurns : [UUID: Int] = [:]
    @State private var runningTurnAnimations : [UUID: Int] = [:]
    @State private var renderingImageIDs : Set<UUID> = []
    /// Drawn while the spin was still running, waiting for it to finish
    @State private var renderedTurns : [UUID: (turns: Int, image: UIImage)] = [:]
    
    var body: some View {
        VStack {
            if images.isEmpty && editMode && isLoadingPhotos {
                loadingIndicator
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if images.isEmpty && editMode {
                Menu {
                    addPhotoOptions
                } label: {
                    Label("", systemImage : "photo.badge.plus").font(.system(size: 30)).frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Add Photos")
                
            } else {
                VStack {
                    FancyHorizontalScroll(count: images.count, size: size, position: $page, isScrollDisabled: reorder != nil) {
                        ForEach(0..<images.count, id: \.self){ imageIndex in
                            RotatablePhoto(
                                image: images[imageIndex].image,
                                turns: Double(pendingTurns[images[imageIndex].id] ?? 0),
                                isTurning: pendingTurns[images[imageIndex].id] != nil
                            )
                                .if(allowsZoom) { image in
                                    image
                                        .onTapGesture { viewerStart = PhotoViewerStart(index: imageIndex) }
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityLabel(images.count > 1 ? "Photo \(imageIndex + 1) of \(images.count)" : "Photo")
                                        .accessibilityHint("Opens the photo full screen")
                                }
                                .gesture(reorderGesture(from: imageIndex), including: editMode && images.count > 1 ? .all : .subviews)
                                .tag(imageIndex)
                                .containerRelativeFrame(.horizontal)
//                                .scaleEffect(2)
//                                .onTapGesture(count: 2) { location in
//                                    withAnimation {
//                                        scale = scale == 1 ? 2 : 1
//                                    }
//                                }
                                .overlay(
                                    editMode
                                    ? AnyView(Button(action: {
                                        // Delete action
                                        images.remove(at: imageIndex)
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .font(.title)
                                            .foregroundStyle(Color.black.opacity(0.75))
                                            .background(.white)
                                            .clipShape(Circle())
                                    }
                                        .accessibilityLabel("Remove Photo")
                                        .padding(.top, 15)
                                        .padding(.trailing, 20))
                                    : AnyView(EmptyView()),
                                    alignment: .topTrailing
                                    
                                )
                                .overlay(
                                    editMode
                                    ? AnyView(Menu {
                                        addPhotoOptions
                                    } label: {
                                        Label("", systemImage : "photo.badge.plus").font(.title2)
                                    }
                                        .accessibilityLabel("Add Photos")
                                        .padding(.bottom, 10)
                                        .padding(.trailing, 20))
                                    : AnyView(EmptyView()),
                                    alignment: .bottomTrailing
                                    
                                )
                                .overlay(alignment: .bottomLeading) {
                                    if editMode {
                                        HStack(spacing: 20) {
                                            Button {
                                                rotate(images[imageIndex])
                                            } label: {
                                                Label("", systemImage : "rotate.right").font(.title2)
                                            }
                                            .accessibilityLabel("Rotate Photo")
                                            
                                            if images.count > 1 {
                                                Button {
                                                    showPhotoOrder = true
                                                } label: {
                                                    Label("", systemImage : "arrow.left.arrow.right").font(.title2)
                                                }
                                                .accessibilityLabel("Reorder Photos")
                                            }
                                        }
                                        .padding(.bottom, 10)
                                        .padding(.leading, 20)
                                    }
                                }
                        }
                    }
                }
                .padding(0)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { carouselWidth = proxy.size.width }
                            .onChange(of: proxy.size.width) { carouselWidth = proxy.size.width }
                    }
                }
                .overlay {
                    if let reorder {
                        reorderStrip(reorder)
                            .transition(.opacity)
                    }
                }
                .overlay {
                    if isLoadingPhotos {
                        loadingIndicator
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        // Attached outside the empty-state branch, which disappears as soon as the captured photo arrives
        .fullScreenCover(isPresented: $showCamera) {
            accessCameraView(selectedImage: $capturedImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewerStart) { start in
            PhotoViewer(images: images.map(\.image), startIndex: start.index)
        }
        .sheet(isPresented: $showPhotoOrder) {
            PhotoOrderSheet(images: $images)
        }
        .sensoryFeedback(trigger: reorder?.id) { _, id in id == nil ? nil : .impact(weight: .medium) }
        .sensoryFeedback(.selection, trigger: reorder?.targetIndex)
        // A held photo can lose its touch without the gesture ending, e.g. to a system alert
        .onChange(of: isReorderGestureActive) {
            if !isReorderGestureActive {
                finishReorder()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImages, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedImages) {
            if editMode && !selectedImages.isEmpty {
                let items = selectedImages
                isLoadingPhotos = true
                selectedImages = []
                
                Task { @MainActor in
                    let loaded = await loadImages(from: items)
                    
                    if !editExistingImages {
                        images.removeAll()
                    }
                    images.append(contentsOf: loaded.map { ImageData(image: $0) })
                    isLoadingPhotos = false
                }
            }
        }
        .onChange(of: capturedImage) {
            if editMode, let capturedImage {
                let photo = capturedImage
                self.capturedImage = nil
                
                Task { @MainActor in
                    let scaled = await Task.detached(priority: .userInitiated) {
                        photo.scaledDown(toMaxPixelSize: StoredImage.displayMaxPixelSize)
                    }.value
                    
                    if !editExistingImages {
                        images.removeAll()
                    }
                    
                    images.append(ImageData(image: scaled))
                }
            }
        }
        .if(size == Size.extraSmall && UIDevice.current.userInterfaceIdiom == .pad) { view in
            view.frame(width: 200)
        }
        .if(size == Size.extraSmall && UIDevice.current.userInterfaceIdiom != .pad) { view in
            view.frame(width: 100)
        }
        .if(size == Size.small && UIDevice.current.userInterfaceIdiom == .pad) { view in
            view.frame(width: 300)
        }
    }
    
    /// Spins the photo right away while a turned copy is drawn, then swaps the copy in once the spin settles
    private func rotate(_ item: ImageData) {
        let id = item.id
        runningTurnAnimations[id, default: 0] += 1
        
        withAnimation(.smooth(duration: 0.35)) {
            pendingTurns[id, default: 0] += 1
        } completion: {
            runningTurnAnimations[id, default: 1] -= 1
            applyRenderedTurns(for: id)
        }
        
        renderPendingTurns(for: id)
    }
    
    private func renderPendingTurns(for id: UUID) {
        guard !renderingImageIDs.contains(id), let turns = pendingTurns[id] else { return }
        
        guard let item = images.first(where: { $0.id == id }) else {
            pendingTurns[id] = nil
            return
        }
        
        renderingImageIDs.insert(id)
        
        // The form shows a smaller copy of saved photos, so rotate the full-size original instead
        let source = turns.isMultiple(of: 4) ? item.image : item.existingItem?.image.flatMap(UIImage.init(data:)) ?? item.image
        
        Task { @MainActor in
            let rotated = await Task.detached(priority: .userInitiated) { source.rotatedClockwise(quarterTurns: turns) }.value
            renderingImageIDs.remove(id)
            renderedTurns[id] = (turns, rotated)
            applyRenderedTurns(for: id)
        }
    }
    
    private func applyRenderedTurns(for id: UUID) {
        // Swapping mid-spin would cut the animation short
        guard runningTurnAnimations[id, default: 0] == 0, let rendered = renderedTurns[id] else { return }
        renderedTurns[id] = nil
        
        guard let index = images.firstIndex(where: { $0.id == id }) else {
            pendingTurns[id] = nil
            return
        }
        
        // Looks identical, so it mustn't animate. Same ID so the form doesn't treat it as a newly added photo;
        // no existing item so it's saved fresh, unless it went all the way around
        withoutAnimation {
            if !rendered.turns.isMultiple(of: 4) {
                images[index] = ImageData(id: id, image: rendered.image)
            }
            let remaining = (pendingTurns[id] ?? rendered.turns) - rendered.turns
            pendingTurns[id] = remaining == 0 ? nil : remaining
        }
        
        // More taps came in while this copy was drawn
        renderPendingTurns(for: id)
    }
    
    /// Hold a photo, then slide it left or right among thumbnails of the rest
    private func reorderGesture(from index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($isReorderGestureActive) { value, isActive, _ in
                if case .second(true, _) = value {
                    isActive = true
                }
            }
            .onChanged { value in
                guard case .second(true, let drag) = value, images.indices.contains(index) else { return }
                
                if reorder == nil {
                    hideKeyboard()
                    withAnimation(.snappy) {
                        reorder = PhotoReorder(id: images[index].id, startIndex: index, targetIndex: index)
                    }
                }
                
                guard var current = reorder else { return }
                let slot = thumbnailSide(for: carouselWidth) + reorderSpacing
                current.translation = drag?.translation.width ?? 0
                current.targetIndex = min(max(current.startIndex + Int((current.translation / max(slot, 1)).rounded()), 0), images.count - 1)
                
                if current != reorder {
                    reorder = current
                }
            }
            .onEnded { _ in
                finishReorder()
            }
    }
    
    private func finishReorder() {
        guard let current = reorder else { return }
        
        // Moved without animation so the carousel underneath is already showing it in its new place
        if current.targetIndex != current.startIndex, let from = images.firstIndex(where: { $0.id == current.id }) {
            withoutAnimation {
                images.move(fromOffsets: IndexSet(integer: from), toOffset: current.targetIndex > from ? current.targetIndex + 1 : current.targetIndex)
                page = current.targetIndex
            }
        }
        
        withAnimation(.snappy) {
            reorder = nil
        }
    }
    
    /// Photo IDs in the order they'd be in if the held photo were let go now
    private func previewOrder(for reorder: PhotoReorder) -> [UUID] {
        var order = images.map(\.id).filter { $0 != reorder.id }
        order.insert(reorder.id, at: min(reorder.targetIndex, order.count))
        return order
    }
    
    private func thumbnailSide(for width: CGFloat) -> CGFloat {
        let count = CGFloat(max(images.count, 1))
        return max(min(84, (width - 40 - reorderSpacing * (count - 1)) / count), 1)
    }
    
    /// Covers the carousel while a photo is held; the touch stays with the photo underneath, so this ignores touches
    private func reorderStrip(_ reorder: PhotoReorder) -> some View {
        GeometryReader { proxy in
            let side = thumbnailSide(for: proxy.size.width)
            let slot = side + reorderSpacing
            let firstCenter = (proxy.size.width - (CGFloat(images.count) * slot - reorderSpacing)) / 2 + side / 2
            let translation = min(
                max(reorder.translation, -CGFloat(reorder.startIndex) * slot - slot / 2),
                CGFloat(images.count - 1 - reorder.startIndex) * slot + slot / 2
            )
            
            let order = previewOrder(for: reorder)
            
            ZStack {
                Text("Slide to move")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2 - side / 2 - 28)
                
                ForEach(images, id: \.id) { item in
                    let isHeld = item.id == reorder.id
                    let slotIndex = isHeld ? reorder.startIndex : order.firstIndex(of: item.id) ?? 0
                    
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaleEffect(isHeld ? 1.15 : 1)
                        .shadow(color: .black.opacity(isHeld ? 0.3 : 0), radius: 8, y: 4)
                        .zIndex(isHeld ? 1 : 0)
                        .position(x: firstCenter + CGFloat(slotIndex) * slot + (isHeld ? translation : 0), y: proxy.size.height / 2)
                        .animation(isHeld ? nil : .snappy, value: slotIndex)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.vertical, 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private func withoutAnimation(_ changes: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, changes)
    }
    
    @ViewBuilder
    private var addPhotoOptions: some View {
        Button {
            showCamera = true
        } label: {
            Label("Take Photo", systemImage : "camera")
        }
        
        Button {
            showPhotoPicker = true
        } label: {
            Label("Choose Photos", systemImage : "photo.on.rectangle")
        }
    }
    
    private var loadingIndicator: some View {
        ProgressView(selectedImages.count > 1 ? "Loading Photos..." : "Loading Photo...")
    }
    
    /// Loads in parallel but keeps the order the photos were picked in; downsamples so the form stays responsive
    private func loadImages(from items: [PhotosPickerItem]) async -> [UIImage] {
        let maxPixelSize = StoredImage.displayMaxPixelSize
        
        return await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    guard let data = try? await item.loadTransferable(type: Data.self) else { return (index, nil) }
                    // Decode straight to a form-sized bitmap instead of a full-resolution photo
                    let image = UIImage.downsampled(from: data, maxPixelSize: maxPixelSize)
                        ?? UIImage(data: data)?.scaledDown(toMaxPixelSize: maxPixelSize)
                    return (index, image)
                }
            }
            
            var results = [UIImage?](repeating: nil, count: items.count)
            for await (index, image) in group {
                results[index] = image
            }
            return results.compactMap { $0 }
        }
    }
}

/// Turns a photo within its frame. The form snaps row heights rather than animating them, and only re-measures
/// when the photos change, so until the turned photo is swapped in the frame holds the taller of the two shapes
/// with the photo pinned to its top; then the frame and row settle together and only empty space below goes away.
private struct RotatablePhoto: View, Animatable {
    let image : UIImage
    /// Fractional mid-turn
    var turns : Double
    var isTurning : Bool
    
    var animatableData: Double {
        get { turns }
        set { turns = newValue }
    }
    
    var body: some View {
        let aspectRatio = image.size.width / max(image.size.height, 1)
        
        // Height per point of width the photo takes up, moving from its shape at one quarter turn to the next
        let fromTurn = turns.rounded(.down)
        let progress = turns - fromTurn
        let fromHeight = heightPerWidth(turns: Int(fromTurn), aspectRatio: aspectRatio)
        let toHeight = heightPerWidth(turns: Int(fromTurn) + 1, aspectRatio: aspectRatio)
        let photoHeight = fromHeight + (toHeight - fromHeight) * progress
        
        let frameHeight = isTurning
            ? max(aspectRatio, 1 / aspectRatio)
            : heightPerWidth(turns: Int(turns.rounded()), aspectRatio: aspectRatio)
        
        Color.clear
            .aspectRatio(1 / frameHeight, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = photoHeight * width
                    
                    // Largest photo whose turned outline fits the space it's moving into
                    let angle = turns * .pi / 2
                    let cosine = abs(cos(angle)), sine = abs(sin(angle))
                    let scale = min(
                        width / (aspectRatio * cosine + sine),
                        height / (aspectRatio * sine + cosine)
                    )
                    
                    Image(uiImage: image)
                        .resizable()
                        // Clipped before turning so the rounded corners spin with the photo
                        .clipShape(RoundedRectangle(cornerRadius: 20.0))
                        .frame(width: aspectRatio * scale, height: scale)
                        .rotationEffect(.radians(angle))
                        .position(x: width / 2, y: height / 2)
                }
            }
    }
    
    private func heightPerWidth(turns: Int, aspectRatio: CGFloat) -> CGFloat {
        turns.isMultiple(of: 2) ? 1 / aspectRatio : aspectRatio
    }
}

/// Drag photos into a new order; the form's photos move as they're dragged, and the first one leads in lists
private struct PhotoOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var images : [ImageData]
    
    /// Full-size photos are slow to redraw at row size on every move
    @State private var thumbnails : [UUID: UIImage] = [:]
    
    private let thumbnailSide : CGFloat = 64
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Image(uiImage: thumbnails[item.id] ?? item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: thumbnailSide, height: thumbnailSide)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo \(index + 1)")
                                
                                if index == 0 {
                                    Text("Shown first")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .onMove { source, destination in
                        images.move(fromOffsets: source, toOffset: destination)
                    }
                } footer: {
                    Text("Drag photos to change their order.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Photo Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            let pixelSide = thumbnailSide * 3
            var prepared : [UUID: UIImage] = [:]
            
            for item in images where thumbnails[item.id] == nil {
                let size = item.image.size
                let scale = pixelSide / max(min(size.width, size.height), 1)
                guard scale < 1 else { continue }
                
                let source = item.image
                let thumbnail = await Task.detached(priority: .utility) {
                    await source.byPreparingThumbnail(
                        ofSize: CGSize(width: size.width * scale, height: size.height * scale)
                    )
                }.value
                
                if let thumbnail {
                    prepared[item.id] = thumbnail
                }
            }
            
            // byPreparingThumbnail can resume off the main actor
            await MainActor.run {
                for (id, thumbnail) in prepared {
                    thumbnails[id] = thumbnail
                }
            }
        }
    }
}

struct PhotoViewerStart: Identifiable {
    let index : Int
    var id : Int { index }
}

/// A small photo pinned over a form so it can be referenced without scrolling back up;
/// drag it to any corner, tap it to open the full-screen viewer, or slide it off the side to tuck it away
struct FloatingPhotoReference: View {
    let images : [UIImage]
    /// Hidden rather than removed so the chosen corner survives scrolling back to the photos
    var isVisible : Bool
    
    private enum Corner: CaseIterable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
        
        var isLeading : Bool { self == .topLeading || self == .bottomLeading }
        var isTop : Bool { self == .topLeading || self == .topTrailing }
    }
    
    @State private var corner : Corner = .bottomTrailing
    @State private var dragOffset : CGSize = .zero
    @State private var showViewer = false
    /// Slid off the side, leaving only a tab to pull it back out
    @State private var isTucked = false
    
    private let size = CGSize(width: 96, height: 120)
    private let margin : CGFloat = 12
    private let tabSize = CGSize(width: 28, height: 76)
    private let springAnimation = Animation.spring(duration: 0.35, bounce: 0.2)
    
    var body: some View {
        GeometryReader { proxy in
            let home = position(for: corner, in: proxy.size)
            let tuckedX = corner.isLeading ? -size.width / 2 - margin : proxy.size.width + size.width / 2 + margin
            let showsTab = isTucked && isVisible
            
            thumbnail
                .scaleEffect(isVisible ? 1 : 0.6)
                .opacity(isVisible ? 1 : 0)
                .allowsHitTesting(isVisible && !isTucked)
                .accessibilityHidden(!isVisible || isTucked)
                .animation(.snappy, value: isVisible)
                .position(x: (isTucked ? tuckedX : home.x) + dragOffset.width, y: home.y + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation }
                        .onEnded { value in
                            settle(from: home, translation: value.translation, predicted: value.predictedEndTranslation, in: proxy.size)
                        }
                )
            
            tab
                .offset(x: showsTab ? 0 : (corner.isLeading ? -tabSize.width : tabSize.width))
                .opacity(showsTab ? 1 : 0)
                .allowsHitTesting(showsTab)
                .accessibilityHidden(!showsTab)
                .position(x: corner.isLeading ? tabSize.width / 2 : proxy.size.width - tabSize.width / 2, y: home.y)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isTucked)
        .fullScreenCover(isPresented: $showViewer) {
            PhotoViewer(images: images, startIndex: 0)
        }
    }
    
    private func settle(from home: CGPoint, translation: CGSize, predicted: CGSize, in container: CGSize) {
        let center = CGPoint(x: home.x + translation.width, y: home.y + translation.height)
        let flungTo = CGPoint(x: home.x + predicted.width, y: home.y + predicted.height)
        
        // Mostly dragged off the edge, or flicked hard past it; an ordinary flick toward a corner stays put
        let edgeZone = size.width * 0.2
        let tucksLeft = center.x < edgeZone || flungTo.x < -size.width
        let tucksRight = center.x > container.width - edgeZone || flungTo.x > container.width + size.width
        
        withAnimation(springAnimation) {
            if tucksLeft || tucksRight {
                corner = flungTo.y < container.height / 2
                    ? (tucksLeft ? .topLeading : .topTrailing)
                    : (tucksLeft ? .bottomLeading : .bottomTrailing)
                isTucked = true
            } else {
                corner = nearestCorner(to: flungTo, in: container)
            }
            dragOffset = .zero
        }
    }
    
    private func untuck() {
        withAnimation(springAnimation) {
            isTucked = false
        }
    }
    
    private var tab: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.caption)
            
            Image(systemName: corner.isLeading ? "chevron.compact.right" : "chevron.compact.left")
                .font(.title3.weight(.semibold))
        }
        .foregroundStyle(Color.secondary)
        .frame(width: tabSize.width, height: tabSize.height)
        .background(
            .regularMaterial,
            in: UnevenRoundedRectangle(
                topLeadingRadius: corner.isLeading ? 0 : 12,
                bottomLeadingRadius: corner.isLeading ? 0 : 12,
                bottomTrailingRadius: corner.isLeading ? 12 : 0,
                topTrailingRadius: corner.isLeading ? 12 : 0
            )
        )
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: untuck)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    let inward = corner.isLeading ? value.translation.width : -value.translation.width
                    if inward > 20 { untuck() }
                }
        )
        .accessibilityElement()
        .accessibilityLabel(images.count > 1 ? "Show yarn photos" : "Show yarn photo")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { untuck() }
    }
    
    private var thumbnail: some View {
        Image(uiImage: images[0])
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                if images.count > 1 {
                    Label("\(images.count)", systemImage: "photo.on.rectangle")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(6)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { showViewer = true }
            .accessibilityElement()
            .accessibilityLabel(images.count > 1 ? "Yarn photos" : "Yarn photo")
            .accessibilityHint("Opens the photo full screen")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { showViewer = true }
            .accessibilityAction(named: "Hide") {
                withAnimation(springAnimation) { isTucked = true }
            }
    }
    
    private func position(for corner: Corner, in container: CGSize) -> CGPoint {
        CGPoint(
            x: corner.isLeading ? margin + size.width / 2 : container.width - margin - size.width / 2,
            y: corner.isTop ? margin + size.height / 2 : container.height - margin - size.height / 2
        )
    }
    
    private func nearestCorner(to point: CGPoint, in container: CGSize) -> Corner {
        Corner.allCases.min { first, second in
            let a = position(for: first, in: container)
            let b = position(for: second, in: container)
            return hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
        } ?? .bottomTrailing
    }
}

/// Full-screen photo browser with pinch, pan, and double-tap zoom
struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    
    let images : [UIImage]
    @State private var selection : Int
    
    init(images: [UIImage], startIndex: Int) {
        self.images = images
        _selection = State(initialValue: startIndex)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selection) {
                ForEach(images.indices, id: \.self) { index in
                    ZoomableImageView(image: images[index])
                        .ignoresSafeArea()
                        .tag(index)
                        .accessibilityLabel(images.count > 1 ? "Photo \(index + 1) of \(images.count)" : "Photo")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
            .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.bold())
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Close")
            .padding()
        }
        .statusBarHidden()
    }
}

/// UIScrollView handles zoom, panning, and edge bounce more naturally than SwiftUI gestures,
/// and hands horizontal swipes to the pager once the photo is panned to its edge
struct ZoomableImageView: UIViewRepresentable {
    let image : UIImage
    
    func makeUIView(context: Context) -> ZoomingScrollView {
        ZoomingScrollView(image: image)
    }
    
    func updateUIView(_ view: ZoomingScrollView, context: Context) {}
}

final class ZoomingScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView : UIImageView
    private var laidOutSize : CGSize = .zero
    
    init(image: UIImage) {
        imageView = UIImageView(image: image)
        super.init(frame: .zero)
        
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 5
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds.size != laidOutSize, bounds.width > 0, bounds.height > 0 else { return }
        laidOutSize = bounds.size
        
        // Fit the photo to the screen at 1x, e.g. on first layout or rotation
        zoomScale = 1
        let imageSize = imageView.image?.size ?? bounds.size
        let fitScale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * fitScale, height: imageSize.height * fitScale)
        
        imageView.frame = CGRect(origin: .zero, size: fittedSize)
        contentSize = fittedSize
        centerImage()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    /// Keeps the photo centered while it's smaller than the screen in either direction
    private func centerImage() {
        let horizontal = max((bounds.width - contentSize.width) / 2, 0)
        let vertical = max((bounds.height - contentSize.height) / 2, 0)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
            return
        }
        
        let point = gesture.location(in: imageView)
        let scale : CGFloat = 2.5
        let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
        
        zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
    }
}

/// Read-only carousel for list cards that loads saved photos in the background.
struct StoredImageCarousel: View {
    let images: NSSet?
    var size: Size = Size.medium
    
    @State private var loaded: (objectIDs: [NSManagedObjectID], items: [ImageData])? = nil
    
    var body: some View {
        let objectIDs = StoredImage.objectIDs(from: images)
        
        Group {
            if let loaded, loaded.objectIDs == objectIDs {
                ImageCarousel(images: .constant(loaded.items), size: size)
            } else if let cached = StoredImage.cachedThumbnails(for: objectIDs) {
                ImageCarousel(images: .constant(cached), size: size)
            } else {
                RoundedRectangle(cornerRadius: 20.0)
                    .fill(Color(UIColor.secondarySystemFill))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.vertical, 4)
                    .if(size == Size.extraSmall) { view in
                        view.frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 200 : 100)
                    }
                    .if(size == Size.small && UIDevice.current.userInterfaceIdiom == .pad) { view in
                        view.frame(width: 300)
                    }
            }
        }
        .task(id: objectIDs) {
            let items = await StoredImage.loadThumbnails(for: objectIDs)
            loaded = (objectIDs, items)
        }
    }
}