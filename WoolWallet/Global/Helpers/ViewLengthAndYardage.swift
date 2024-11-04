//
//  ViewLengthAndYardage.swift
//  WoolWallet
//
//  Created by Mac on 11/2/24.
//

import Foundation
import SwiftUI

struct ViewLengthAndYardage:  View {
    var weightAndYardage: WeightAndYardage
    
    var body: some View {
        let unit = weightAndYardage.unitOfMeasure!.lowercased()
        
        
        if weightAndYardage.exactLength > 0 {
            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.exactLength)) ?? "1") \(unit)")
                .font(.title3)
                .foregroundStyle(Color.primary)
        } else {
            Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.approxLength)) ?? "1") \(unit)")
                .font(.title3)
                .foregroundStyle(Color.primary)
        }
        
        Spacer()
        
        if weightAndYardage.yardage > 0 && weightAndYardage.grams > 0 {
            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.yardage)) ?? "") \(unit) / \(weightAndYardage.grams) grams")
                .font(.caption)
                .foregroundStyle(Color(UIColor.secondaryLabel))
        }
    }
}
