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
    var onAdd: ((Yarn) -> Void)? // Closure to return the newly added yarn
    
    // Internal state trackers
    @State private var images                : [ImageData] = []
    @State private var showExistingYarnAlert : Bool = false
    @State private var existingYarn          : Yarn? = nil
    @State private var processingColor       : Bool = false
    @State private var maskImage             : UIImage? // This will hold the segmentation mask image
    @State private var imagesChanged         : Bool = false
    @State private var errorParsingColor     : Bool = false
    
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
    
    // init function
    init(yarnToEdit : Yarn?, onAdd: ((Yarn) -> Void)? = nil) {
        self.yarnToEdit = yarnToEdit
        self.onAdd = onAdd
        
        // Pre-populate the form if editing an existing Yarn
        if let yarnToEdit = yarnToEdit {
            _name              = State(initialValue : yarnToEdit.name ?? "")
            _dyer              = State(initialValue : yarnToEdit.dyer ?? "")
            _notes             = State(initialValue : yarnToEdit.notes ?? "")
            _caked             = State(initialValue : yarnToEdit.isCaked)
            _isMini            = State(initialValue : yarnToEdit.isMini)
            _colorType         = State(initialValue : yarnToEdit.colorType != nil ? ColorType(rawValue: yarnToEdit.colorType!) : nil)
            _isSockSet         = State(initialValue : yarnToEdit.isSockSet)
            _archive           = State(initialValue : yarnToEdit.isArchived)
            _images            = State(initialValue : yarnToEdit.uiImages)
            _composition       = State(initialValue : yarnToEdit.compositionItems)
            _weightAndYardages = State(initialValue : yarnToEdit.weightAndYardageItems)
            _colorPickers      = State(initialValue : !yarnToEdit.colorPickerItems.isEmpty
                                       ? yarnToEdit.colorPickerItems
                                       : [ColorPickerItem(color: Color.white, name: "White")]
            )
        }
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
                    ImageCarousel(images : $images, editMode: true, editExistingImages : yarnToEdit != nil)
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
                    TextField("Name", text: $name).disableAutocorrection(true)
                    
                    TextFieldTypeahead(field: $dyer, label: "Dyer", allResults: uniqueDyers)
                    
                    Toggle("Sock Set", isOn: $isSockSet.animation())
                        .onChange(of: isSockSet) {
                            if isSockSet && weightAndYardages.first!.weight == Weight.none {
                                weightAndYardages[0].weight = Weight.one
                            } else if !isSockSet && weightAndYardages.first!.weight == Weight.one {
                                weightAndYardages[0].weight = Weight.none
                            }
                            
                            if isSockSet && weightAndYardages.count == 1 {
                                addWeightAndYardage()
                            } else if !isSockSet && weightAndYardages.count > 1 {
                                weightAndYardages = [weightAndYardages.first!]
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
                
                Button(yarnToEdit == nil ? "Add" : "Save", action: {
                    createOrUpdateYarn()
                })
                .disabled(name.isEmpty || images.isEmpty)
            }
            .onChange(of: maskImage) {
                if maskImage != nil {
                    DispatchQueue.global(qos: .background).async {
                        print("Starting to parse color in background")
                        
                        var distinctColors : [Color] = []
                        do {
                            try distinctColors = AnalyzeColorUtils.shared.yarnColors(from: images.first!.image, with: maskImage!)
                        } catch {
                            print("Failed to fetch parse color: \(error)")
                            distinctColors = [Color.white]
                        }
                        
                        DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                            print("Done parsing color")
                            self.colorPickers = distinctColors.map{ color in
                                return ColorPickerItem(color : color,  name : "")
                            }
                            self.processingColor = false
                            print("set")
                        }
                    }
                }
            }
            .onChange(of: images) {
                if yarnToEdit?.colorPickerItems == nil {
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
            .navigationTitle(yarnToEdit == nil ? "New Yarn" : "Edit Yarn")
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
                        createOrUpdateYarn()
                    }) {
                        Text(yarnToEdit == nil ? "Add" : "Save")
                    }
                    .disabled(name.isEmpty || images.isEmpty)
                }
               
            }
            .onChange(of: images) {
                imagesChanged = true
            }
        }
    }
    
    private func createOrUpdateYarn() {
        if yarnToEdit == nil {
            existingYarn = getExistingYarn(name: name, dyer : dyer, in: managedObjectContext)
            
            if existingYarn != nil {
                showExistingYarnAlert = true
            }
        }
        
        if !showExistingYarnAlert {
            let newYarn = persistYarn(yarn: yarnToEdit == nil ? Yarn(context: managedObjectContext) : yarnToEdit!)
            
            if onAdd != nil {
                onAdd!(newYarn)
            } else {
                hideKeyboard()
                dismiss()
            }
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
        print("Kicking off.")
        DispatchQueue.global(qos: .background).async {
            print("In background")
            processingColor = true
            AnalyzeColorUtils.shared.classifyImageWithModel(image: inputImage) { mask in
                DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                    print("Done and updating")
                    self.maskImage = mask
                }
            }
        }
    }
    
    func persistYarn(yarn : Yarn) -> Yarn {
        let isEdit = yarn.id != nil
        
        yarn.id = isEdit ? yarn.id : UUID()
        yarn.name = name
        yarn.dyer = dyer
        yarn.isSockSet = isSockSet
        yarn.isMini = isMini
        yarn.colorType = colorType != nil ? colorType!.rawValue : ""
        yarn.isCaked = caked
        yarn.isArchived = archive
        yarn.notes = notes
        
        // delete any items that we don't need anymore
        if yarnToEdit != nil {
            yarnToEdit?.weightAndYardageItems.forEach { item in
                if !weightAndYardages.contains(where: {element in element.id == item.id}) {
                    let existingItem = item.existingItem!
                    
                    existingItem.yarnPairings?.forEach { managedObjectContext.delete($0 as! NSManagedObject) }
                    
                    managedObjectContext.delete(existingItem)
                }
            }
            
            yarnToEdit?.colorPickerItems.forEach { item in
                if !colorPickers.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            yarnToEdit?.compositionItems.forEach { item in
                if !composition.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            if imagesChanged {
                yarnToEdit?.uiImages.forEach { item in
                    if !images.contains(where: {element in element.id == item.id}) {
                        managedObjectContext.delete(item.existingItem!)
                    }
                }
            }
        }
        
        let weightAndYardageArray: [WeightAndYardage] = weightAndYardages.enumerated().map { (index, element) in
            var data = element
            
            if index > 0 {
                data.weight = weightAndYardages.first!.weight
            }
            
            let wAndY = WeightAndYardage.from(data: data, order: index, context: managedObjectContext)
            
            wAndY.yarnFavorites?.forEach {
                let item = $0 as! FavoritePairing
                
                if WeightAndYardageUtils.shared.doesNotMatch(favorite: item.patternWeightAndYardage!, second: wAndY) {
                    managedObjectContext.delete($0 as! NSManagedObject)
                }
            }
            
            return wAndY
        }
        
        yarn.weightAndYardages = NSSet(array: weightAndYardageArray)
        
        // colorPickers
        let storedColors: [StoredColor] = colorPickers.map { item in
            return StoredColor.from(data: item, context: managedObjectContext)
        }
        
        yarn.colors = NSSet(array: storedColors)
        
        // compositions
        let compositions: [Composition] = composition.map { item in
            return Composition.from(compositionItem: item, context: managedObjectContext)
        }
        
        yarn.composition = NSSet(array: compositions)
        
        if imagesChanged {
            // images
            let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
                return StoredImage.from(data: element, order: index, context: managedObjectContext)
            }
            
            yarn.images = NSSet(array: storedImages)
        }
        
        PersistenceController.shared.save()
        
        return yarn
    }
    
    func getExistingYarn(name: String, dyer : String, in context: NSManagedObjectContext) -> Yarn? {
        let fetchRequest: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND dyer ==[c] %@", name, dyer)
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            // Handle or log the error
            print("Fetch error: \(error.localizedDescription)")
            return nil
        }
    }
}
