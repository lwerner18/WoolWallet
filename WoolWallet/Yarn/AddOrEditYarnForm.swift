//
//  AddOrEditYarnForm.swift
//  WoolWallet
//
//  Created by Mac on 9/21/24.
//

import SwiftUI
import PhotosUI
import CoreData
import UIImageColors
import UIKit
import CoreImage
import Combine

struct AddOrEditYarnForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    // Fetched data
    @FetchRequest(entity: Yarn.entity(), sortDescriptors: [])
    var yarns: FetchedResults<Yarn>
    
    // Binding variables
    var yarnToEdit: Yarn?
    var isCopy: Bool
    var onAdd: ((Yarn) -> Void)? // Closure to return the newly added yarn
    
    // Internal state trackers
    @State private var images                : [ImageData] = []
    @State private var processingColor       : Bool = false
    @State private var maskImage             : UIImage? // This will hold the segmentation mask image
    @State private var imagesChanged         : Bool = false
    
    // Form fields
    @State private var name              : String = ""
    @State private var dyer              : String = ""
    @State private var isSockSet         : Bool = false
    @State private var weightAndYardages : [WeightAndYardageData] = [WeightAndYardageData(parent: WeightAndYardageParent.yarn)]
    @State private var notes             : String = ""
    @State private var caked             : Bool = false
    @State private var archive           : Bool = false
    @State private var isMini            : Bool = false
    @State private var colorType         : ColorType? = nil
    @State private var colorPickers      : [ColorPickerItem] = []
    @State private var composition       : [CompositionItem] = []
    
    @State private var initialSnapshot   : FormSnapshot? = nil
    
    private struct FormSnapshot: Equatable {
        var images            : [ImageData]
        var name              : String
        var dyer              : String
        var isSockSet         : Bool
        var weightAndYardages : [WeightAndYardageData]
        var notes             : String
        var caked             : Bool
        var archive           : Bool
        var isMini            : Bool
        var colorType         : ColorType?
        var colorPickers      : [ColorPickerItem]
        var composition       : [CompositionItem]
    }
    
    private var snapshot: FormSnapshot {
        FormSnapshot(
            images: images,
            name: name,
            dyer: dyer,
            isSockSet: isSockSet,
            weightAndYardages: weightAndYardages,
            notes: notes,
            caked: caked,
            archive: archive,
            isMini: isMini,
            colorType: colorType,
            colorPickers: colorPickers,
            composition: composition
        )
    }
    
    private var hasChanges: Bool {
        initialSnapshot.map { $0 != snapshot } ?? false
    }
    
    // init function
    init(yarnToEdit : Yarn?, isCopy : Bool = false, onAdd: ((Yarn) -> Void)? = nil) {
        self.yarnToEdit = yarnToEdit
        self.isCopy = isCopy
        self.onAdd = onAdd
        
        // Pre-populate the form if editing or copying an existing Yarn
        if let yarnToEdit = yarnToEdit {
            _name              = State(initialValue : yarnToEdit.name ?? "")
            _dyer              = State(initialValue : yarnToEdit.dyer ?? "")
            _notes             = State(initialValue : isCopy ? "" : yarnToEdit.notes ?? "")
            _caked             = State(initialValue : yarnToEdit.isCaked)
            _isMini            = State(initialValue : yarnToEdit.isMini)
            _colorType         = State(initialValue : yarnToEdit.colorType != nil ? ColorType(rawValue: yarnToEdit.colorType!) : nil)
            _isSockSet         = State(initialValue : yarnToEdit.isSockSet)
            // Copies always start active, even when duplicating an archived yarn
            _archive           = State(initialValue : isCopy ? false : yarnToEdit.isArchived)
            // New photos for a copy; keep source images only when editing
            _images            = State(initialValue : isCopy ? [] : yarnToEdit.uiImages)
            
            let existingWeightAndYardages = isCopy
                ? yarnToEdit.weightAndYardageItemsForCopy
                : yarnToEdit.weightAndYardageItems
            // The form assumes at least one entry; older yarns can be missing them
            _weightAndYardages = State(initialValue : existingWeightAndYardages.isEmpty
                                       ? [WeightAndYardageData(parent: WeightAndYardageParent.yarn)]
                                       : existingWeightAndYardages
            )
            
            if isCopy {
                // Clone values without linking to the source yarn's Core Data children
                _composition       = State(initialValue : yarnToEdit.compositionItemsForCopy)
                _colorPickers      = State(initialValue : yarnToEdit.colorPickerItemsForCopy)
            } else {
                _composition       = State(initialValue : yarnToEdit.compositionItems)
                _colorPickers      = State(initialValue : !yarnToEdit.colorPickerItems.isEmpty
                                           ? yarnToEdit.colorPickerItems
                                           : [ColorPickerItem(color: Color.white, name: "White")]
                )
            }
        }
    }
    
    private var isCreatingNewYarn: Bool {
        yarnToEdit == nil || isCopy
    }
    
    // Computed property to get unique dyers
    var uniqueDyers: [String] {
        var dyersSet = Set<String>()
        
        for yarn in yarns {
            if let dyer = yarn.dyer {
                dyersSet.insert(dyer) // Use lowercased for case insensitivity
            }
        }
        
        return Array(dyersSet) // Convert the set back to an array
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Images")) {
                    ImageCarousel(images : $images, editMode: true, editExistingImages : yarnToEdit != nil && !isCopy)
                        .customFormSection()
                }
                
                if !images.isEmpty {
                    if processingColor {
                        Section {
                            ProgressView("Analyzing Color...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    } else {
                        ForEach($colorPickers.indices, id: \.self) { index in
                            ColorPickerView(
                                colorPickerItem: $colorPickers[index],
                                removeAction: {removeColorPicker(colorPickers[index])},
                                addAction: {addColorPicker()},
                                displayAddButton : index == 0,
                                canRemove: colorPickers.count > 1
                            )
                        }
                        
                        Section(header: Text("How would you describe the color?")) {
                            Picker("", selection: $colorType) {
                                ForEach(ColorType.allCases, id: \.id) { colorTypeEnum in
                                    Text(colorTypeEnum.rawValue).tag(colorTypeEnum as ColorType?)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                
                Section(header: Text("General Information")) {
                    TextField("Name", text: $name).autocorrectionDisabled()
                    
                    TextFieldTypeahead(field: $dyer, label: "Dyer", allResults: uniqueDyers)
                    
                    Toggle("Sock Set", isOn: $isSockSet.animation())
                        .onChange(of: isSockSet) {
                            if weightAndYardages.isEmpty {
                                addWeightAndYardage()
                            }
                            
                            if isSockSet && weightAndYardages[0].weight == Weight.none {
                                weightAndYardages[0].weight = Weight.one
                            } else if !isSockSet && weightAndYardages[0].weight == Weight.one {
                                weightAndYardages[0].weight = Weight.none
                            }
                            
                            if isSockSet && weightAndYardages.count == 1 {
                                addWeightAndYardage()
                            } else if !isSockSet && weightAndYardages.count > 1 {
                                weightAndYardages = [weightAndYardages[0]]
                            }
                        }
                }
                
                ForEach($weightAndYardages.indices, id: \.self) { index in
                    WeightAndYardageForm(
                        weightAndYardage: $weightAndYardages[index],
                        isSockSet: isSockSet,
                        order: index,
                        totalCount: weightAndYardages.count,
                        addAction: {addWeightAndYardage()},
                        removeAction: {removeWeightAndYardage(weightAndYardages[index])}
                    )
                }
                
                if !composition.isEmpty {
                    VStack {
                        CompositionChart(composition: composition)
                        CompositionText(composition: composition)
                    }
                    .customFormSection()
                    
                    
                }
                
                Section(header: Text("What is this yarn made of?")) {
                    NavigationLink {
                        EditComposition(composition: $composition)
                    } label: {
                        Label("Composition", systemImage : "chart.pie")
                    }
                    .id(UUID())
                }
                
                Section(header: Text("Additional Information")) {
                    Toggle("Mini", isOn: $isMini)
                    Toggle("Caked", isOn: $caked)
                    Toggle("Archive", isOn: $archive)
                }
                
                Section(header: Text("Anything else you'd like to note?")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Button(isCreatingNewYarn ? "Add" : "Save", action: {
                    createOrUpdateYarn()
                })
                .disabled(name.isEmpty || images.isEmpty)
            }
            .onChange(of: maskImage) {
                if maskImage != nil {
                    DispatchQueue.global(qos: .background).async {
                        var distinctColors : [Color] = []
                        do {
                            try distinctColors = AnalyzeColorUtils.shared.yarnColors(from: images.first!.image, with: maskImage!)
                        } catch {
                            print("Failed to parse yarn colors: \(error)")
                            distinctColors = [Color.white]
                        }
                        
                        if distinctColors.isEmpty {
                            distinctColors = [Color.white]
                        }
                        
                        DispatchQueue.main.async {
                            self.colorPickers = distinctColors.map { color in
                                ColorPickerItem(color: color, name: "")
                            }
                            self.processingColor = false
                        }
                    }
                }
            }
            .onChange(of: images) {
                // Auto-detect colors for brand-new yarns and copies (edit keeps manual colors)
                if isCreatingNewYarn && !images.isEmpty {
                    performSegmentation()
                }
            }
            .onChange(of: colorPickers) {
                if colorPickers.count > 1 {
                    colorType = ColorType.variegated
                } else {
                    colorType = ColorType.tonal
                }
            }
            .navigationTitle(isCreatingNewYarn ? "New Yarn" : "Edit Yarn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DiscardChangesButton(hasChanges: hasChanges) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        createOrUpdateYarn()
                    }) {
                        Text(isCreatingNewYarn ? "Add" : "Save")
                    }
                    .disabled(name.isEmpty || images.isEmpty)
                }
            }
            .onChange(of: images) {
                imagesChanged = true
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = snapshot
                }
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }
    
    private func createOrUpdateYarn() {
        let yarn = isCreatingNewYarn ? Yarn(context: managedObjectContext) : yarnToEdit!
        let newYarn = persistYarn(yarn: yarn)
        
        hideKeyboard()
        
        if let onAdd {
            onAdd(newYarn)
        } else {
            dismiss()
        }
    }
    
    private func addColorPicker() {
        colorPickers.insert(ColorPickerItem(color: Color.white, name : "White"), at: 0)
    }
    
    private func addWeightAndYardage() {
        weightAndYardages.append(WeightAndYardageData(parent: WeightAndYardageParent.yarn))
    }
    
    private func removeColorPicker(_ item: ColorPickerItem) {
        colorPickers.removeAll { $0.id == item.id }
    }
    
    private func removeWeightAndYardage(_ item: WeightAndYardageData) {
        weightAndYardages.removeAll { $0.id == item.id }
    }
    
    func performSegmentation() {
        guard let inputImage = self.images.first?.image else { return }
        processingColor = true
        DispatchQueue.global(qos: .userInitiated).async {
            AnalyzeColorUtils.shared.classifyImageWithModel(image: inputImage) { mask in
                DispatchQueue.main.async {
                    if let mask {
                        self.maskImage = mask
                    } else {
                        // Keep whatever colors are already on the form
                        self.processingColor = false
                    }
                }
            }
        }
    }
    
    func persistYarn(yarn: Yarn) -> Yarn {
        let isEdit = yarnToEdit != nil && !isCopy
        
        yarn.id = isEdit ? yarn.id : UUID()
        yarn.name = name
        yarn.dyer = dyer
        yarn.isSockSet = isSockSet
        yarn.isMini = isMini
        yarn.colorType = colorType?.rawValue ?? ""
        yarn.isCaked = caked
        yarn.isArchived = archive
        yarn.notes = notes
        
        if isEdit, let yarnToEdit {
            deleteRemovedChildren(for: yarnToEdit)
        }
        
        yarn.weightAndYardages = NSSet(array: buildWeightAndYardageChildren())
        yarn.colors = NSSet(array: buildStoredColors())
        yarn.composition = NSSet(array: buildCompositions())
        
        // New / copied yarns always persist whatever images are on the form
        if imagesChanged || isCopy {
            yarn.images = NSSet(array: buildStoredImages())
        }
        
        PersistenceController.shared.save()
        return yarn
    }
    
    private func deleteRemovedChildren(for original: Yarn) {
        // Weight & Yardage
        original.weightAndYardageArray.forEach { item in
            if !weightAndYardages.contains(where: { $0.id == item.id }) {
                item.yarnPairings?.forEach { managedObjectContext.delete($0 as! NSManagedObject) }
                managedObjectContext.delete(item)
            }
        }
        
        // Colors
        original.colorPickerItems.forEach { item in
            if !colorPickers.contains(where: { $0.id == item.id }) {
                managedObjectContext.delete(item.existingItem!)
            }
        }
        
        // Composition
        original.compositionItems.forEach { item in
            if !composition.contains(where: { $0.id == item.id }) {
                managedObjectContext.delete(item.existingItem!)
            }
        }
        
        // Images
        if imagesChanged {
            original.uiImages.forEach { item in
                if !images.contains(where: { $0.id == item.id }) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
        }
    }

    private func buildWeightAndYardageChildren() -> [WeightAndYardage] {
        return weightAndYardages.enumerated().map { (index, element) in
            var data = element
            
            // Keep 1st weight on all skeins
            if index > 0, let w = weightAndYardages.first?.weight {
                data.weight = w
            }

            
            let w = WeightAndYardage.from(
                data: data,
                order: index,
                context: managedObjectContext
            )
            
            // Clean up invalid favorites
            w.yarnFavorites?.forEach { fav in
                let f = fav as! FavoritePairing
                if WeightAndYardageUtils.shared.doesNotMatch(favorite: f.patternWeightAndYardage!, second: w) {
                    managedObjectContext.delete(f)
                }
            }
            
            return w
        }
    }
    
    private func buildStoredColors() -> [StoredColor] {
        colorPickers.map {
            StoredColor.from(data: $0, context: managedObjectContext)
        }
    }
    
    private func buildCompositions() -> [Composition] {
        composition.map {
            Composition.from(compositionItem: $0, context: managedObjectContext)
        }
    }
    
    private func buildStoredImages() -> [StoredImage] {
        images.enumerated().map { (index, element) in
            StoredImage.from(data: element, order: index, context: managedObjectContext)
        }
    }
}
