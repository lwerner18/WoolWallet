//
//  ImagePicker.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import Foundation


import SwiftUI
import UIKit

struct ImagePicker: View {
    @Binding var selectedImage: Image?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {
                // Simulate selecting an image from photo library
                self.selectedImage = Image(systemName: "photo")
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Choose from Library")
            }
            .padding()
            
            Button(action: {
                // Simulate capturing a new photo
                self.selectedImage = Image(systemName: "camera")
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Take Photo")
            }
            .padding()
            
            Spacer()
        }
    }
}
