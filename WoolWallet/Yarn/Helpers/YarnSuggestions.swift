//
//  YarnSuggestions.swift
//  WoolWallet
//
//  Created by Mac on 10/18/24.
//

import Foundation
import SwiftUI
import CoreData

struct YarnSuggestions: View {
    var yarnSuggestion : YarnSuggestion
    
    var body: some View {
        let matches = yarnSuggestion.suggestedWAndY
        
        if !matches.isEmpty {
            YarnSuggestionCarousel(
                weightAndYardage: yarnSuggestion.patternWAndY,
                matchingWeightAndYardage: matches,
                title: "Yarn Suggestions"
            )
        }
    }
}

struct YarnSuggestionCarousel: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var weightAndYardage : WeightAndYardage
    var matchingWeightAndYardage : [WeightAndYardage]
    var forProject : Bool = false
    var title : String? = "Yarn Suggestions"
    @Binding var projectPairing : [ProjectPairingItem]
    
    var favoritesRequest : FetchRequest<FavoritePairing>
    var favoriteYarns : FetchedResults<FavoritePairing> { favoritesRequest.wrappedValue }
    
    @State private var scrollTarget : MatchScrollTarget? = nil
    
    init(
        weightAndYardage : WeightAndYardage,
        matchingWeightAndYardage : [WeightAndYardage],
        forProject : Bool = false,
        title : String? = "Yarn Suggestions",
        projectPairing : Binding<[ProjectPairingItem]> = .constant([])
    ) {
        self.weightAndYardage = weightAndYardage
        self.matchingWeightAndYardage = matchingWeightAndYardage
        self.forProject = forProject
        self.title = title
        self._projectPairing = projectPairing
        
        self.favoritesRequest = FetchRequest(
            entity: FavoritePairing.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "patternWeightAndYardage.id == %@", weightAndYardage.id! as any CVarArg)
        )
    }
    
    private var sortedMatches: [WeightAndYardage] {
        let ratio = weightAndYardage.grams == 0 ? 0 : weightAndYardage.yardage / Double(weightAndYardage.grams)
        
        return matchingWeightAndYardage.sorted {
            let leftFavorite = favoriteIndex(for: $0.id) != nil ? 0 : 1
            let rightFavorite = favoriteIndex(for: $1.id) != nil ? 0 : 1
            let leftRatio = $0.grams == 0 ? 0 : abs(($0.yardage / Double($0.grams)) - ratio)
            let rightRatio = $1.grams == 0 ? 0 : abs(($1.yardage / Double($1.grams)) - ratio)
            return (leftFavorite, leftRatio) < (rightFavorite, rightRatio)
        }
    }
    
    var body: some View {
        let matches = sortedMatches
        
        MatchCarousel(
            title: title,
            count: matchingWeightAndYardage.count,
            scrollTarget: scrollTarget,
            orderKey: matches.map(\.objectID)
        ) {
            ForEach(matches, id: \.objectID) { match in
                YarnMatchCard(
                    yarnWandY: match,
                    isFavorite: favoriteIndex(for: match.id) != nil,
                    onToggleFavorite: { toggleFavorite(match) },
                    onAdd: forProject ? { addToProject(match) } : nil
                )
                .containerRelativeFrame(.horizontal) { length, _ in
                    matchingWeightAndYardage.count > 1 ? length * 0.62 : min(length, 240)
                }
                .id(match.objectID)
            }
        }
    }
    
    private func favoriteIndex(for id: UUID?) -> Int? {
        guard let id else { return nil }
        return favoriteYarns.firstIndex { $0.yarnWeightAndYardage?.id == id }
    }
    
    private func toggleFavorite(_ match: WeightAndYardage) {
        withAnimation(MatchCarouselMotion.reorder) {
            if let index = favoriteIndex(for: match.id) {
                managedObjectContext.delete(favoriteYarns[index])
            } else {
                let favorite = FavoritePairing(context: managedObjectContext)
                favorite.yarnWeightAndYardage = match
                favorite.patternWeightAndYardage = weightAndYardage
            }
            
            guard PersistenceController.shared.save() else { return }
            scrollTarget = MatchScrollTarget(match.objectID)
        }
    }
    
    private func addToProject(_ match: WeightAndYardage) {
        withAnimation {
            projectPairing.append(
                ProjectPairingItem(
                    patternWeightAndYardage: weightAndYardage,
                    yarnWeightAndYardage: match
                )
            )
        }
    }
}

/// Collapsible wrapper used while picking yarn for a new project
struct YarnSuggestionCollapsible : View {
    var weightAndYardage : WeightAndYardage
    var matchingWeightAndYardage : [WeightAndYardage]
    var allowEdits : Bool
    var forProject : Bool
    var openByDefault : Bool
    var title : String
    @Binding var projectPairing: [ProjectPairingItem]
    
    init(
        weightAndYardage : WeightAndYardage,
        matchingWeightAndYardage : [WeightAndYardage],
        allowEdits : Bool = true,
        forProject : Bool = false,
        openByDefault : Bool = false,
        title : String = "Yarn Suggestions",
        projectPairing: Binding<[ProjectPairingItem]>
    ) {
        self.weightAndYardage = weightAndYardage
        self.matchingWeightAndYardage = matchingWeightAndYardage
        self.allowEdits = allowEdits
        self.forProject = forProject
        self.openByDefault = openByDefault
        self.title = title
        self._projectPairing = projectPairing
    }
    
    var body : some View {
        CollapsibleView(
            label : {
                Text("\(title) (\(matchingWeightAndYardage.count))")
                    .foregroundStyle(Color.primary)
            },
            showArrows : true,
            openByDefault : openByDefault,
            useInfoCard : true
        ) {
            YarnSuggestionCarousel(
                weightAndYardage: weightAndYardage,
                matchingWeightAndYardage: matchingWeightAndYardage,
                forProject: forProject,
                title: nil,
                projectPairing: $projectPairing
            )
        }
    }
}
