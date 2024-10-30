//
//  AddOrEditPattern.swift
//  WoolWallet
//
//  Created by Mac on 9/29/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternItemField: Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var item: Item
    var description : String = ""
    var existingItem : PatternItem? = nil
}

struct Hook: Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var hook: CrochetHookSize
    var existingItem : CrochetHook? = nil
}

struct Needle: Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var needle: KnitNeedleSize
    var existingItem : KnittingNeedle? = nil
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
    @State private var patternType          : PatternType = PatternType.crochet
    @State private var name                 : String = ""
    @State private var designer             : String = ""
    @State private var items                : [PatternItemField] = [PatternItemField(item : Item.none)]
    @State private var oneSize              : Int = -1
    @State private var intendedSize         : String = ""
    @State private var crochetHookSizes     : [Hook] = [Hook(hook: CrochetHookSize.none)]
    @State private var knittingNeedleSizes  : [Needle] = [Needle(needle: KnitNeedleSize.none)]
    @State private var recWeightAndYardages : [WeightAndYardageData] = [WeightAndYardageData(parent: WeightAndYardageParent.pattern)]
    @State private var notes                : String = ""
    @State private var images               : [ImageData] = []
    
    init(patternToEdit : Pattern?, onAdd: ((Pattern) -> Void)? = nil) {
        self.patternToEdit = patternToEdit
        self.onAdd = onAdd
        
        // Pre-populate the form if editing an existing Yarn
        if let patternToEdit = patternToEdit {
            _patternType          = State(initialValue : PatternType(rawValue: patternToEdit.type!)!)
            _name                 = State(initialValue : patternToEdit.name ?? "")
            _designer             = State(initialValue : patternToEdit.designer ?? "")
            _notes                = State(initialValue : patternToEdit.notes ?? "")
            _items                = State(initialValue : patternToEdit.patternItems)
            _oneSize              = State(initialValue : Int(patternToEdit.oneSize))
            _intendedSize         = State(initialValue : patternToEdit.intendedSize ?? "")
            _crochetHookSizes     = State(initialValue : patternToEdit.crochetHooks)
            _knittingNeedleSizes  = State(initialValue : patternToEdit.knittingNeedles)
            _recWeightAndYardages = State(initialValue : patternToEdit.weightAndYardageItems)
            _images               = State(initialValue : patternToEdit.uiImages)
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
                        ForEach(PatternType.allCases, id: \.id) { patternType in
                            Text(patternType.rawValue).tag(patternType)
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
                            
                            if items[index].item == Item.other {
                                TextField("Description", text: $items[index].description).disableAutocorrection(true)
                            }
                        }
                        .onDelete(perform: deleteItem)
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
                
                Section(header: Text("What kind of yarn do you need?")) {
                    NavigationLink {
                        RecYarnForm(recWeightAndYardages: $recWeightAndYardages)
                    } label: {
                        Label("Yarn Specs", systemImage : "volleyball")
                          
                    }
                    .id(UUID())
                    .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                        return 0
                    }
                    
                    ForEach(recWeightAndYardages.indices, id: \.self) { index in
                        let item = recWeightAndYardages[index]
                        
                        if recWeightAndYardages[index].hasBeenEdited() {
                            CollapsibleView(
                                label : {
                                    RecYarnHeader(count: recWeightAndYardages.count, index: index, weightAndYardage: item)
                                },
                                showArrows : true
                            ) {
                                VStack {
                                    if item.yardage != nil && item.grams != nil {
                                        HStack {
                                            Spacer()
                                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: item.yardage!)) ?? "") \(item.unitOfMeasure.rawValue) / \(item.grams!) grams")
                                            Spacer()
                                        }
                                        
                                        Divider()
                                    }
                                    
                                    HStack {
                                        Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(item.weight.rawValue)
                                    }
                                    
                                    if item.hasExactLength == 0 {
                                        Divider()
                                        
                                        HStack {
                                            Text("Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                                            Spacer()
                                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: item.skeins)) ?? "")")
                                        }
                                    }
                                    
                                 
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                
                // hooks (depends on knit or crochet
                Section(
                    header: Text(patternType == PatternType.knit ? "Needles" : "Hooks"),
                    footer:
                        HStack {
                            Spacer()
                            
                            Button {
                                patternType == PatternType.knit ? addKnittingNeedle() : addCrochetHook()
                            } label : {
                                Text("Need another \(patternType == PatternType.knit ? "needle" : "hook")?")
                            }
                        }
                ) {
                    if patternType == PatternType.knit {
                        List {
                            ForEach($knittingNeedleSizes.indices, id: \.self) { index in
                                Picker("Needle \(knittingNeedleSizes.count > 1 ? "\(index + 1)" : "Size")", selection: $knittingNeedleSizes[index].needle) {
                                    ForEach(KnitNeedleSize.allCases, id: \.id) { needleSize in
                                        Text(needleSize.rawValue).tag(needleSize)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .deleteDisabled(knittingNeedleSizes.count < 2)
                            }
                            .onDelete(perform: deleteNeedle)
                        }
                    } else {
                        List {
                            ForEach($crochetHookSizes.indices, id: \.self) { index in
                                Picker("Hook \(crochetHookSizes.count > 1 ? "\(index + 1)" : "Size")", selection: $crochetHookSizes[index].hook) {
                                    ForEach(CrochetHookSize.allCases, id: \.id) { hookSize in
                                        Text(hookSize.rawValue).tag(hookSize)
                                    }
                                }
                                .pickerStyle(.navigationLink)
                                .deleteDisabled(crochetHookSizes.count < 2)
                            }
                            .onDelete(perform: deleteHook)
                        }
                    }
                }
                
                // techniques (depends on knit or crochet
                
                // notions
                
                Section(header: Text("Images")) {
                    ImageCarousel(images : $images, editMode: true, editExistingImages : patternToEdit != nil)
                        .customFormSection()
                }
                
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
        pattern.intendedSize = oneSize == 1 ? nil : intendedSize
        pattern.notes = notes
        
        // delete any items that we don't need anymore
        if patternToEdit != nil {
            patternToEdit?.weightAndYardageItems.forEach { item in
                if !recWeightAndYardages.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            patternToEdit?.patternItems.forEach { item in
                if !items.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            patternToEdit?.crochetHooks.forEach { item in
                if !crochetHookSizes.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            patternToEdit?.knittingNeedles.forEach { item in
                if !knittingNeedleSizes.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            patternToEdit?.uiImages.forEach { item in
                if !images.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
        }
        
        // weightAndYardages
        let weightAndYardageArray: [WeightAndYardage] = recWeightAndYardages.enumerated().map { (index, element) in
            let wAndY = WeightAndYardage.from(data: element, order: index, context: managedObjectContext)
            
            wAndY.patternFavorites?.forEach {
                let item = $0 as! FavoritePairing
                
                if WeightAndYardageUtils.shared.doesNotMatch(favorite: item.yarnWeightAndYardage!, second: wAndY) {
                    managedObjectContext.delete($0 as! NSManagedObject)
                }
            }
            
            return wAndY
        }
        
        pattern.recWeightAndYardages = NSSet(array: weightAndYardageArray)
        
        // items
        let patternItems: [PatternItem] = items.enumerated().map { (index, element) in
            return PatternItem.from(item: element, order: index, context: managedObjectContext)
        }
        
        pattern.items = NSSet(array: patternItems)
        
        // crochet hooks
        let crochetHooks: [CrochetHook] = crochetHookSizes.enumerated().map { (index, element) in
            return CrochetHook.from(hook: element, order: index, context: managedObjectContext)
        }
        
        pattern.hooks = NSSet(array: crochetHooks)
        
        // knitting needles
        let knittingNeedles: [KnittingNeedle] = knittingNeedleSizes.enumerated().map { (index, element) in
            return KnittingNeedle.from(needle: element, order: index, context: managedObjectContext)
        }
        
        pattern.needles = NSSet(array: knittingNeedles)
        
        // images
        let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
            return StoredImage.from(data: element, order: index, context: managedObjectContext)
        }
        
        pattern.images = NSSet(array: storedImages)
        
        PersistenceController.shared.save()
        
        return pattern
    }
    
    private func addCrochetHook() {
        crochetHookSizes.append(Hook(hook: CrochetHookSize.none))
    }
    
    private func addKnittingNeedle() {
        knittingNeedleSizes.append(Needle(needle : KnitNeedleSize.none))
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
