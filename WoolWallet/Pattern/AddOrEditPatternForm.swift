//
//  AddOrEditPattern.swift
//  WoolWallet
//
//  Created by Mac on 9/29/24.
//

import Foundation
import SwiftUI

let patternTypes : [PatternType] = [PatternType.crochet, PatternType.knit]

struct PatternItemField: Identifiable, Equatable {
    let id = UUID()
    
    var item: Item
    var showDescription : Bool = false
    var description : String = ""
}

struct AddOrEditPatternForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    // Fetched data
    @FetchRequest(entity: Pattern.entity(), sortDescriptors: [])
    var patterns: FetchedResults<Pattern>
    
    var patternToEdit: Pattern?
    var onAdd: ((Pattern) -> Void)?
    
    @State private var showExistingPatternAlert   : Bool = false
    
    // Form fields
    @State private var patternType         : PatternType = PatternType.crochet
    @State private var name                : String = ""
    @State private var designer            : String = ""
    @State private var items              : [PatternItemField] = [PatternItemField(item : Item.none)]
    @State private var oneSize             : Int = -1
    @State private var intendedSize        : String = ""
    @State private var crochetHookSizes    : [CrochetHookSize] = [CrochetHookSize.none]
    @State private var knittingNeedleSizes : [KnitNeedleSize] = [KnitNeedleSize.none]
    @State private var recWeightAndYardage : WeightAndYardage = WeightAndYardage()
    @State private var notes               : String = ""
    
    init(patternToEdit : Pattern?, onAdd: ((Pattern) -> Void)? = nil) {
        self.patternToEdit = patternToEdit
        self.onAdd = onAdd
        
        // Pre-populate the form if editing an existing Yarn
        if let patternToEdit = patternToEdit {
            _name         = State(initialValue : patternToEdit.name ?? "")
            _designer     = State(initialValue : patternToEdit.designer ?? "")
            _notes        = State(initialValue : patternToEdit.notes ?? "")
        }
    }
    
    // Computed property to get unique dyers
    var uniqueDesigners: [String] {
        var designersSet = Set<String>()

        for pattern in patterns {
            if let designer = pattern.designer {
                designersSet.insert(designer)
            }
        }
        
        return Array(designersSet) // Convert the set back to an array
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Information")) {
                    Picker("Type", selection: $patternType) {
                        ForEach(0..<patternTypes.count) { index in
                            Text(patternTypes[index].rawValue).tag(patternTypes[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Name", text: $name).disableAutocorrection(true)
                    
                    TextFieldTypeahead(field: $designer, label: "Designer", allResults: uniqueDesigners)
                }
                
                // TODO: List of common ones or free text
                Section(
                    header: Text("What does this pattern make?"),
                    footer:
                        HStack {
                            Spacer()
                            
                            Button {
                                addItem()
                            } label : {
                                Text("Need another item?")
                            }
                        }
                ) {
                    List {
                        ForEach($items.indices, id: \.self) { index in
                            Picker("Item \(items.count > 1 ? "\(index + 1)" : "")", selection: $items[index].item) {
                                ForEach(Item.allCases, id: \.id) { item in
                                    HStack {
                                        if item != Item.none {
                                            let itemDisplay = PatternUtils.shared.getItemDisplay(for: item)
                                            
                                            if itemDisplay.custom {
                                                Image(itemDisplay.icon).iconCircle(background: itemDisplay.color, smallMode : true)
                                            } else {
                                                Image(systemName: itemDisplay.icon).iconCircle(background: itemDisplay.color, smallMode : true)
                                            }
                                        }
                                        
                                        Text(item.rawValue)
                                    }
                                    .tag(item)
                                   
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .deleteDisabled(items.count < 2)
                            .onChange(of: items) {
                                if items[index].item == Item.other {
                                    items[index].showDescription = true
                                } else {
                                    items[index].showDescription = false
                                }
                            }
                            
                            if items[index].showDescription {
                                TextField("Description", text: $items[index].description).disableAutocorrection(true)
                            }
                        }
                        .onDelete(perform: deleteItem)
                        
//                        ForEach($items) { $item in
//                            TextFieldTypeahead(
//                                field: $item.item,
//                                label: "Item \(items.count > 1 ? "\(items.firstIndex(of: $item.wrappedValue)! + 1)" : "")", // or use a different identifier
//                                allResults: Item.allCases.map { $0.rawValue }
//                            )
//                            .deleteDisabled(items.count < 2)
//                        }
//                        .onDelete(perform: deleteItem)
                    }
                }
                
                
                Section(header: Text("Is this pattern one size?")) {
                    Picker("", selection: $oneSize) {
                        Text("Yes").tag(1)
                        Text("No").tag(0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if oneSize == 0 {
                        TextField("Intended Size", text: $intendedSize).disableAutocorrection(true)
                    }
                }
                
                // hooks (depends on knit or crochet
                Section(
                    header: Text(patternType == PatternType.crochet ? "Hooks" : "Needles"),
                    footer: 
                        HStack {
                            Spacer()
                            
                            Button {
                                patternType == PatternType.crochet ? addCrochetHook() : addKnittingNeedle()
                            } label : {
                                Text("Need another \(patternType == PatternType.crochet ? "hook" : "needle")?")
                            }
                        }
                ) {
                    if patternType == PatternType.crochet {
                        List {
                            ForEach($crochetHookSizes.indices, id: \.self) { index in
                                Picker("Hook \(crochetHookSizes.count > 1 ? "\(index + 1)" : "Size")", selection: $crochetHookSizes[index]) {
                                    ForEach(CrochetHookSize.allCases, id: \.id) { hookSize in
                                        Text(hookSize.rawValue).tag(hookSize)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .deleteDisabled(crochetHookSizes.count < 2)
                            }
                            .onDelete(perform: deleteHook)
                        }
                    } else {
                        List {
                            ForEach($knittingNeedleSizes.indices, id: \.self) { index in
                                Picker("Needle \(knittingNeedleSizes.count > 1 ? "\(index + 1)" : "Size")", selection: $knittingNeedleSizes[index]) {
                                    ForEach(KnitNeedleSize.allCases, id: \.id) { needleSize in
                                        Text(needleSize.rawValue).tag(needleSize)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .deleteDisabled(knittingNeedleSizes.count < 2)
                            }
                            .onDelete(perform: deleteNeedle)
                        }
                    }
                }
                
                // techniques (depends on knit or crochet
                
                // notions
                
                WeightAndYardageForm(
                    weightAndYardage: $recWeightAndYardage,
                    isSockSet: false,
                    isPattern : true,
                    skeinIndex: 0,
                    hasTwoMinis: .constant(false)
                )
                
                Section(header: Text("Anything else you'd like to note?")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Button(patternToEdit == nil ? "Add" : "Save", action: {
                    createOrUpdatePattern()
                })
                .disabled(name.isEmpty)
            }
            .navigationTitle(patternToEdit == nil ? "New Pattern" : "Edit Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        createOrUpdatePattern()
                    }) {
                        Text(patternToEdit == nil ? "Add" : "Save")
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createOrUpdatePattern() {
        if patternToEdit == nil {
//            existingYarn = getExistingYarn(name: name, dyer : dyer, in: managedObjectContext)
//            
//            if existingYarn != nil {
//                showExistingYarnAlert = true
//            }
        }
        
        if !showExistingPatternAlert {
            let newPattern = persistPattern(pattern: patternToEdit == nil ? Pattern(context: managedObjectContext) : patternToEdit!)
            
            if onAdd != nil {
                onAdd!(newPattern)
            } else {
                hideKeyboard()
                dismiss()
            }
        }
    }
    
    func persistPattern(pattern : Pattern) -> Pattern {
        pattern.id = pattern.id != nil ? pattern.id : UUID()
        pattern.name = name
        pattern.designer = designer
        pattern.type = patternType.rawValue
        
        pattern.oneSize = Int16(oneSize)
        pattern.intendedSize = intendedSize
        
        // main skein
        pattern.recWeight        = recWeightAndYardage.weight.rawValue
        pattern.recUnitOfMeasure = recWeightAndYardage.unitOfMeasure.rawValue
        pattern.recLength        = recWeightAndYardage.length ?? 0
        pattern.recGrams         = Int16(recWeightAndYardage.grams ?? 0)
        
        pattern.notes = notes
        
        if items.first?.item != Item.none {
            let patternItems: [PatternItem] = items.map { item in
                return PatternItem.from(item: item.item.rawValue, context: managedObjectContext)
            }
            
            pattern.items = NSSet(array: patternItems)
        }
  
        
        let crochetHooks: [CrochetHook] = crochetHookSizes.map { item in
            return CrochetHook.from(size: item.rawValue, context: managedObjectContext)
        }
        
        pattern.crochetHooks = NSSet(array: crochetHooks)
        
        let knittingNeedles: [KnittingNeedle] = knittingNeedleSizes.map { item in
            return KnittingNeedle.from(size: item.rawValue, context: managedObjectContext)
        }
        
        pattern.knittingNeedles = NSSet(array: knittingNeedles)
        
//        let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
//            return StoredImage.from(image: element, order: index, context: managedObjectContext)
//        }
//        
//        pattern.images = NSSet(array: storedImages)
        
        PersistenceController.shared.save()
        
        return pattern
    }
    
    private func addCrochetHook() {
        crochetHookSizes.append(CrochetHookSize.none)
    }
    
    private func addKnittingNeedle() {
        knittingNeedleSizes.append(KnitNeedleSize.none)
    }
    
    private func addItem() {
        items.append(PatternItemField(item: Item.none))
    }
    
    func deleteNeedle(at offsets: IndexSet) {
        knittingNeedleSizes.remove(atOffsets: offsets)
    }
    
    func deleteHook(at offsets: IndexSet) {
        crochetHookSizes.remove(atOffsets: offsets)
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
