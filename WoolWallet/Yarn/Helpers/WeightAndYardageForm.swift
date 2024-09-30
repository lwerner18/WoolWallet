//
//  WeightAndYardageForm.swift
//  WoolWallet
//
//  Created by Mac on 9/28/24.
//

import Foundation
import SwiftUI

struct WeightAndYardage {
    var weight            : Weight = Weight.none
    var unitOfMeasure     : UnitOfMeasure = UnitOfMeasure.yards
    var length            : Double? = nil
    var grams             : Int? = nil
    var hasBeenWeighed    : Int = -1
    var totalGrams        : Int? = nil
    var skeins            : Double = 1
    var hasPartialSkein   : Bool = false
    var exactLength       : Double = 0
    var approximateLength : Double = 0
}

struct WeightAndYardageForm: View {
    @Binding var weightAndYardage: WeightAndYardage
    var isSockSet : Bool = false
    var skeinIndex : Int = 0
    @Binding var hasTwoMinis : Bool
    
    var body: some View {
        Section(
            header: Text("\(isSockSet ? (skeinIndex == 0 ? "Main Skein Weight and Yardage" : (skeinIndex == 1 ? (hasTwoMinis ? "Mini #1 Yardage" : "Mini Skein Yardage") : "Mini #2 Yardage")) : "Weight and Yardage")"),
            footer : weightAndYardage.length != nil && weightAndYardage.grams != nil
            ? Text("\(String(format: "%g", weightAndYardage.length!)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) / \(weightAndYardage.grams!) grams")
            : Text("")
        ) {
            
            if skeinIndex == 0 {
                Picker("Weight", selection: $weightAndYardage.weight) {
                    ForEach(0..<weights.count, id: \.self) { index in
                        Text(weights[index].rawValue).tag(weights[index])
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Picker("Unit of Measure", selection: $weightAndYardage.unitOfMeasure) {
                ForEach(0..<unitsOfMeasure.count) { index in
                    Text(unitsOfMeasure[index].rawValue).tag(unitsOfMeasure[index])
                }
            }
            .onChange(of: weightAndYardage.unitOfMeasure) {
                let yardsToMeters = 0.9144
                if weightAndYardage.length != nil {
                    if (weightAndYardage.unitOfMeasure == UnitOfMeasure.meters) {
                        weightAndYardage.length = Double(String(format : "%.2f", yardsToMeters * weightAndYardage.length!))!
                    } else {
                        weightAndYardage.length = Double(String(format : "%.2f", weightAndYardage.length! / yardsToMeters))!
                    }
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField(weightAndYardage.unitOfMeasure == UnitOfMeasure.yards ? "Yards" : "Meters", value: $weightAndYardage.length, format: .number)
                .keyboardType(.decimalPad)
            
            TextField("Grams", value: $weightAndYardage.grams, format: .number)
                .keyboardType(.numberPad)
                .onChange(of: weightAndYardage.grams) {
                    if weightAndYardage.grams != nil && weightAndYardage.totalGrams != nil {
                        weightAndYardage.skeins = Double(weightAndYardage.totalGrams!)/Double(weightAndYardage.grams!)
                    }
                }
        }
        
        Section(
            header :
                Text("Have you weighed \(isSockSet ? (skeinIndex == 0 ? "the main skein" : (skeinIndex == 1 ? (hasTwoMinis ? "the first mini" : "the mini") : "the second mini")) : "this yarn")?"),
            footer : isSockSet && skeinIndex == 1 && !hasTwoMinis
                ? AnyView(HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                hasTwoMinis = true
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
                if weightAndYardage.hasBeenWeighed == 0 {
                    weightAndYardage.skeins = 1
                    weightAndYardage.hasPartialSkein = false
                } else if weightAndYardage.hasBeenWeighed == 1 {
                    weightAndYardage.totalGrams = nil
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
                            
                            if weightAndYardage.length != nil {
                                withAnimation {
                                    weightAndYardage.exactLength = (weightAndYardage.length! * Double(weightAndYardage.totalGrams!)) / Double(weightAndYardage.grams!)
                                }
                            }
                        }
                    }
                    .transition(.slide)
                
                if weightAndYardage.exactLength > 0 && weightAndYardage.totalGrams != nil {
                    HStack {
                        Text("Length")
                        
                        Spacer()
                        
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.exactLength)) ?? "0") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    }
                    .transition(.slide)
                }
                
                if weightAndYardage.skeins != nil {
                    HStack {
                        Text("Skeins")
                        Spacer()
                        Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.skeins)) ?? "1")")
                    }
                    .transition(.slide)
                }
            } else if weightAndYardage.hasBeenWeighed == 0 {
                Stepper("Skeins: \(String(format: "%g", weightAndYardage.skeins))", value: $weightAndYardage.skeins, in: 1...50)
                
                Toggle("Partial Skein", isOn: $weightAndYardage.hasPartialSkein)
                
                if weightAndYardage.length != nil {
                    HStack {
                        Text("Length Estimate")
                        Spacer()
                        Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.length! * weightAndYardage.skeins)) ?? "0") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    }
                }
            }
        }
    }
}
