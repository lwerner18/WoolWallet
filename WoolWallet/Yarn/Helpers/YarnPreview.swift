//
//  YarnPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/8/24.
//

import Foundation
import SwiftUI

struct YarnPreview: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var yarnWandY : WeightAndYardage
    
    var body: some View {
        HStack {
            VStack {
                ImageCarousel(images: .constant(yarnWandY.yarn!.uiImages), smallMode: true)
                    .xsImageCarousel()
                
                if yarnWandY.yarn!.isSockSet {
                    Text("Sock Set")
                        .font(.caption)
                    
                    ZStack {
                        switch yarnWandY.order {
                        case 0: Text("Main Skein")
                        case 1: Text("Mini Skein")
                        case 2: Text("Mini #2")
                        default: EmptyView()
                        }
                    }
                    .font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                Text(yarnWandY.yarn!.name!)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.primary)
                    .bold()
                
                Text(yarnWandY.yarn!.dyer!)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.caption)
                    .bold()
                
                Spacer()
                
                ViewLengthAndYardage(weightAndYardage: yarnWandY)
            }
            
            Spacer()
        }
    }
}
