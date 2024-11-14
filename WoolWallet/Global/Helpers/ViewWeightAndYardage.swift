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
            return GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.yardage)) ?? ""
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
    
    var usedLength : Double {
        return weightAndYardage.currentLength - weightAndYardage.availableLength
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
                showAvailableLength && usedLength > 0 ?
                AnyView(HStack {
                    Label("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: usedLength)) ?? "0") \(weightAndYardage.unitOfMeasure!.lowercased()) of this yarn is currently being used in projects ", systemImage : "info.circle")
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
                }
                
                if formattedYardage != "" && weightAndYardage.grams > 0 {
                    if isPattern {
                        Divider()
                    }
                    
                    HStack {
                        Spacer()
                        
                        Text("\(formattedYardage) \(weightAndYardage.unitOfMeasure!.lowercased()) / \(weightAndYardage.grams) grams")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                    }
                    .yarnDataRow()
                }
                
                if weightAndYardage.totalGrams > 0 {
                    if formattedYardage != "" && weightAndYardage.grams > 0  {
                        Divider()
                    }
                    
                    HStack {
                        Text("Total Grams").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.totalGrams)) ?? "1")")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if weightAndYardage.unitOfMeasure != nil {
                    Divider()
                    
                    HStack {
                        Text("\(weightAndYardage.isExact ? "" : "Estimated ")Length\(isPattern ? " Needed" : "")").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(weightAndYardage.isExact ? "" : "~")\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.currentLength)) ?? "1") \(weightAndYardage.unitOfMeasure!.lowercased())")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                
                if showAvailableLength {
                    Divider()
                    
                    HStack {
                        Text("Available Length").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(weightAndYardage.isExact ? "" : "~")\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.availableLength)) ?? "1") \(weightAndYardage.unitOfMeasure!.lowercased())")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if isYarn || (isPattern && weightAndYardage.currentLength == 0) {
                    Divider()
                    
                    HStack {
                        Text("Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.currentSkeins)) ?? "1")")
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

