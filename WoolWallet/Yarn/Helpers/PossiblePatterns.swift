//
//  PatternFavorites.swift
//  WoolWallet
//
//  Created by Mac on 10/18/24.
//

import Foundation
import SwiftUI
import CoreData

struct PossiblePatterns: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var patternSuggestion : PatternSuggestion
    @Binding var favoritedPatterns : [FavoritePairing]
    
    @State private var scrollOffset = CGPoint.zero
    
    init(
        patternSuggestion : PatternSuggestion,
        favoritedPatterns : Binding<[FavoritePairing]>
    ) {
        self.patternSuggestion = patternSuggestion
        self._favoritedPatterns = favoritedPatterns
    }
    
    var body: some View {
        if !patternSuggestion.suggestedWAndY.isEmpty {
            InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                CollapsibleView(
                    label : {
                        Text("Possible Patterns (\(patternSuggestion.suggestedWAndY.count))").foregroundStyle(Color.primary)
                    },
                    showArrows : true
                ) {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            let ratio = patternSuggestion.yarnWAndY.yardage / Double(patternSuggestion.yarnWAndY.grams)
                            
                            let sorted = patternSuggestion.suggestedWAndY.sorted {
                                (getFavoritesIndex(for: $0.id!) != nil ? 0 : 1, abs(($0.yardage / Double($0.grams)) - ratio)) <
                                    (getFavoritesIndex(for: $1.id!) != nil ? 0 : 1, abs(($1.yardage / Double($1.grams)) - ratio))
                            }
                            
                            ForEach(sorted) { wAndYMatch in
                                let favoriteIndex = getFavoritesIndex(for: wAndYMatch.id!)
                                
                                let pattern = wAndYMatch.pattern!
                                
                                HStack {
                                    
                                    VStack {
                                        let itemDisplay =
                                        PatternUtils.shared.getItemDisplay(
                                            for: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item
                                        )
                                        
                                        if itemDisplay.custom {
                                            Image(itemDisplay.icon)
                                                .iconCircle(background: itemDisplay.color, xl: true)
                                        } else {
                                            Image(systemName: itemDisplay.icon)
                                                .iconCircle(background: itemDisplay.color, xl: true)
                                        }
                                        
                                        HStack {
                                            Image(pattern.type == PatternType.knit.rawValue ? "knit" : "crochet2")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 10, height: 10)
                                            
                                            Text(pattern.type!)
                                        }
                                        .infoCapsule(isSmall: true)
                                    }
                                    
                                    Spacer()

                                    
                                    VStack(alignment: .center) {
                                        Text(pattern.name!)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        Text(pattern.designer!)
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption)
                                            .bold()
                                        
                                        Spacer()
                                        
                                        if pattern.patternItems.first?.item == Item.other {
                                            Text(
                                                PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                                            )
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            
                                            Spacer()
                                        }
                                        
                                        let unit = wAndYMatch.unitOfMeasure!.lowercased()
                                        
                                        if wAndYMatch.exactLength > 0 {
                                            Text("\(pattern.weightAndYardageItems.count > 1 ? "Color \(PatternUtils.shared.getLetter(for: Int(wAndYMatch.order))) requires" : "Requires") \(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndYMatch.exactLength)) ?? "1") \(unit)")
                                                .foregroundStyle(Color.primary)
                                        } else {
                                            Text("\(pattern.weightAndYardageItems.count > 1 ? "Color \(PatternUtils.shared.getLetter(for: Int(wAndYMatch.order))) requires" : "Requires") \(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndYMatch.approxLength)) ?? "1") \(unit)")
                                                .foregroundStyle(Color.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        if wAndYMatch.yardage > 0 && wAndYMatch.grams > 0 {
                                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndYMatch.yardage)) ?? "") \(unit) / \(wAndYMatch.grams) grams")
                                                .font(.caption)
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .containerRelativeFrame(.horizontal)
                                .scrollTransition(.animated, axis: .horizontal) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                }
                                .overlay(
                                    Button(action: {
                                        if favoriteIndex != nil {
                                            managedObjectContext.delete(favoritedPatterns[favoriteIndex!])
                                            
                                            favoritedPatterns.remove(at: favoriteIndex!)
                                        } else {
                                            let newFavorite = FavoritePairing(context: managedObjectContext)
                                            newFavorite.patternWeightAndYardage = wAndYMatch
                                            newFavorite.yarnWeightAndYardage = patternSuggestion.yarnWAndY
                                            
                                            favoritedPatterns.append(newFavorite)
                                        }
                                        
                                        PersistenceController.shared.save()
                                        
                                    }) {
                                        Label("", systemImage : favoriteIndex != nil ? "heart.fill" : "heart")
                                            .font(.title3)
                                            .foregroundStyle(Color(UIColor.systemPink))
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                        .padding(.leading, 10),
                                    alignment: .topTrailing
                                    
                                )
                            }
                        }
                        .scrollTracker(
                            scrollOffset : $scrollOffset,
                            name: "scroll"
                        )
                    }
                    .overlay(
                        patternSuggestion.suggestedWAndY.count > 1
                        ? AnyView(
                            ScrollDots(
                                scrollOffset: scrollOffset,
                                numberOfDots: patternSuggestion.suggestedWAndY.count,
                                smallMode: true,
                                hasBottomPadding: false
                            )
                        )
                        : AnyView(EmptyView()),
                        alignment: .bottomTrailing
                    )
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollDisabled(patternSuggestion.suggestedWAndY.count <= 1)
                }
            }
        }
    }
    
    func getFavoritesIndex(for id: UUID) -> Optional<Int> {
        return favoritedPatterns.firstIndex(where: { element in
            return element.patternWeightAndYardage?.id == id
        })
    }
}
