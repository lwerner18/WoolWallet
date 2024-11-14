//
//  WeightAndYardageUtils.swift
//  WoolWallet
//
//  Created by Mac on 10/25/24.
//

import Foundation
import CoreData

class WeightAndYardageUtils {
    static let shared = WeightAndYardageUtils()
    
    private init() {}
    
    func doesNotMatch(favorite faveWandY: WeightAndYardage, second wAndY: WeightAndYardage) -> Bool {
        if faveWandY.weight != wAndY.weight {
            return true
        }
        
        if faveWandY.currentLength > wAndY.currentLength {
            return true
        }
        
        var ratio1 = 0.0
        var ratio2 = 0.0
        
        let allowedDeviation = 0.15
        
        if faveWandY.yardage > 0 && faveWandY.grams > 0 {
            ratio1 = faveWandY.yardage / Double(faveWandY.grams)
        }
        
        if wAndY.yardage > 0 && wAndY.grams > 0 {
            ratio2 = wAndY.yardage / Double(wAndY.grams)
        }
        
        if ratio1 - ratio2 > allowedDeviation {
            return true
        }
        
        return false
    }
}
