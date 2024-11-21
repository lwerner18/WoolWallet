//
//  ViewWeightAndYardage.swift
//  WoolWallet
//
//  Created by Mac on 10/11/24.
//

import Foundation
import SwiftUI

struct ViewWeightAndYardage: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var weightAndYardage : WeightAndYardage
    var isSockSet : Bool = false
    var totalCount : Int
    var hideName : Bool = false
    var showSuggestions : Bool = true
    
    // Computed property to format length to two decimal places if number is a fraction
    var formattedYardage: String {
        if weightAndYardage.yardage != 0 {
            return weightAndYardage.yardage.formatted
        }
        
        return ""
    }
    
    var isYarn : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.yarn.rawValue
    }
    
    var isPattern : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.pattern.rawValue
    }
    
    var showAvailableLength : Bool {
        return weightAndYardage.yarnPairingItems.contains(where: {element in element.project!.inProgress})
    }
    
    var body: some View {
        if totalCount > 1 && !hideName  {
            Divider().padding()
            
            HStack {
                Text(getName()).font(.title3).bold().foregroundStyle(Color.primary)
                Spacer()
            }
        }
        
        InfoCard(
            footer : {
                showAvailableLength && weightAndYardage.yardsUsed > 0 ?
                AnyView(HStack {
                    Label("\(weightAndYardage.yardsUsed.formatted) \(weightAndYardage.unitOfMeasure!.lowercased()) of this yarn is currently being used in projects ", systemImage : "info.circle")
                        .font(.caption2)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                    
                    Spacer()
                })
                : AnyView(EmptyView())
            }
        ) {
            VStack {
                if isPattern {
                    HStack {
                        Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text(weightAndYardage.weight ?? "").font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                if formattedYardage != "" && weightAndYardage.grams > 0 {      
                    HStack {
                        Spacer()
                        
                        Text("\(formattedYardage) \(weightAndYardage.unitOfMeasure!.lowercased()) / \(weightAndYardage.grams) grams")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                if weightAndYardage.totalGrams > 0 {
                    HStack {
                        Text("Total Grams").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(weightAndYardage.totalGrams.formatted) grams")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                HStack {
                    Text("\(weightAndYardage.isExact ? "" : "Estimated ")Length\(isPattern ? " Needed" : "")").foregroundStyle(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.currentLength.formatted) \(weightAndYardage.unitOfMeasure!.lowercased())")
                        .font(.headline).bold().foregroundStyle(Color.primary)
                }
                .yarnDataRow()
                
                
                if showAvailableLength {
                    Divider()
                    
                    HStack {
                        Text("Available Length").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.availableLength.formatted) \(weightAndYardage.unitOfMeasure!.lowercased())")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if isYarn || (isPattern && weightAndYardage.currentLength == 0) {
                    Divider()
                    
                    HStack {
                        Text("Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text(weightAndYardage.currentSkeins.formatted)
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                
                if weightAndYardage.hasPartialSkein {
                    Divider()
                    
                    HStack {
                        Spacer()
                        Label("Partial skein", systemImage : "divide").font(.headline).foregroundStyle(Color.primary)
                        Spacer()
                    }
                    .yarnDataRow()
                }
                
                if isYarn {
                    
                }
            }
        }
    }
    
    private func getName() -> String {
        if isYarn {
            if isSockSet {
                switch weightAndYardage.order {
                case 0: return "Main Skein"
                case 1: return totalCount > 2 ? "Mini #1" : "Mini"
                case 2: return "Mini #2"
                default: return ""
                }
            }
        } else if totalCount > 1 {
            return "Color \(PatternUtils.shared.getLetter(for: Int(weightAndYardage.order)))"
        }
        
        return ""
    }
}

