//
//  ViewWeightAndYardage.swift
//  WoolWallet
//
//  Created by Mac on 9/28/24.
//

import Foundation
import SwiftUI

struct ViewWeightAndYardage: View {
    var weightAndYardage : WeightAndYardage
    
    // Computed property to format length to two decimal places if number is a fraction
    var formattedLength: String {
        if weightAndYardage.length != nil {
            return GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.length!)) ?? ""
        }
        
        return ""
    }
    
    var body: some View {
        InfoCard() {
            VStack {
                if formattedLength != "" && weightAndYardage.grams != nil {
                    HStack {
                        Spacer()
                        
                        Text("\(formattedLength) \(weightAndYardage.unitOfMeasure.rawValue) / \(weightAndYardage.grams!) grams").font(.headline).bold()
                        
                        Spacer()
                        
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                if weightAndYardage.totalGrams != nil {
                    HStack {
                        Text("Total Grams").foregroundStyle(Color.gray)
                        Spacer()
                        Text("\(weightAndYardage.totalGrams!)").font(.headline).bold()
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                if weightAndYardage.exactLength > 0 {
                    HStack {
                        Text("Length").foregroundStyle(Color.gray)
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.exactLength)) ?? "1") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())").font(.headline).bold()
                    }
                    .yarnDataRow()
                    
                    Divider()
                } else if weightAndYardage.approximateLength > 0 {
                    HStack {
                        Text("Length Estimate").foregroundStyle(Color.gray)
                        Spacer()
                        Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.approximateLength)) ?? "1") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())").font(.headline).bold()
                    }
                    .yarnDataRow()
                    
                    Divider()
                }
                
                HStack {
                    Text("Skeins").foregroundStyle(Color.gray)
                    Spacer()
                    Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.skeins)) ?? "1")").font(.headline).bold()
                }
                .yarnDataRow()
           
                
                if weightAndYardage.hasPartialSkein {
                    Divider()
                    
                    HStack {
                        Spacer()
                        Label("Partial skein", systemImage : "divide").font(.headline)
                        Spacer()
                    }
                    .yarnDataRow()
                }
            }
        }
    }
}
