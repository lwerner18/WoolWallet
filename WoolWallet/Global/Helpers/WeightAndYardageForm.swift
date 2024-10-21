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
    var hasBeenWeighed    : Int = -1
    var totalGrams        : Double? = nil
    var skeins            : Double = 1
    var hasPartialSkein   : Bool = false
    var exactLength       : Double? = nil
    var approximateLength : Double? = nil
    var parent            : WeightAndYardageParent = WeightAndYardageParent.yarn
    var hasExactLength    : Int = -1
    var existingItem      : WeightAndYardage? = nil
    
    func hasBeenEdited() -> Bool {
        return weight != Weight.none
        || unitOfMeasure != UnitOfMeasure.yards
        || yardage != nil
        || grams != nil
        || hasBeenWeighed != -1
        || totalGrams != nil
        || skeins != 1
        || hasPartialSkein != false
        || exactLength != nil
        || approximateLength != nil
        || hasExactLength != -1
    }
    
    func matchingYarns(in context: NSManagedObjectContext) -> [WeightAndYardage] {
        let fetchRequest: NSFetchRequest<WeightAndYardage> = WeightAndYardage.fetchRequest()
        
        let length = exactLength ?? approximateLength ?? 0
        let allowedDeviation = 0.15
        var ratio = 0.0
        
        print("length", length)
        
        if yardage != nil && grams != nil {
            ratio = yardage! / Double(grams!)
        }
        
        var predicates: [NSPredicate] = []
        
        // only yarn parents
        predicates.append(NSPredicate(format: "parent == %@", WeightAndYardageParent.yarn.rawValue))
        
        // weight filter
        predicates.append(NSPredicate(format: "weight == %@", weight.rawValue))
        
        // length filter
        predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "exactLength > %@", NSNumber(value: length)),
            NSPredicate(format: "approxLength > %@", NSNumber(value: length))
        ]))
        
        // ratio filter
        if ratio > 0.0 {
            predicates.append(
                NSPredicate(
                    format: "grams > 0 AND (yardage / grams >= %@) AND (yardage / grams <= %@)",
                    NSNumber(value: ratio - allowedDeviation),
                    NSNumber(value: ratio + allowedDeviation)
                )
            )
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        do {
            let result = try context.fetch(fetchRequest)
            
            print(result.first?.weight)
            print(result.first?.parent)
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch matching yarns: \(error)")
            return []
        }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .background(Color(UIColor.systemGroupedBackground))
        }
        
        Section(
            header: Text(prefix),
            footer : weightAndYardage.yardage != nil && weightAndYardage.grams != nil
            ? Text("\(String(format: "%g", weightAndYardage.yardage!)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased()) / \(weightAndYardage.grams!) grams")
            : Text("")
        ) {
            if (order == 0 && isYarn) || isPattern {
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
                
                if (weightAndYardage.unitOfMeasure == UnitOfMeasure.meters) {
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.yardage = Double(String(format : "%.2f", yardsToMeters * weightAndYardage.yardage!))!
                    }
                    
                    if weightAndYardage.hasExactLength == 1 && weightAndYardage.exactLength != nil {
                        weightAndYardage.exactLength = Double(String(format : "%.2f", yardsToMeters * weightAndYardage.exactLength!))!
                    }
                } else {
                    if weightAndYardage.yardage != nil {
                        weightAndYardage.yardage = Double(String(format : "%.2f", weightAndYardage.yardage! / yardsToMeters))!
                    }
                    
                    if weightAndYardage.hasExactLength == 1 && weightAndYardage.exactLength != nil {
                        weightAndYardage.exactLength = Double(String(format : "%.2f", weightAndYardage.exactLength! / yardsToMeters))!
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
                    weightAndYardage.approximateLength = weightAndYardage.yardage! * weightAndYardage.skeins
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
                    if weightAndYardage.exactLength != nil {
                        Text("\(String(format: "%g", weightAndYardage.exactLength!)) \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
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
                    weightAndYardage.exactLength = nil
                    weightAndYardage.approximateLength = nil
                }
                
                if weightAndYardage.hasExactLength == 1 {
                    TextField(
                        "Length Needed (in \(weightAndYardage.unitOfMeasure.rawValue.lowercased()))",
                        value: $weightAndYardage.exactLength,
                        format: .number
                    )
                    .keyboardType(.decimalPad)
                    .transition(.slide)
                } else if weightAndYardage.hasExactLength == 0 {
                    Stepper("Skeins: \(String(format: "%g", weightAndYardage.skeins))", value: $weightAndYardage.skeins, in: 1...50)
                        .onChange(of: weightAndYardage.skeins) {
                            if weightAndYardage.yardage != nil {
                                weightAndYardage.approximateLength = weightAndYardage.yardage! * weightAndYardage.skeins
                            }
                        }
                    
                    if weightAndYardage.approximateLength != nil {
                        HStack {
                            Text("Estimated Length Needed")
                            Spacer()
                            Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.approximateLength!)) ?? "0") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
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
                    weightAndYardage.exactLength = nil
                    weightAndYardage.approximateLength = nil
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
                                        weightAndYardage.exactLength = (weightAndYardage.yardage! * Double(weightAndYardage.totalGrams!)) / Double(weightAndYardage.grams!)
                                    }
                                }
                            }
                        }
                        .transition(.slide)
                    
                    if weightAndYardage.exactLength != nil && weightAndYardage.totalGrams != nil {
                        HStack {
                            Text("Length")
                            
                            Spacer()
                            
                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.exactLength!)) ?? "0") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
                        }
                        .transition(.slide)
                    }
                    
                    if weightAndYardage.skeins != 0 {
                        HStack {
                            Text("Skeins")
                            Spacer()
                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.skeins)) ?? "1")")
                        }
                        .transition(.slide)
                    }
                } else if weightAndYardage.hasBeenWeighed == 0 {
                    Stepper("Skeins: \(String(format: "%g", weightAndYardage.skeins))", value: $weightAndYardage.skeins, in: 1...50)
                        .onChange(of: weightAndYardage.skeins) {
                            if weightAndYardage.yardage != nil {
                                weightAndYardage.approximateLength = weightAndYardage.yardage! * weightAndYardage.skeins
                            }
                        }
                    
                    Toggle("Partial Skein", isOn: $weightAndYardage.hasPartialSkein)
                    
                    if weightAndYardage.approximateLength != nil {
                        HStack {
                            Text("Length Estimate")
                            Spacer()
                            Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: weightAndYardage.approximateLength!)) ?? "0") \(weightAndYardage.unitOfMeasure.rawValue.lowercased())")
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
