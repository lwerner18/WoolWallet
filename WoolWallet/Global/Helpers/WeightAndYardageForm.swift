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

struct WeightAndYardageData: Equatable {
    var id                : UUID = UUID()
    var weight            : Weight = Weight.none
    var unitOfMeasure     : UnitOfMeasure = UnitOfMeasure.yards
    var yardage           : Double? = nil
    var grams             : Int? = nil
    var hasBeenWeighed    : Int = 0
    var totalGrams        : Double? = nil
    var skeins            : Double = 1
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
    
    private var canRemove: Bool {
        isPattern || (isYarn && order == 2)
    }
    
    /// Short section titles that match the yarn details page
    private var sectionTitle: String {
        if isYarn {
            if isSockSet {
                switch order {
                case 0: return "Main Skein"
                case 1: return totalCount > 2 ? "Mini #1" : "Mini Skein"
                case 2: return "Mini #2"
                default: return "Skein"
                }
            }
            return "Amount"
        }
        
        if totalCount > 1 {
            return "Color \(PatternUtils.shared.getLetter(for: order))"
        }
        
        return "Recommended Yarn"
    }
    
    private var skeinNoun: String {
        guard isYarn, isSockSet else { return "this yarn" }
        
        switch order {
        case 0: return "the main skein"
        case 1: return totalCount > 2 ? "the first mini" : "the mini"
        default: return "the second mini"
        }
    }
    
    private var yardageSummary: String? {
        guard let yardage = weightAndYardage.yardage, let grams = weightAndYardage.grams else { return nil }
        return "\(String(format: "%g", yardage)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) / \(grams) grams"
    }
    
    var body: some View {
        if totalCount > 1 && isPattern {
            patternColorHeader
        }
        
        Section {
            if (order == 0 && isYarn) || isPattern {
                Picker("Weight", selection: $weightAndYardage.weight) {
                    ForEach(Weight.allCases, id: \.id) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Picker("Units", selection: $weightAndYardage.unitOfMeasure) {
                ForEach(UnitOfMeasure.allCases, id: \.id) { unitOfMeasure in
                    Text(unitOfMeasure.rawValue).tag(unitOfMeasure)
                }
            }
            .onChange(of: weightAndYardage.unitOfMeasure) {
                let yardsToMeters = 0.9144
                
                if weightAndYardage.unitOfMeasure == UnitOfMeasure.meters {
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
            .pickerStyle(.segmented)
            .padding(.vertical, 2)
            
            TextField(
                weightAndYardage.unitOfMeasure == UnitOfMeasure.yards ? "Yards per skein" : "Meters per skein",
                value: $weightAndYardage.yardage,
                format: .number
            )
            .keyboardType(.decimalPad)
            .onChange(of: weightAndYardage.yardage) {
                if weightAndYardage.yardage != nil {
                    weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                }
            }
            
            TextField("Grams per skein", value: $weightAndYardage.grams, format: .number)
                .keyboardType(.numberPad)
                .onChange(of: weightAndYardage.grams) {
                    if weightAndYardage.grams != nil && weightAndYardage.totalGrams != nil {
                        weightAndYardage.skeins = Double(weightAndYardage.totalGrams!)/Double(weightAndYardage.grams!)
                    }
                }
        } header: {
            sectionHeader
        } footer: {
            if let yardageSummary {
                Text(yardageSummary)
            } else if isYarn && order == 0 {
                Text("From the ball band — weight, put-up, and fiber weight.")
            }
        }
        
        if isPattern {
            patternLengthSection
        }
        
        if isYarn {
            yarnAmountSection
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text(sectionTitle)
            
            Spacer()
            
            if canRemove && isYarn {
                Button(role: .destructive) {
                    withAnimation {
                        removeAction()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
                .accessibilityLabel("Remove \(sectionTitle)")
            }
        }
    }
    
    private var patternColorHeader: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Text(sectionTitle)
                    .font(.title3.bold())
                
                Spacer()
                
                if canRemove {
                    Button {
                        withAnimation {
                            removeAction()
                        }
                    } label: {
                        Label("Remove", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(Color.red)
                    }
                    .accessibilityLabel("Remove")
                }
            }
        }
        .transition(.slide)
        .customFormSection()
    }
    
    private var patternLengthSection: some View {
        Section {
            Picker("Know the length needed?", selection: $weightAndYardage.hasExactLength.animation()) {
                Text("Yes").tag(1)
                Text("No").tag(0)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: weightAndYardage.hasExactLength) {
                weightAndYardage.skeins = 1
                weightAndYardage.length = nil
            }
            .padding(.vertical, 2)
            
            if weightAndYardage.hasExactLength == 1 {
                TextField(
                    "Length needed (\(weightAndYardage.unitOfMeasure.rawValue.lowercased()))",
                    value: $weightAndYardage.length,
                    format: .number
                )
                .keyboardType(.decimalPad)
                .transition(.slide)
            } else if weightAndYardage.hasExactLength == 0 {
                Stepper(
                    "Skeins: \(String(format: "%g", weightAndYardage.skeins))",
                    value: $weightAndYardage.skeins,
                    in: 1...50
                )
                .onChange(of: weightAndYardage.skeins) {
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.length = weightAndYardage.yardage! * weightAndYardage.skeins
                    }
                }
                
                if weightAndYardage.length != nil {
                    HStack {
                        Text("Estimated length")
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("~\(weightAndYardage.length!.formatted) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    }
                }
            }
        } header: {
            Text("Length Needed")
        } footer: {
            if order == totalCount - 1 {
                HStack {
                    if let length = weightAndYardage.length {
                        Text("\(String(format: "%g", length)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            addAction()
                        }
                    } label: {
                        Text("Need another color?")
                    }
                }
                .transition(.moveAndFade)
            }
        }
    }
    
    private var yarnAmountSection: some View {
        Section {
            Picker("", selection: $weightAndYardage.hasBeenWeighed.animation()) {
                Text("Yes").tag(1)
                Text("No").tag(0)
            }
            .pickerStyle(.segmented)
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
            .padding(.vertical, 2)
            
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
                Stepper(
                    "Skeins: \(String(format: "%g", weightAndYardage.skeins))",
                    value: $weightAndYardage.skeins,
                    in: 0...50
                )
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
        } header: {
            Text("Have you weighed \(skeinNoun)?")
        } footer: {
            if isSockSet && order == 1 && totalCount < 3 {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            addAction()
                        }
                    } label: {
                        Text("Have another mini?")
                    }
                }
                .transition(.moveAndFade)
            }
        }
    }
}
