//
//  TextFieldTypeahead.swift
//  WoolWallet
//
//  Created by Mac on 9/26/24.
//

import Foundation
import SwiftUI
import Combine

struct TextFieldTypeahead: View {
    @Binding var field: String
    var label: String
    var allResults : [String]
    
    @State private var filteredResults: [String] = []
    // Timer for debouncing
    @State private var debounceTimer: AnyCancellable? = nil
    @State private var hideSuggestions : Bool = true
    @State private var buttonTapped: Bool = false
    
    var body: some View {
        TextField(label, text: $field)
            .disableAutocorrection(true)
            .onChange(of: field) { newValue in
                // Cancel previous timer if it exists
                debounceTimer?.cancel()
                
                // Start a new timer
                debounceTimer = Just(newValue)
                    .delay(for: .milliseconds(300), scheduler: RunLoop.main) // Adjust the delay as needed
                    .sink { value in
                        // Update filtered dyers based on the input
                        if value.isEmpty {
                            filteredResults = [] // Clear when input is empty
                        } else {
                            filteredResults = allResults.filter { $0.lowercased().contains(value.lowercased()) }
                        }
                        
                        if !buttonTapped {
                            hideSuggestions = false
                        } else {
                            buttonTapped = false
                        }
                    }
            }
        
        if !filteredResults.isEmpty && !hideSuggestions {
            VStack {
                ForEach(filteredResults, id: \.self) { filteredResult in
                    if filteredResult != field {
                        HStack {
                            Text(filteredResult)
                                .foregroundColor(.blue) // Text color
                               
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity) // Make sure the HStack takes full width
                        .contentShape(Rectangle()) // Ensure the tap area is the full HStack
                        .onTapGesture {
                            field = filteredResult
                            hideSuggestions = true
                            buttonTapped = true
                        }
                        
                        Divider()
                    }
                }
            }
        }
    }
}

