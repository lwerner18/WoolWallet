//
//  PostCompleteForm.swift
//  WoolWallet
//
//  Created by Mac on 11/11/24.
//

import Foundation
import SwiftUI

struct PostCompleteForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var project : Project
    
    @State private var animateCheckmark = false
    @State private var provideRemainingWeight : [Bool] = []
    @State private var remainingWeights : [Double?] = []
    
    init(
        project: Project
    ) {
        self.project = project
        
        _provideRemainingWeight = State(initialValue: project.projectPairingItems.map { pairing in
            return false
        })
        
        _remainingWeights = State(initialValue: project.projectPairingItems.map { pairing in
            return nil
        })
    }
    
    var body: some View {
        Form {
            VStack {
                Label("", systemImage: "hands.clap")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#008000")) // Set text color
                    .symbolEffect(.bounce, value: animateCheckmark)
                    .padding()
                
                Text("Congrats!")
                    .font(.title2)
                    .foregroundStyle(Color.primary)
                    .padding()
                
                Spacer()
                
                Text("Now that you're done, let's take care of some housekeeping.")
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.caption)
            }
            .onAppear {
                animateCheckmark.toggle()
            }
            .customFormSection()
            
            ForEach($provideRemainingWeight.indices, id: \.self) { index in
                let patternWAndY = project.projectPairingItems[index].patternWeightAndYardage
                
                let text = "COLOR \(PatternUtils.shared.getLetter(for: Int(patternWAndY.order)))"
                
                let provideWeight = provideRemainingWeight[index]
                
                Section(
                    header : Text(project.projectPairingItems.count > 1 ? text : "Yarn"),
                    footer : provideWeight && remainingWeights[index] != nil
                    ? AnyView(Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: remainingWeights[index]!)) ?? "0") grams"))
                    : AnyView(EmptyView())
                ) {
                    Toggle("Provide Remaining Weight", isOn: $provideRemainingWeight[index])
                    
                    if provideWeight {
                        TextField("Remaining Grams", value: $remainingWeights[index], format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            
            HStack {
                Spacer()
                
                Button {
                    // pairings
                    let pairings: [ProjectPairing] = project.projectPairingItems.enumerated().map { (index, element) in
                        let pairing = ProjectPairing.from(data: element, context: managedObjectContext)
                        let yarnWAndY : WeightAndYardage = pairing.yarnWeightAndYardage!
                        
                        if provideRemainingWeight[index] && remainingWeights[index] != nil {
                            let remainingWeight : Double = remainingWeights[index]!
                            let previousLength = yarnWAndY.currentLength
                            
                            if yarnWAndY.grams > 0 {
                                yarnWAndY.currentSkeins = Double(remainingWeight)/Double(yarnWAndY.grams)
                                
                              
                                
                                if yarnWAndY.yardage > 0 {
                                    yarnWAndY.currentLength = (yarnWAndY.yardage * Double(remainingWeight)) / Double(yarnWAndY.grams)
                                }
                            }
                            
                            pairing.lengthUsed = previousLength - yarnWAndY.currentLength
                        } else {
                            pairing.lengthUsed = pairing.patternWeightAndYardage!.currentLength
                            
                            if yarnWAndY.currentLength > 0 {
                                yarnWAndY.currentLength = yarnWAndY.currentLength - pairing.lengthUsed
                                
                                if yarnWAndY.currentSkeins > 0 && yarnWAndY.yardage > 0 {
                                    yarnWAndY.currentSkeins = yarnWAndY.currentLength / yarnWAndY.yardage
                                }
                            }
                        }
                        
                        if yarnWAndY.currentSkeins < 0 {
                            yarnWAndY.currentSkeins = 0
                        }
                        
                        if yarnWAndY.currentLength < 0 {
                            yarnWAndY.currentLength = 0
                            yarnWAndY.yarn?.isArchived = true
                        }
                        
                        return pairing
                    }
                    
                    project.pairings = NSSet(array: pairings)
                    
                    
                    PersistenceController.shared.save()
                    
                    dismiss()
                } label: {
                    Text("Done")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Spacer()
            }
            .customFormSection()
        }
    }
}
