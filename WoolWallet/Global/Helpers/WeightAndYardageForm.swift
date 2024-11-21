//
//  WeightAndYardageForm.swift
//  WoolWallet
//
//  Created by Mac on 10/11/24.
//

import Foundation
import SwiftUI
import CoreData

enum WeightAndYardageParent : String, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case pattern = "Pattern"
    case yarn = "Yarn"
}

struct WeightAndYardageData {
    var id                : UUID = UUID()
    var weight            : Weight = Weight.none
    var unitOfMeasure     : UnitOfMeasure = UnitOfMeasure.yards
    var yardage           : Double? = nil
    var grams             : Int? = nil
    var hasBeenWeighed    : Int = 0
    var totalGrams        : Double? = nil
    var skeins            : Double = 0
    var hasPartialSkein   : Bool = false
    var length            : Double? = nil
    var parent            : WeightAndYardageParent = WeightAndYardageParent.yarn
    var hasExactLength    : Int = -1
    var existingItem      : WeightAndYardage? = nil
    
    func hasBeenEdited() -> Bool {
        return weight != Weight.none
        || unitOfMeasure != UnitOfMeasure.yards
        || yardage != nil
        || grams != nil
        || hasBeenWeighed != 0
        || totalGrams != nil
        || skeins != 1
        || hasPartialSkein != false
        || length != nil
        || hasExactLength != -1
    }
}

struct WeightAndYardageForm: View {
    @Binding var weightAndYardage: WeightAndYardageData
    var isSockSet : Bool = false
    var order : Int = 0
    var totalCount : Int
    var addAction: () -> Void
    var removeAction: () -> Void
    
