//
//  ViewLengthAndYardage.swift
//  WoolWallet
//
//  Created by Mac on 11/2/24.
//

import Foundation
import SwiftUI

struct ViewLengthAndYardage:  View {
    @ObservedObject var weightAndYardage: WeightAndYardage
    
    var isExact : Bool {
        return weightAndYardage.hasBeenWeighed == 1 || weightAndYardage.hasExactLength == 1
    }
    
    var body: some View {
        let unit = weightAndYardage.unitOfMeasure!.lowercased()
        
        
        if weightAndYardage.currentLength > 0 {
            Text("\(weightAndYardage.isExact ? "" : "~")\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.currentLength)) ?? "1") \(unit)")
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
