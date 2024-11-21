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
            Text("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.currentLength.formatted) \(unit)")
                .font(.title3)
                .foregroundStyle(Color.primary)
        }
        
        if weightAndYardage.availableLength > 0 {
            Spacer()
            
            Text("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.availableLength.formatted) \(unit) available")
                .font(.subheadline)
                .foregroundStyle(Color.primary)
        }
        
        Spacer()
        
        if weightAndYardage.yardage > 0 && weightAndYardage.grams > 0 {
            Text("\(weightAndYardage.yardage.formatted) \(unit) / \(weightAndYardage.grams) grams")
                .font(.caption)
                .foregroundStyle(Color(UIColor.secondaryLabel))
        }
    }
}