    var isYarn : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.yarn
    }
    
    var isPattern : Bool {
        return weightAndYardage.parent == WeightAndYardageParent.pattern
    }
    
    // Computed property to get unique dyers
    var prefix: String {
        if isYarn {
            if isSockSet {
                switch order {
                case 0: return "Main Skein Weight and Yardage"
                case 1: return totalCount > 2 ? "Mini #1 Yardage" : "Mini Skein Yardage"
                case 2: return "Mini #2 Yardage"
                default: return ""
                }
            } else {
                return "Weight and Yardage"
            }
        } else {
            if totalCount > 1 {
                return "Color \(order + 1) Weight and Yardage"
            } else {
                return "Recommended Weight and Yardage"
            }
        }
    }
    
    var body: some View {
        if totalCount > 1  {
            VStack {
                Divider()
                
                HStack {
                    Text(getName()).bold().font(.title)
                    
                    Spacer()
                    
                    // can remove any for pattern and only second mini for yarn
                    if isPattern || (isYarn && order == 2) {
                        Button {
                            withAnimation {
                                removeAction()
                            }
                        } label: {
                            Label("", systemImage : "xmark.circle")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .transition(.slide)
            .customFormSection()
        }
        
        Section(
            header: Text(prefix),
            footer : weightAndYardage.yardage != nil && weightAndYardage.grams != nil
            ? Text("\(String(format: "%g", weightAndYardage.yardage!)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) / \(weightAndYardage.grams!) grams")
            : Text("")
        ) {
            if (order == 0 && isYarn) || isPattern {
                Picker("Weight", selection: $weightAndYardage.weight) {
                    ForEach(Weight.allCases, id: \.id) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Picker("Unit of Measure", selection: $weightAndYardage.unitOfMeasure) {
                ForEach(UnitOfMeasure.allCases, id: \.id) { unitOfMeasure in
                    Text(unitOfMeasure.rawValue).tag(unitOfMeasure)
                }
            }
            .onChange(of: weightAndYardage.unitOfMeasure) {
                let yardsToMeters = 0.9144
                
                if (weightAndYardage.unitOfMeasure == UnitOfMeasure.meters) {
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.yardage = Double(String(format : "%.2f", yardsToMeters * weightAndYardage.yardage!))!
                    }
                    
                    if weightAndYardage.hasExactLength == 1 && weightAndYardage.length != nil {
                        weightAndYardage.length = Double(String(format : "%.2f", yardsToMeters * weightAndYardage.length!))!
                    }
                } else {
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.yardage = Double(String(format : "%.2f", weightAndYardage.yardage! / yardsToMeters))!
                    }
                    
                    if weightAndYardage.hasExactLength == 1 && weightAndYardage.length != nil {
                        weightAndYardage.length = Double(String(format : "%.2f", weightAndYardage.length! / yardsToMeters))!
                    }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField(
                weightAndYardage.unitOfMeasure == UnitOfMeasure.yards ? "Yards" : "Meters",
                value: $weightAndYardage.yardage,
                format: .number
            )
            .keyboardType(.decimalPad)
            .onChange(of: weightAndYardage.yardage) {
                if weightAndYardage.yardage != nil {
                    weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                }
            }
            
            TextField("Grams", value: $weightAndYardage.grams, format: .number)
                .keyboardType(.numberPad)
                .onChange(of: weightAndYardage.grams) {
                    if weightAndYardage.grams != nil && weightAndYardage.totalGrams != nil {
                        weightAndYardage.skeins = Double(weightAndYardage.totalGrams!)/Double(weightAndYardage.grams!)
                    }
                }
        }
        
        if isPattern {
            Section(
                header: Text("Do you know how many \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) you need?"),
                footer : order == totalCount - 1
                ? AnyView(HStack {
                    if weightAndYardage.length != nil {
                        Text("\(String(format: "%g", weightAndYardage.length!)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    }
                    
                    Spacer()
                    Button {
                        withAnimation {
                            addAction()
                        }
                    } label: {
                        Text("Need more yarn?")
                    }
                    
                }.transition(.moveAndFade))
                : AnyView(Text(""))
            ) {
                Picker("", selection: $weightAndYardage.hasExactLength.animation()) {
                    Text("Yes").tag(1)
                    Text("No").tag(0)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: weightAndYardage.hasExactLength) {
                    weightAndYardage.skeins = 1
                    weightAndYardage.length = nil
                }
                
                if weightAndYardage.hasExactLength == 1 {
                    TextField(
                        "Length Needed (in \(weightAndYardage.unitOfMeasure.rawValue.lowercased()))",
                        value: $weightAndYardage.length,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .transition(.slide)
                } else if weightAndYardage.hasExactLength == 0 {
                    Stepper("Skeins: \(String(format: "%g", weightAndYardage.skeins))", value: $weightAndYardage.skeins, in: 1...50)
                        .onChange(of: weightAndYardage.skeins) {
                            if weightAndYardage.yardage != nil {
                                weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                            }
                        }
                    
                    if weightAndYardage.length != nil {
                        HStack {
                            Text("Estimated Length Needed")
                            Spacer()
                            Text("~\(weightAndYardage.length!.formatted) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                        }
                    }
                }
            }
        }
        
        if isYarn {
            Section(
                header :
                    Text("Have you weighed \(isSockSet ? (order == 0 ? "the main skein" : (order == 1 ? (totalCount > 2 ? "the first mini" : "the mini") : "the second mini")) : "this yarn")?"),
                footer : isSockSet && order == 1 && totalCount < 3
                ? AnyView(HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            addAction()
                        }
                    } label: {
                        Text("Have another mini?")
                    }
                    
                }.transition(.moveAndFade))
                : AnyView(Text(""))
            ) {
                Picker("", selection: $weightAndYardage.hasBeenWeighed.animation()) {
                    Text("Yes").tag(1)
                    Text("No").tag(0)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: weightAndYardage.hasBeenWeighed) {
                    weightAndYardage.skeins = 1
                    weightAndYardage.hasPartialSkein = false
                    weightAndYardage.totalGrams = nil
                    
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                    } else {
                        weightAndYardage.length = nil
                    }
                }
                
                if weightAndYardage.hasBeenWeighed == 1 {
                    TextField("Total Grams", value: $weightAndYardage.totalGrams, format: .number)
                        .keyboardType(.decimalPad)
                        .onChange(of: weightAndYardage.totalGrams) {
                            if weightAndYardage.totalGrams != nil && weightAndYardage.grams != nil {
                                withAnimation {
                                    weightAndYardage.skeins = Double(weightAndYardage.totalGrams!)/Double(weightAndYardage.grams!)
                                }
                                
                                if weightAndYardage.yardage != nil {
                                    withAnimation {
                                        weightAndYardage.length = (weightAndYardage.yardage! * Double(weightAndYardage.totalGrams!)) / Double(weightAndYardage.grams!)
                                    }
                                }
                            }
                        }
                        .transition(.slide)
                    
                    if weightAndYardage.length != nil && weightAndYardage.totalGrams != nil {
                        HStack {
                            Text("Length")
                            
                            Spacer()
                            
                            Text("\(weightAndYardage.length!.formatted) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                        }
                        .transition(.slide)
                    }
                    
                    if weightAndYardage.skeins != 0 {
                        HStack {
                            Text("Skeins")
                            Spacer()
                            Text(weightAndYardage.skeins.formatted)
                        }
                        .transition(.slide)
                    }
                } else if weightAndYardage.hasBeenWeighed == 0 {
                    Stepper("Skeins: \(String(format: "%g", weightAndYardage.skeins))", value: $weightAndYardage.skeins, in: 0...50)
                        .onChange(of: weightAndYardage.skeins) {
                            if weightAndYardage.yardage != nil {
                                weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                            }
                        }
                        .onAppear {
                            if weightAndYardage.yardage != nil {
                                weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                            }
                        }
                    
                    Toggle("Partial Skein", isOn: $weightAndYardage.hasPartialSkein)
                    
                    if weightAndYardage.length != nil {
                        HStack {
                            Text("Length Estimate")
                            Spacer()
                            Text("~\(weightAndYardage.length!.formatted) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                        }
                    }
                }
            }
        }
    }
    
    private func getName() -> String {
        if isYarn {
            if isSockSet {
                switch order {
                case 0: return "Main Skein"
                case 1: return totalCount > 2 ? "Mini #1" : "Mini"
                case 2: return "Mini #2"
                default: return ""
                }
            }
        } else if totalCount > 1 {
            return "Color \(PatternUtils.shared.getLetter(for: order))"
        }
        
        return ""
    }
}
