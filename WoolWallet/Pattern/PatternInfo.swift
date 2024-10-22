//
//  PatternInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

struct YarnSuggestion {
    var patternWAndY : WeightAndYardageData
    var suggestedWAndY : [WeightAndYardage] = []
}

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
    @State private var yarnSuggestions : [YarnSuggestion] = []
    
    
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
                            Image(pattern.type == PatternType.knit.rawValue ? "knit" : "crochet2")
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
                        if !pattern.patternItems.isEmpty && pattern.patternItems.first!.item != Item.none {
                            InfoCard() {
                                Text(
                                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                                )
                                .font(.headline)
                                .bold()
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        if pattern.weightAndYardageItems.count > 3 {
                            ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                                let item : WeightAndYardageData = pattern.weightAndYardageItems[index]
                                
                                InfoCard() {
                                    CollapsibleView(
                                        label : {
                                            RecYarnHeader(count: pattern.weightAndYardageItems.count, index: index, weightAndYardage: item)
                                        },
                                        showArrows : true
                                    ) {
                                        ViewWeightAndYardage(
                                            weightAndYardage: item,
                                            isSockSet: false,
                                            order: index,
                                            totalCount: pattern.weightAndYardageItems.count,
                                            hideName : true
                                        )
                                    }
                                }
                                
                                if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == item.id}) {
                                    YarnSuggestions(
                                        weightAndYardage: item,
                                        matchingWeightAndYardage: suggestion.suggestedWAndY
                                    )
                                }
                            }
                        } else {
                            ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                                let item : WeightAndYardageData = pattern.weightAndYardageItems[index]
                                
                                ViewWeightAndYardage(
                                    weightAndYardage: item,
                                    isSockSet: false,
                                    order: index,
                                    totalCount: pattern.weightAndYardageItems.count
                                )
                                
                                if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == item.id}) {
                                    YarnSuggestions(
                                        weightAndYardage: item,
                                        matchingWeightAndYardage: suggestion.suggestedWAndY
                                    )
                                }
                            }
                        }
                        
                        if pattern.intendedSize != nil && pattern.intendedSize != "" {
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
        .onAppear {
            DispatchQueue.global(qos: .background).async {
                var temp : [YarnSuggestion] = []
                
                for wAndY in pattern.weightAndYardageItems {
                    temp.append(
                        YarnSuggestion(
                            patternWAndY: wAndY,
                            suggestedWAndY: PatternUtils.shared.getMatchingYarns(for: wAndY, in: managedObjectContext)
                        )
                    )
                }
                
                DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                    self.yarnSuggestions = temp
                }
            }
        }
    }
}
