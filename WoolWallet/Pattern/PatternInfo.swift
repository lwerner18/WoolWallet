//
//  PatternInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var pattern : Pattern
    var isNewPattern : Bool?
    
    init(pattern: Pattern, isNewPattern : Bool? = false) {
        self.pattern = pattern
        self.isNewPattern = isNewPattern
    }
    
    // Internal state trackers
    @State private var showEditPatternForm : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    var itemDisplay : ItemDisplay {
        return PatternUtils.shared.getItemDisplay(
            for: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item
        )
    }
    
    var body: some View {
        VStack {
            if isNewPattern! {
                // Toolbar-like header
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                .padding(.bottom, 10) // Padding around the button
                .padding(.top, 20) // Padding around the button
                .padding(.horizontal, 20) // Padding around the button
            }
            
            ScrollView {
                if isNewPattern! {
                    VStack {
                        Label("", systemImage: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#008000")) // Set text color
                            .symbolEffect(.bounce, value: animateCheckmark)
                            .padding()
                        
                        Text("Successfully created pattern")
                            .font(.title2)
                        
                        Text("Now get crafting!")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .onAppear {
                        animateCheckmark.toggle()
                    }
                }
                
                ConditionalStack(useVerticalLayout: isPortraitMode) {
                    if itemDisplay.custom {
                        Image(itemDisplay.icon)
                            .iconCircle(background: itemDisplay.color, xl: true)
                    } else {
                        Image(systemName: itemDisplay.icon)
                            .iconCircle(background: itemDisplay.color, xl: true)
                    }
                    
                    VStack {
                        Text(pattern.name ?? "N/A").bold().font(.largeTitle).foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                        
                        Text(pattern.designer ?? "N/A").bold().foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    
                    HStack {
                        HStack {
                            Image(pattern.type == PatternType.crochet.rawValue ? "crochet2" : "knit")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                            Text(pattern.type!)
                        }
                        .infoCapsule()
                        
                        if pattern.oneSize == 1 {
                            Label("One Size", systemImage : "tray.and.arrow.down")
                                .infoCapsule()
                        }
                        
                        Spacer()
                    }
                    
                    VStack {
                        if !pattern.patternItems.isEmpty {
                            InfoCard() {
                                Text(joinedItems(patternItems: pattern.patternItems)).font(.headline).bold().foregroundStyle(Color.primary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        ForEach(pattern.matchingYarns(in: managedObjectContext)) { yarn in
                            Text(yarn.name!)
                            Text(yarn.weight ?? "N/A")
                        }
                        
                        if pattern.intendedSize != nil {
                            InfoCard() {
                                HStack {
                                    Text("Intended Size").foregroundStyle(Color(UIColor.secondaryLabel))
                                    Spacer()
                                    Text(pattern.intendedSize!).font(.headline).bold().foregroundStyle(Color.primary)
                                }
                            }
                        }
                    }
                }
                .foregroundStyle(Color.black)
                .padding()
            }
            .navigationTitle(pattern.name ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditPatternForm = true
                        } label : {
                            Label("Edit", systemImage : "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showConfirmationDialog = true
                        } label: {
                            Label("Delete", systemImage : "trash")
                        }
                        
                    } label: {
                        Label("more", systemImage : "ellipsis")
                    }
                }
            }
            .alert("Are you sure you want to delete this pattern?", isPresented: $showConfirmationDialog) {
                Button("Delete", role: .destructive) {
                    PatternUtils.shared.removePattern(at: pattern, with: managedObjectContext)
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditPatternForm) {
                AddOrEditPatternForm(patternToEdit: pattern)
            }
            
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // Function to join color names with commas
    func joinedItems(patternItems : [PatternItemField]) -> String {
        var itemsSet = Set<String>()
        
        for pattern in patternItems {
            if pattern.item == Item.other {
                if pattern.description != "" {
                    itemsSet.insert(pattern.description.lowercased())
                }
            } else {
                itemsSet.insert(pattern.item.rawValue.lowercased())
            }
        }
        
        var items = Array(itemsSet)
        
        if items.count == 1 && (items.first == Item.socks.rawValue.lowercased() || items.first == Item.mittens.rawValue.lowercased()) {
            return "Makes \(items.first!)"
        } else if items.count == 1 && !Item.allCases.contains(where: { $0.rawValue.lowercased() == items.first })  {
            return "Makes: \(items.first!)"
        } else if items.count == 1 {
            return "Makes a \(items.first!)"
        } else if items.count == 2 {
            return "Makes a \(items[0]) and \(items[1])"
        }
        
        let lastItem = items.removeLast()
        
        return "Makes \(items.joined(separator: ", ")), and \(lastItem)"
    }
}
