//
//  PatternFavorites.swift
//  WoolWallet
//
//  Created by Mac on 10/18/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternFavorites: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    var yarn : Yarn
    
    var favoritesRequest : FetchRequest<FavoriteYarnForPattern>
    var favoriteYarns : FetchedResults<FavoriteYarnForPattern>{favoritesRequest.wrappedValue}
    
    var patternsRequest : FetchRequest<Pattern>
    var patterns : FetchedResults<Pattern>{patternsRequest.wrappedValue}
    
//    init(yarn: Yarn) {
//        self.yarn = yarn
//        
//        self.favoritesRequest = FetchRequest(
//            entity: FavoriteYarnForPattern.entity(),
//            sortDescriptors: [],
//            predicate: NSPredicate(format: "yarnId == %@", yarn.id! as CVarArg)
//        )
//    }
    
    var body: some View {
        Text("Hi")
//        if !favoriteYarns.isEmpty {
//            InfoCard(backgroundColor: Color.accentColor.opacity(0.1)) {
//                CollapsibleView(
//                    label : {
//                        Text("Patterns in mind (\(favoriteYarns.count))").foregroundStyle(Color.primary)
//                    },
//                    showArrows : true
//                ) {
//                    ScrollView(.horizontal) {
//                        LazyHStack(spacing: 0) {
//                            ForEach(matchingYarn) { yarn in
//                                let favoriteIndex = favoriteYarns.firstIndex(where: { element in
//                                    return element.yarnId == yarn.id
//                                })
//                                
//                                HStack {
//                                    ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
//                                        .frame(width: 75, height: 100)
//                                    
//                                    Spacer()
//                                    
//                                    VStack(alignment: .center) {
//                                        Text(yarn.name!)
//                                            .foregroundStyle(Color.primary)
//                                            .bold()
//                                        
//                                        Text(yarn.dyer!)
//                                            .foregroundStyle(Color(UIColor.secondaryLabel))
//                                            .font(.caption)
//                                            .bold()
//                                        
//                                        ForEach(yarn.weightAndYardages?.allObjects as? [WeightAndYardage] ?? []) { weight in
//                                            let unit = weight.unitOfMeasure!.lowercased()
//                                            
//                                            Spacer()
//                                            
//                                            if weight.exactLength > 0 {
//                                                Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weight.exactLength)) ?? "1") \(unit)")
//                                                    .font(.title3)
//                                                    .foregroundStyle(Color.primary)
//                                            } else {
//                                                Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weight.approxLength)) ?? "1") \(unit)")
//                                                    .font(.title3)
//                                                    .foregroundStyle(Color.primary)
//                                            }
//                                            
//                                            Spacer()
//                                            
//                                            if weight.yardage > 0 && weight.grams > 0 {
//                                                Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weight.yardage)) ?? "") \(unit) / \(weight.grams) grams")
//                                                    .font(.caption)
//                                                    .foregroundStyle(Color(UIColor.secondaryLabel))
//                                            }
//                                        }
//                                        
//                                        Spacer()
//                                    }
//                                    
//                                    Spacer()
//                                }
//                                .containerRelativeFrame(.horizontal)
//                                .scrollTransition(.animated, axis: .horizontal) { content, phase in
//                                    content
//                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
//                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
//                                }
//                                .overlay(
//                                    Button(action: {
//                                        if favoriteIndex != nil {
//                                            managedObjectContext.delete(favoriteYarns[favoriteIndex!])
//                                        } else {
//                                            let newFavorite = FavoriteYarnForPattern(context: managedObjectContext)
//                                            newFavorite.yarnId = yarn.id
//                                            newFavorite.weightAndYardageId = weightAndYardage.id
//                                        }
//                                        
//                                        PersistenceController.shared.save()
//                                        
//                                    }) {
//                                        Label("", systemImage : favoriteIndex != nil ? "heart.fill" : "heart")
//                                            .font(.title3)
//                                            .foregroundStyle(Color(UIColor.systemPink))
//                                            .contentTransition(.symbolEffect(.replace))
//                                    },
//                                    alignment: .topTrailing
//                                    
//                                )
//                            }
//                        }
//                    }
//                    .scrollTargetBehavior(.paging)
//                    .scrollIndicators(.hidden)
//                    .scrollDisabled(matchingYarn.count <= 1)
//                }
//            }
//        }
    }
}
