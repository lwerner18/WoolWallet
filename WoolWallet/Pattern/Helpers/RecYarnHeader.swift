//
//  RecYarnHeader.swift
//  WoolWallet
//
//  Created by Mac on 10/16/24.
//

import Foundation
import SwiftUI

struct RecYarnHeader: View {
    var count : Int
    var index : Int
    var weightAndYardage : WeightAndYardageData
    
    var body: some View {
        HStack {
            Text(count == 1 ? "Recommended Yarn" : "Color \(PatternUtils.shared.getLetter(for: index))")
                .bold()
                .foregroundStyle(Color.primary)
            
            if weightAndYardage.length != nil && weightAndYardage.length! > 0 {
                Spacer()
                
                Text("\(weightAndYardage.hasExactLength == 1 ? "" : "~")\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.length!)) ?? "1") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    .foregroundStyle(Color(UIColor.secondaryLabel))
            }
        }
    }
}
