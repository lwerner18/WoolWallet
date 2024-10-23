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
    
    var weightAndYardage : WeightAndYardageData
    var isSockSet : Bool = false
    var order : Int = 0
    var totalCount : Int
    var hideName : Bool = false
    var showSuggestions : Bool = true
    
    // Computed property to format length to two decimal places if number is a fraction
    var formattedYardage: String {
        if weightAndYardage.yardage != nil {
            return GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.yardage!)) ?? ""
        }
        
        return ""
    }
    
    var isYarn : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.yarn
    }
    
    var isPattern : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.pattern
    }
    
    var body: some View {
        if totalCount > 1 && !hideName  {
            Divider().padding()
            
            HStack {
                Text(getName()).font(.title3).bold().foregroundStyle(Color.primary)
                Spacer()
            }
        }
        
        InfoCard() {
            VStack {
                if isPattern {
                    HStack {
                        Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(weightAndYardage.weight.rawValue)").font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if formattedYardage != "" && weightAndYardage.grams != nil {
                    Divider()
                    
                    HStack {
                        Spacer()
                        
                        Text("\(formattedYardage) \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) / \(weightAndYardage.grams!) grams")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                        
                        Spacer()
                        
                    }
                    .yarnDataRow()
                }
                
                if weightAndYardage.totalGrams != nil {
                    Divider()
                    
                    HStack {
                        Text("Total Grams").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.totalGrams!)) ?? "1")")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if weightAndYardage.exactLength != nil && weightAndYardage.exactLength! > 0 {
                    Divider()
                    
                    HStack {
                        Text("Length\(isPattern ? " Needed" : "")").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.exactLength!)) ?? "1") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                            .font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                } else if weightAndYardage.approximateLength != nil && weightAndYardage.approximateLength! > 0 {
                    Divider()
                    
                    HStack {
                        Text(isPattern ? "Estimated Length Needed" : "Length Estimate").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.approximateLength!)) ?? "1") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())").font(.headline).bold().foregroundStyle(Color.primary)
                    }
                    .yarnDataRow()
                }
                
                if isYarn || (isPattern && weightAndYardage.exactLength == 0) {
                    Divider()
                    
                    HStack {
                        Text("Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.skeins)) ?? "1")")
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
            }
        }
    }
    
    private func getName() -> String {
        if isYarn {
            if isSockSet {
                switch order {
                case 0: return "Main Skein"
                case 1: return totalCount > 2 ? "Mini #1" : "Mini"
                case 2: return "Mini #2"
                default: return ""
                }
            }
        } else if totalCount > 1 {
            return "Color \(PatternUtils.shared.getLetter(for: order))"
        }
        
        return ""
    }
}

