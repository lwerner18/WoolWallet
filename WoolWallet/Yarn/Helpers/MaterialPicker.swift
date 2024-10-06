//
//  MaterialPicker.swift
//  WoolWallet
//
//  Created by Mac on 10/6/24.
//

import Foundation
import SwiftUI

struct Material : Identifiable, Hashable {
    let id = UUID()
    let category: MaterialCategory
    let subTypes: [String]
}

let materials = [
    Material(
        category: MaterialCategory.wool,
        subTypes: ["Merino Wool", "Virgin Wool", "Superwash Wool"]
    ),
    Material(
        category: MaterialCategory.alpaca,
        subTypes: ["Alpaca"]
    ),
    Material(
        category: MaterialCategory.cashmere,
        subTypes: ["Cashmere"]
    ),
    Material(
        category: MaterialCategory.mohair,
        subTypes: ["Mohair"]
    ),
    Material(
        category: MaterialCategory.cotton,
        subTypes: ["American Cotton", "Pima Cotton", "Egyptian Cotton", "Mercerized Cotton"]
    ),
    Material(
        category: MaterialCategory.linen,
        subTypes: ["Linen"]
    ),
    Material(
        category: MaterialCategory.bamboo,
        subTypes: ["Bamboo"]
    ),
    Material(
        category: MaterialCategory.silk,
        subTypes: ["Silk"]
    ),
    Material(
        category: MaterialCategory.acrylic,
        subTypes: ["Acrylic"]
    ),
    Material(
        category: MaterialCategory.acrylic,
        subTypes: ["Nylon"]
    ),
    Material(
        category: MaterialCategory.rayon,
        subTypes: ["Viscose", "Tencel / Lyocell", "Modal"]
    ),
    Material(
        category: MaterialCategory.other,
        subTypes: ["Other"]
    )
]

struct MaterialPicker: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    
    @Binding var material : String
    
    var body: some View {
        Form {
            ForEach(materials, id: \.id) { materialItem in
                // Group 1
                Section(header: Text(materialItem.category.rawValue)) {
                    ForEach(materialItem.subTypes, id: \.self) { subType in
                        HStack {
                            Text(subType)
                                .onTapGesture {
                                    material = subType
                                    
                                    dismiss()
                                }
                            
//                            Button {
//                           
//                            } label : {
//
//                            }
//                            .buttonStyle(.plain)
//                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                                .onTapGesture {
                                    material = subType
                                    
                                    dismiss()
                                }
                            
                            if material == subType {
                                Label("", systemImage: "checkmark")
                                    .font(.footnote)
                                    .bold()
                                    .foregroundStyle(.blue)
                                    .onTapGesture {
                                        material = subType
                                        
                                        dismiss()
                                    }
                            }
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                            return 0
                        }
//                        .frame(maxWidth: .infinity)
//                        .onTapGesture {
//                            material = subType
//                            
//                            dismiss()
//                        }
                        
                    }
                }
            }
        }
        .navigationTitle("Material")
        .navigationBarTitleDisplayMode(.inline)
    }
}
