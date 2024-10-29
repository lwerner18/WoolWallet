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
            InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                YarnSuggestionCollapsible(
                    weightAndYardage: yarnSuggestion.patternWAndY,
                    matchingWeightAndYardage: yarnSuggestion.suggestedWAndY,
                    projectPairing : .constant([])
                )
            }
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
    @Binding var projectPairing: [ProjectPairing]
    
    @State private var scrollOffset = CGPoint.zero
    
    var favoritesRequest : FetchRequest<FavoritePairing>
    var favoriteYarns : FetchedResults<FavoritePairing>{favoritesRequest.wrappedValue}
    
    init(
        weightAndYardage : WeightAndYardage,
        matchingWeightAndYardage : [WeightAndYardage],
        allowEdits : Bool = true,
        forProject : Bool = false,
        openByDefault : Bool = false,
        projectPairing: Binding<[ProjectPairing]>
    ) {
        self.weightAndYardage = weightAndYardage
        self.matchingWeightAndYardage = matchingWeightAndYardage
        self.allowEdits = allowEdits
        self.forProject = forProject
        self.openByDefault = openByDefault
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
                Text("Yarn suggestions (\(matchingWeightAndYardage.count))").foregroundStyle(Color.primary)
            },
            showArrows : true,
            openByDefault : openByDefault
        ) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    let ratio = weightAndYardage.yardage / Double(weightAndYardage.grams)
                    
                    let sorted = matchingWeightAndYardage.sorted {
                        (getFavoritesIndex(for: $0.id!) != nil ? 0 : 1, abs(($0.yardage / Double($0.grams)) - ratio)) <
                            (getFavoritesIndex(for: $1.id!) != nil ? 0 : 1, abs(($1.yardage / Double($1.grams)) - ratio))
                    }
                    
                    ForEach(sorted) { wAndYMatch in
                        let favoriteIndex = getFavoritesIndex(for: wAndYMatch.id!)
                        
                        let yarn = wAndYMatch.yarn!
                        
                        HStack {
                            VStack {
                                ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
                                    .frame(width: 75, height: 100)
                                
                                if yarn.isSockSet {
                                    Label("Sock Set", systemImage : "shoeprints.fill")
                                        .infoCapsule(isSmall: true)
                                    
                                    if yarn.isSockSet {
                                        switch wAndYMatch.order {
                                        case 0: Text("Main Skein").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                        case 1: Text("Mini Skein").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                        case 2: Text("Mini #2").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                        default: EmptyView()
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center) {
                                Text(yarn.name!)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.primary)
                                    .bold()
                                
                                Text(yarn.dyer!)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.caption)
                                    .bold()
                                
                                Spacer()
                                
                                let unit = wAndYMatch.unitOfMeasure!.lowercased()
                                
                                
                                if wAndYMatch.exactLength > 0 {
                                    Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndYMatch.exactLength)) ?? "1") \(unit)")
                                        .font(.title3)
                                        .foregroundStyle(Color.primary)
                                } else {
                                    Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndYMatch.approxLength)) ?? "1") \(unit)")
                                        .font(.title3)
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
                            HStack {
                                if allowEdits {
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
                                    }
                                } else {
                                    Label("", systemImage : favoriteIndex != nil ? "heart.fill" : "heart")
                                        .font(.title3)
                                        .foregroundStyle(Color(UIColor.systemPink))
                                        .contentTransition(.symbolEffect(.replace))
                                }
                             
                                
                                if forProject {
                                    Button {
                                        withAnimation {
                                            projectPairing.append(
                                                ProjectPairing(
                                                    patternWeightAndYardageId: weightAndYardage.id!,
                                                    yarnWeightAndYardage: wAndYMatch
                                                )
                                            )
                                        }
                                    } label: {
                                        Label("", systemImage : "plus.circle").font(.title3)
                                    }
                                }
                            }
                                .padding(.leading, 10),
                            alignment: .topTrailing
                            
                        )
                        .padding(.vertical, 4)
                    }
                }
                .scrollTracker(
                    scrollOffset : $scrollOffset,
                    name: "scroll"
                )
            }
            .overlay(
                matchingWeightAndYardage.count > 1
                ? AnyView(
                    ScrollDots(
                        scrollOffset: scrollOffset,
                        numberOfDots: matchingWeightAndYardage.count,
                        smallMode: true,
                        hasBottomPadding: false
                    )
                )
                : AnyView(EmptyView()),
                alignment: .bottomTrailing
            )
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollDisabled(matchingWeightAndYardage.count <= 1)
        }
    }
        
    func getFavoritesIndex(for id: UUID) -> Optional<Int> {
        return favoriteYarns.firstIndex(where: { element in
            return element.yarnWeightAndYardage?.id == id
        })
    }
}
