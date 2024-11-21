//
//  YarnPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/8/24.
//

import Foundation
import SwiftUI
import CoreData

struct YarnPreview: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var yarnWandY : WeightAndYardage
    
    var body: some View {
        HStack {
            YarnPreviewPart1(yarnWandY: yarnWandY)
            
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

struct YarnPreviewForProject: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var yarnWandY : WeightAndYardage
    @ObservedObject var projectPairing : ProjectPairing
    @ObservedObject var project : Project
    
    public init(yarnWandY: WeightAndYardage, projectPairing : ProjectPairing, project : Project) {
        self.yarnWandY = yarnWandY
        self.projectPairing = projectPairing
        self.project = project
    }
    
    var isExact : Bool {
        return yarnWandY.hasBeenWeighed == 1 || yarnWandY.hasExactLength == 1
    }
    
    var body: some View {
        HStack {
            YarnPreviewPart1(yarnWandY: yarnWandY)
            
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
                
                let unit = yarnWandY.unitOfMeasure!.lowercased()
                
                let length = project.complete ? projectPairing.lengthUsed : projectPairing.patternWeightAndYardage?.currentLength ?? 0
                let verb = project.inProgress ? "Using" : project.complete ? "Used" : "Requires"
                
                Text("\(verb) \(length.formatted) \(unit)")
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                if yarnWandY.yardage > 0 && yarnWandY.grams > 0 {
                    Text("\(yarnWandY.yardage.formatted) \(unit) / \(yarnWandY.grams) grams")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            
            Spacer()
        }
    }
}

struct YarnPreviewPart1: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var yarnWandY : WeightAndYardage
    
    public init(yarnWandY: WeightAndYardage) {
        self.yarnWandY = yarnWandY
    }
    
    var body: some View {
        HStack {
            VStack {
                ImageCarousel(images: .constant(yarnWandY.yarn!.uiImages), size: Size.extraSmall)
                
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
        }
    }
}

