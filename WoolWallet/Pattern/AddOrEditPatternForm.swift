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

struct NotionItem: Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var notion: PatternNotion
    var description : String = ""
    var existingItem : Notion? = nil
}

struct TechniqueItem: Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var technique: PatternTechnique
    var description : String = ""
    var existingItem : Technique? = nil
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
    
    @State private var showExistingPatternAlert : Bool = false
    @State private var imagesChanged            : Bool = false
    
    // Form fields
    @State private var patternType          : PatternType = PatternType.crochet
    @State private var name                 : String = ""
    @State private var designer             : String = ""
    @State private var items                : [PatternItemField] = [PatternItemField(item : Item.none)]
    @State private var oneSize              : Bool = false
    @State private var owned                : Bool = true
    @State private var intendedSize         : String = ""
    @State private var crochetHookSizes     : [Hook] = [Hook(hook: CrochetHookSize.none)]
    @State private var knittingNeedleSizes  : [Needle] = [Needle(needle: KnitNeedleSize.none)]
    @State private var recWeightAndYardages : [WeightAndYardageData] = [WeightAndYardageData(parent: WeightAndYardageParent.pattern)]
    @State private var notes                : String = ""
    @State private var images               : [ImageData] = []
    @State private var notions              : [NotionItem] = [NotionItem(notion: PatternNotion.none)]
    @State private var techniques           : [TechniqueItem] = [TechniqueItem(technique: PatternTechnique.none)]
    
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
            _oneSize              = State(initialValue : patternToEdit.oneSize)
            _owned                = State(initialValue : patternToEdit.owned)
            _intendedSize         = State(initialValue : patternToEdit.intendedSize ?? "")
            _crochetHookSizes     = State(initialValue : patternToEdit.crochetHooks)
            _knittingNeedleSizes  = State(initialValue : patternToEdit.knittingNeedles)
            _recWeightAndYardages = State(initialValue : patternToEdit.weightAndYardageItems)
            _images               = State(initialValue : patternToEdit.uiImages)
            _notions              = State(initialValue : patternToEdit.notionItems)
            _techniques           = State(initialValue : patternToEdit.techniqueItems)
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
                    .onChange(of: patternType) {
                        techniques = [TechniqueItem(technique: PatternTechnique.none)]
                    }
                    
                    TextField("Name", text: $name).disableAutocorrection(true)
                    
                    TextFieldTypeahead(field: $designer, label: "Designer", allResults: uniqueDesigners)
                }
                
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
                                            PatternItemDisplayWithItem(item: item, size: Size.small)
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
                
                Section(header: Text("Additional Information")) {
                    Toggle("One Size", isOn: $oneSize)
                    
                    if !oneSize {
                        TextField("Intended Size", text: $intendedSize).disableAutocorrection(true)
                    }
                    
                    Toggle("Owned", isOn: $owned)
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
                                            Text("\(item.yardage!.formatted) \(item.unitOfMeasure.rawValue) / \(item.grams!) grams")
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
                                            Text(item.skeins.formatted)
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
                
                Section(
                    header: Text("Techniques"),
                    footer:
                        HStack {
                            Spacer()
                            
                            Button {
                                addTechnique()
                            } label : {
                                Text("Need another technique?")
                            }
                        }
                ) {
                    List {
                        ForEach($techniques.indices, id: \.self) { index in
                            Picker("Technique \(techniques.count > 1 ? "\(index + 1)" : "")", selection: $techniques[index].technique) {
                                let list = patternType == PatternType.crochet
                                    ? PatternUtils.shared.crochetTechniques()
                                    : patternType == PatternType.knit
                                        ? PatternUtils.shared.knitTechniques()
                                        : PatternUtils.shared.tunisianTechniques()
                                
                                ForEach(list, id: \.id) { technique in
                                    Text(technique.rawValue).tag(technique)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .deleteDisabled(techniques.count < 2)
                            
                            if techniques[index].technique == PatternTechnique.other {
                                TextField("Description", text: $techniques[index].description).disableAutocorrection(true)
                            }
                        }
                        .onDelete(perform: deleteTechnique)
                    }
                }
                
                Section(
                    header: Text("Notions"),
                    footer:
                        HStack {
                            Spacer()
                            
                            Button {
                                addNotion()
                            } label : {
                                Text("Need another notion?")
                            }
                        }
                ) {
                    List {
                        ForEach($notions.indices, id: \.self) { index in
                            Picker("Notion \(notions.count > 1 ? "\(index + 1)" : "")", selection: $notions[index].notion) {
                                ForEach(PatternNotion.allCases, id: \.id) { notion in
                                    Text(notion.rawValue).tag(notion)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .deleteDisabled(notions.count < 2)
                            
                            if notions[index].notion == PatternNotion.other {
                                TextField("Description", text: $notions[index].description).disableAutocorrection(true)
                            }
                        }
                        .onDelete(perform: deleteNotion)
                    }
                }
                
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
            .onChange(of: images) {
                imagesChanged = true
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
        
        pattern.oneSize = oneSize
        pattern.intendedSize = oneSize ? nil : intendedSize
        pattern.owned = owned
        pattern.notes = notes
        
        // delete any items that we don't need anymore
        if patternToEdit != nil {
            patternToEdit?.weightAndYardageArray.forEach { item in
                if !recWeightAndYardages.contains(where: {element in element.id == item.id}) {
                    item.patternPairings?.forEach { managedObjectContext.delete($0 as! NSManagedObject) }
                    
                    managedObjectContext.delete(item)
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
            
            patternToEdit?.notionItems.forEach { item in
                if !notions.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            patternToEdit?.techniqueItems.forEach { item in
                if !techniques.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            if imagesChanged {
                patternToEdit?.uiImages.forEach { item in
                    if !images.contains(where: {element in element.id == item.id}) {
                        managedObjectContext.delete(item.existingItem!)
                    }
                }
            }
        }
        
        // weightAndYardages
        let weightAndYardageArray: [WeightAndYardage] = recWeightAndYardages.enumerated().map { (index, element) in
            var data = element
            
            let wAndY = WeightAndYardage.from(data: data, order: index, context: managedObjectContext)
            
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
        
        // notions
        let notionItems: [Notion] = notions.enumerated().map { (index, element) in
            return Notion.from(notionItem: element, order: index, context: managedObjectContext)
        }
        
        pattern.notions = NSSet(array: notionItems)
        
        // techniques
        let techniqueItems: [Technique] = techniques.enumerated().map { (index, element) in
            return Technique.from(techniqueItem: element, order: index, context: managedObjectContext)
        }
        
        pattern.techniques = NSSet(array: techniqueItems)
        
        if imagesChanged {
            // images
            let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
                return StoredImage.from(data: element, order: index, context: managedObjectContext)
            }
            
            pattern.images = NSSet(array: storedImages)
        }
        
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
    
    private func addNotion() {
        notions.append(NotionItem(notion: PatternNotion.none))
    }
    
    private func addTechnique() {
        techniques.append(TechniqueItem(technique: PatternTechnique.none))
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
    
    func deleteNotion(at offsets: IndexSet) {
        notions.remove(atOffsets: offsets)
    }
    
    func deleteTechnique(at offsets: IndexSet) {
        techniques.remove(atOffsets: offsets)
    }
}
