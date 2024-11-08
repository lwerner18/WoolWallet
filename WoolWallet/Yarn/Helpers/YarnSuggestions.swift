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
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var yarnSuggestion : YarnSuggestion
    
    init(
        yarnSuggestion : YarnSuggestion
    ) {
        self.yarnSuggestion = yarnSuggestion
    }
    
    var body: some View {
        if !yarnSuggestion.suggestedWAndY.isEmpty {
            YarnSuggestionCollapsible(
                weightAndYardage: yarnSuggestion.patternWAndY,
                matchingWeightAndYardage: yarnSuggestion.suggestedWAndY,
                projectPairing : .constant([])
            )
        }
    }
}

struct YarnSuggestionCollapsible : View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var weightAndYardage : WeightAndYardage
    var matchingWeightAndYardage : [WeightAndYardage]
    var allowEdits : Bool
    var forProject : Bool
    var openByDefault : Bool
    var title : String
    @Binding var projectPairing: [ProjectPairingItem]
    
    var favoritesRequest : FetchRequest<FavoritePairing>
    var favoriteYarns : FetchedResults<FavoritePairing>{favoritesRequest.wrappedValue}
    
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
        
        self.favoritesRequest = FetchRequest(
            entity: FavoritePairing.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "patternWeightAndYardage.id == %@", weightAndYardage.id! as any CVarArg)
        )
   
    }
    
    var body : some View {
        CollapsibleView(
            label : {
                Text("\(title) (\(matchingWeightAndYardage.count))").foregroundStyle(Color.primary)
            },
            showArrows : true,
            openByDefault : openByDefault,
            useInfoCard : true
        ) {
            SimpleHorizontalScroll(count: matchingWeightAndYardage.count) {
                let ratio = weightAndYardage.yardage / Double(weightAndYardage.grams)
                
                let sorted = matchingWeightAndYardage.sorted {
                    (getFavoritesIndex(for: $0.id!) != nil ? 0 : 1, abs(($0.yardage / Double($0.grams)) - ratio)) <
                        (getFavoritesIndex(for: $1.id!) != nil ? 0 : 1, abs(($1.yardage / Double($1.grams)) - ratio))
                }
                
                ForEach(sorted, id : \.id) { wAndYMatch in
                    let favoriteIndex = getFavoritesIndex(for: wAndYMatch.id!)
                    
                    InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                        YarnPreview(yarnWandY : wAndYMatch)
                        .overlay(
                            Button(action: {
                                if favoriteIndex != nil {
                                    managedObjectContext.delete(favoriteYarns[favoriteIndex!])
                                } else {
                                    let newFavorite = FavoritePairing(context: managedObjectContext)
                                    newFavorite.yarnWeightAndYardage = wAndYMatch
                                    newFavorite.patternWeightAndYardage = weightAndYardage
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
                        .overlay(
                            HStack {
                                if forProject {
                                    Button {
                                        withAnimation {
                                            projectPairing.append(
                                                ProjectPairingItem(
                                                    patternWeightAndYardage: weightAndYardage,
                                                    yarnWeightAndYardage: wAndYMatch
                                                )
                                            )
                                        }
                                    } label: {
                                        Label("", systemImage : "plus.circle").font(.title3)
                                    }
                                    .offset(x: 10, y: 0)
                                }
                            },
                            alignment: .bottomTrailing
                            
                        )
                    }
                    .simpleScrollItem(count: matchingWeightAndYardage.count)
                    .padding(.top, forProject ? 5 : 0)
                }
               
            }
        }
    }
        
    func getFavoritesIndex(for id: UUID) -> Optional<Int> {
        return favoriteYarns.firstIndex(where: { element in
            return element.yarnWeightAndYardage?.id == id
        })
    }
}
