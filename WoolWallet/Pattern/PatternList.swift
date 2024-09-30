//
//  PatternList.swift
//  WoolWallet
//
//  Created by Mac on 9/3/24.
//

import Foundation
import SwiftUI

struct PatternList: View {
    var body: some View {
        NavigationStack {
            Text("Patterns")
                .navigationTitle("Patterns")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: AddOrEditPattern()
                        ) {
                            Image(systemName: "plus") // Use a system icon
                                .imageScale(.large)
                        }
                    }
                }
        }
    }
}
