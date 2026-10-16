//
//  PossiblePatterns.swift
//  WoolWallet
//
//  Created by Mac on 10/18/24.
//

import Foundation
import SwiftUI
import CoreData

struct PossiblePatterns: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var patternSuggestion : PatternSuggestion
    @Binding var favoritedPatterns : [FavoritePairing]
    
    @State private var scrollTarget : MatchScrollTarget? = nil
    
    private var sortedMatches: [WeightAndYardage] {
        let yarn = patternSuggestion.yarnWAndY
        let ratio = yarn.grams == 0 ? 0 : yarn.yardage / Double(yarn.grams)
        
        return patternSuggestion.suggestedWAndY.sorted {
            let leftFavorite = favoriteIndex(for: $0.id) != nil ? 0 : 1
            let rightFavorite = favoriteIndex(for: $1.id) != nil ? 0 : 1
            let leftRatio = $0.grams == 0 ? 0 : abs(($0.yardage / Double($0.grams)) - ratio)
            let rightRatio = $1.grams == 0 ? 0 : abs(($1.yardage / Double($1.grams)) - ratio)
            return (leftFavorite, leftRatio) < (rightFavorite, rightRatio)
        }
    }
    
    var body: some View {
        let matches = patternSuggestion.suggestedWAndY
        let ordered = sortedMatches
        
        if !matches.isEmpty {
            MatchCarousel(
                title: "Possible Patterns",
                count: matches.count,
                scrollTarget: scrollTarget,
                orderKey: ordered.map(\.objectID)
            ) {
                ForEach(ordered, id: \.objectID) { match in
                    if let pattern = match.pattern {
                        PatternMatchCard(
                            pattern: pattern,
                            weightAndYardage: match,
                            isFavorite: favoriteIndex(for: match.id) != nil,
                            onToggleFavorite: { toggleFavorite(match) }
                        )
                        .containerRelativeFrame(.horizontal) { length, _ in
                            matches.count > 1 ? length * 0.62 : min(length, 240)
                        }
                        .id(match.objectID)
                    }
                }
            }
        }
    }
    
    private func favoriteIndex(for id: UUID?) -> Int? {
        guard let id else { return nil }
        return favoritedPatterns.firstIndex { $0.patternWeightAndYardage?.id == id }
    }
    
    private func toggleFavorite(_ match: WeightAndYardage) {
        withAnimation(MatchCarouselMotion.reorder) {
            if let index = favoriteIndex(for: match.id) {
                managedObjectContext.delete(favoritedPatterns[index])
                guard PersistenceController.shared.save() else { return }
                favoritedPatterns.remove(at: index)
            } else {
                let favorite = FavoritePairing(context: managedObjectContext)
                favorite.patternWeightAndYardage = match
                favorite.yarnWeightAndYardage = patternSuggestion.yarnWAndY
                guard PersistenceController.shared.save() else { return }
                favoritedPatterns.append(favorite)
            }
            
            scrollTarget = MatchScrollTarget(match.objectID)
        }
    }
}
