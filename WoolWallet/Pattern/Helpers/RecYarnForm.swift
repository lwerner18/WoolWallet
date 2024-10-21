//
//  RecYarnForm.swift
//  WoolWallet
//
//  Created by Mac on 10/11/24.
//

import Foundation
import SwiftUI

struct RecYarnForm: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    
    @Binding var recWeightAndYardages : [WeightAndYardageData]
    
    var body: some View {
        Form {
            ForEach($recWeightAndYardages.indices, id: \.self) { index in
                WeightAndYardageForm(
                    weightAndYardage: $recWeightAndYardages[index],
                    isSockSet: false,
                    order: index,
                    totalCount: recWeightAndYardages.count,
                    addAction: {addWeightAndYardage()},
                    removeAction: {removeWeightAndYardage(recWeightAndYardages[index])}
                )
            }
            
            Button("Save", action: {
                dismiss()
            })
        }
        .navigationTitle("Yarn Specs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "checkmark") // Use a system icon
                        .imageScale(.large)
                }
            }
        }
    }
    
    private func addWeightAndYardage() {
        recWeightAndYardages.append(
            WeightAndYardageData(
                weight: recWeightAndYardages.first!.weight,
                parent: WeightAndYardageParent.pattern
            )
        )
    }
    
    private func removeWeightAndYardage(_ item: WeightAndYardageData) {
        recWeightAndYardages.removeAll { $0.id == item.id }
    }
}
