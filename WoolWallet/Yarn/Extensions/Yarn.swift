//
//  Yarn.swift
//  WoolWallet
//
//  Created by Mac on 8/21/24.
//

import Foundation
import SwiftUI

extension Yarn {
    var colorPickerItems: [ColorPickerItem] {
        let storedColors = colors?.allObjects as? [StoredColor] ?? []
        
        return storedColors.map { storedColor in
            let color = Color(
                red: storedColor.red,
                green: storedColor.green,
                blue: storedColor.blue,
                opacity: storedColor.alpha
            )
            
            return ColorPickerItem(color: color, name: storedColor.name!)
        }
    }
    
    var compositionItems: [CompositionItem] {
        let compositions = composition?.allObjects as? [Composition] ?? []
        
        return compositions.map { composition in
            return CompositionItem(percentage: Int(composition.percentage), material: composition.material!)
        }
    }
    
    var uiImages: [UIImage] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        let sortedImages = storedImages.sorted { $0.order < $1.order}
        
        return sortedImages.map { storedImage in
            return UIImage(data: storedImage.image ?? Data())!
        }
    }
}
