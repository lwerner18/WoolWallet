//
//  ImageCarousel.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ImageData: Equatable {
    var id = UUID()
    var image : UIImage
    var existingItem : StoredImage? = nil
}

struct ImageCarousel: View {
    @Binding var images: [ImageData]
    var editMode: Bool = false
    var size : Size = Size.medium
    var editExistingImages : Bool? = false

    @State private var showPhotoPicker : Bool = false
    @State private var selectedImages = [PhotosPickerItem]()
    @State private var showCamera : Bool = false
    @State private var capturedImage : UIImage?
    
    
    var body: some View {
        VStack {
            if images.isEmpty && editMode {
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
                    FancyHorizontalScroll(count: images.count, size: size) {
                        ForEach(0..<images.count, id: \.self){ imageIndex in
                            Image(uiImage: images[imageIndex].image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20.0))
                                .tag(imageIndex)
                                .containerRelativeFrame(.horizontal)
                                .overlay(
                                    editMode
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
                                    editMode
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
                        }
                    }
                }
                .padding(0)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImages, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedImages) {
            if editMode {
                Task {
                    if !editExistingImages! {
                        images.removeAll()
                    }
                    
                    for item in selectedImages {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            let image = UIImage(data: data)
                            images.append(ImageData(image: image!))
                        } else {
                            print("Failed to load the image")
                        }
                    }
                }
            }
        }
        .onChange(of: capturedImage) {
            if editMode && capturedImage != nil {
                Task {
                    if !editExistingImages! {
                        images.removeAll()
                    }
                    
                    images.append(ImageData(image: capturedImage!))
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
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}
