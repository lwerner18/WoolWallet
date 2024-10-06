//
//  ImageCarousel.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ImageCarousel: View {
    @Binding var images: [UIImage]
    var editMode: Bool? = false
    var smallMode : Bool? = false
    var editExistingImages : Bool? = false

    @State private var showPhotoPicker : Bool = false
    @State private var selectedImages = [PhotosPickerItem]()
    @State private var scrollOffset = CGPoint.zero
    @State private var showCamera : Bool = false
    @State private var capturedImage : UIImage?
    
    @GestureState private var zoom = 1.0
    
    @State var scale = 1.0
    @State var lastScale = 0.0
    
    var body: some View {
        VStack {
            if images.isEmpty && editMode! {
                Menu {
                    Button {
                        self.showCamera = true
                    } label: {
                        Label("Take a photo", systemImage : "camera")
                    }
                    
                    Button {
                        self.showPhotoPicker = true
                    } label: {
                        Label("Select photos", systemImage : "photo.on.rectangle")
                    }
                    
                } label: {
                    Label("", systemImage : "photo.badge.plus").font(.system(size: 30)).frame(maxWidth: .infinity)
                }
                .fullScreenCover(isPresented: self.$showCamera) {
                    accessCameraView(selectedImage: self.$capturedImage)
                }
                
            } else {
                VStack {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            ForEach(0..<images.count,id: \.self){ imageIndex in
                                Image(uiImage: images[imageIndex])
                                    .resizable()
                                    .aspectRatio(contentMode: smallMode! ? .fill : .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 25.0))
                                    .tag(imageIndex)
                                    .containerRelativeFrame(.horizontal)
                                    .overlay(
                                        editMode!
                                        ? AnyView(Button(action: {
                                            // Delete action
                                            images.remove(at: imageIndex)
                                        }) {
                                            Image(systemName: "xmark.circle")
                                                .font(.title)
                                                .foregroundColor(Color.black.opacity(0.75))
                                                .background(.white)
                                                .clipShape(Circle())
                                        }
                                            .padding(.top, 15)
                                            .padding(.trailing, 20))
                                        : AnyView(EmptyView()),
                                        alignment: .topTrailing
                                        
                                    )
                                    .overlay(
                                        editMode!
                                        ? AnyView(Button(action: {
                                            showPhotoPicker = true
                                        }) {
                                            Label("", systemImage : "photo.badge.plus").font(.title2)
                                        }
                                            .padding(.bottom, 10)
                                            .padding(.trailing, 20))
                                        : AnyView(EmptyView()),
                                        alignment: .bottomTrailing
                                        
                                    )
                                    .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                    }
                            }
                        }
                        .background(GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                        })
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            self.scrollOffset = value
                        }
                        
                    }
                    .overlay(
                        images.count > 1
                        ? AnyView(
                            HStack {
                                
                                Spacer()
                                
                                let screenWidth = UIScreen.main.bounds.size.width
                                let pagesSwiped = (scrollOffset.x / screenWidth) * -1.0
                                let currentImageIndex = Int(pagesSwiped.rounded(.up))
                                let size : CGFloat = smallMode! ? 4 : 7
                                
                                // Create a ZStack to overlay the dots on a capsule
                                ZStack {
                                    // Light gray capsule background
                                    Capsule()
                                        .fill(Color.black.opacity(0.5)) // Adjust opacity for light gray
                                        .frame(width: CGFloat(images.count) * (size + 11), height: size + 11) // Adjust the frame based on the number of dots
                                    
                                    // Dots
                                    HStack(spacing: 6) { // Adjust spacing between dots
                                        ForEach(0..<images.count, id: \.self) { index in
                                            Circle()
                                                .fill(index == currentImageIndex ? Color.white : Color.gray)
                                                .frame(width: size, height: size)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                                .padding(.bottom, smallMode! ? 4 : 8)
                        )
                        : AnyView(EmptyView()),
                        alignment: .bottom
                    )
                    .coordinateSpace(name: "scroll")
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollDisabled(images.count <= 1)
                }
                .padding(0)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImages, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedImages) {
            if editMode! {
                Task {
                    if !editExistingImages! {
                        images.removeAll()
                    }
                    
                    for item in selectedImages {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            let image = UIImage(data: data)
                            images.append(image!)
                        } else {
                            print("Failed to load the image")
                        }
                    }
                }
            }
        }
    }
    
    private func handleScaleChange(_ zoom: CGFloat) -> CGFloat {
        min(max((lastScale + zoom - (lastScale == 0 ? 0 : 1)), 1.0), 3.0)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}
