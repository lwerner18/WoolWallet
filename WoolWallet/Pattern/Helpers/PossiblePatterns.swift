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
 
    init(
        patternSuggestion : PatternSuggestion,
        favoritedPatterns : Binding<[FavoritePairing]>
    ) {
        self.patternSuggestion = patternSuggestion
        self._favoritedPatterns = favoritedPatterns
    }
    
    var body: some View {
        if !patternSuggestion.suggestedWAndY.isEmpty {
            VStack {
                CollapsibleView(
                    label : {
                        Text("Possible Patterns (\(patternSuggestion.suggestedWAndY.count))").foregroundStyle(Color.primary)
                    },
                    showArrows : true,
                    useInfoCard : true
                ) {
                    SimpleHorizontalScroll(
                        count: patternSuggestion.suggestedWAndY.count,
                        halfWidthInLandscape : true
                    ) {
                        let ratio = patternSuggestion.yarnWAndY.yardage / Double(patternSuggestion.yarnWAndY.grams)
                        
                        let sorted = patternSuggestion.suggestedWAndY.sorted {
                            (getFavoritesIndex(for: $0.id!) != nil ? 0 : 1, abs(($0.yardage / Double($0.grams)) - ratio)) <
                                (getFavoritesIndex(for: $1.id!) != nil ? 0 : 1, abs(($1.yardage / Double($1.grams)) - ratio))
                        }
                        
                        ForEach(sorted, id : \.id) { wAndYMatch in
                            let favoriteIndex = getFavoritesIndex(for: wAndYMatch.id!)
                            
                            let pattern = wAndYMatch.pattern!
                            
                            InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                                HStack {
                                    
                                    VStack {
                                        PatternItemDisplay(pattern: pattern, size: Size.large)
                                        
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
                                        
                                        ViewLengthAndYardage(weightAndYardage: wAndYMatch)
                                    }
                                    
                                    Spacer()
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
                                    }.offset(x: 10, y: 0),
                                    alignment: .topTrailing
                                    
                                )
                            }
                        }
                    }
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
