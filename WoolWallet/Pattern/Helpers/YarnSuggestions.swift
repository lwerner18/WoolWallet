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
    
    var weightAndYardage : WeightAndYardageData
    
    var favoritesRequest : FetchRequest<FavoriteYarnForPattern>
    var favoriteYarns : FetchedResults<FavoriteYarnForPattern>{favoritesRequest.wrappedValue}
    
    init(weightAndYardage : WeightAndYardageData) {
        self.weightAndYardage = weightAndYardage
        
        self.favoritesRequest = FetchRequest(
            entity: FavoriteYarnForPattern.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "patternWeightAndYardageId == %@", weightAndYardage.id as CVarArg)
        )
    }
    
    var matchingWeightAndYardage : [WeightAndYardage] {
        weightAndYardage.matchingYarns(in: managedObjectContext)
    }
    
    var body: some View {
        if !matchingWeightAndYardage.isEmpty {
            InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
                CollapsibleView(
                    label : {
                        Text("Yarn suggestions (\(matchingWeightAndYardage.count))").foregroundStyle(Color.primary)
                    },
                    showArrows : true
                ) {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            ForEach(matchingWeightAndYardage) { wAndYMatch in
                                let favoriteIndex = favoriteYarns.firstIndex(where: { element in
                                    return element.yarnWeightAndYardageId == wAndYMatch.id
                                })
                                
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
                                    Button(action: {
                                        if favoriteIndex != nil {
                                            managedObjectContext.delete(favoriteYarns[favoriteIndex!])
                                        } else {
                                            let newFavorite = FavoriteYarnForPattern(context: managedObjectContext)
                                            newFavorite.yarnWeightAndYardageId = wAndYMatch.id
                                            newFavorite.patternWeightAndYardageId = weightAndYardage.id
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
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollDisabled(matchingWeightAndYardage.count <= 1)
                }
            }
        }
    }
}
