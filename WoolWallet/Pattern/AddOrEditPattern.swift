//
//  AddOrEditPattern.swift
//  WoolWallet
//
//  Created by Mac on 9/29/24.
//

import Foundation
import SwiftUI

struct AddOrEditPattern: View {
    var body: some View {
        NavigationStack {
            Form {
                Section(){
                    Text("test")
                }
            }
            .navigationTitle("Add/Edit Pattern")
            .navigationBarTitleDisplayMode(.inline) // Optional: controls title display mode
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Handle cancellation (e.g., dismiss the view)
                    }
                }
            }
        }
    }
}
