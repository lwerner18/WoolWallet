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

let unitsOfMeasure : [UnitOfMeasure] = [UnitOfMeasure.yards, UnitOfMeasure.meters]

let weights : [Weight] = [Weight.none, Weight.zero, Weight.one, Weight.two, Weight.three, Weight.four, Weight.five, Weight.six, Weight.seven]

struct AddOrEditYarnForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    // Fetched data
    @FetchRequest(entity: Yarn.entity(), sortDescriptors: [])
    var yarns: FetchedResults<Yarn>
    
    // Binding variables
    @Binding var toast: Toast?
    var yarnToEdit: Yarn?
    var onAdd: ((Yarn) -> Void)? // Closure to return the newly added yarn
    
    // Internal state trackers
    @State private var images = [UIImage]()
    @State private var showExistingYarnAlert   : Bool = false
    @State private var existingYarn            : Yarn? = nil
    @State private var processingColor         : Bool = false
    @State private var showPartialSkeinSlider  : Bool = false
    @State private var partialSkein            : Double = 0.0
    @State private var hasTwoMinis             : Bool = false
    @State private var maskImage               : UIImage? // This will hold the segmentation mask image
    
    // Form fields
    @State private var name                  : String = ""
    @State private var dyer                  : String = ""
    @State private var isSockSet             : Bool = false
    @State private var weightAndYardage      : WeightAndYardage = WeightAndYardage()
    @State private var mini1WeightAndYardage : WeightAndYardage = WeightAndYardage()
    @State private var mini2WeightAndYardage : WeightAndYardage = WeightAndYardage()
    @State private var notes                 : String = ""
    @State private var caked                 : Bool = false
    @State private var archive               : Bool = false
    @State private var colorPickers          : [ColorPickerItem] = []
    @State private var composition           : [CompositionItem] = []
    
    // init function
    init(toast : Binding<Toast?>, yarnToEdit : Yarn?, onAdd: ((Yarn) -> Void)? = nil) {
        self.yarnToEdit = yarnToEdit
        self._toast = toast
        self.onAdd = onAdd
        
        // Pre-populate the form if editing an existing Yarn
        if let yarnToEdit = yarnToEdit {
            _name         = State(initialValue : yarnToEdit.name ?? "")
            _dyer         = State(initialValue : yarnToEdit.dyer ?? "")
            _notes        = State(initialValue : yarnToEdit.notes ?? "")
            _caked        = State(initialValue : yarnToEdit.isCaked)
            _isSockSet    = State(initialValue : yarnToEdit.isSockSet)
            _hasTwoMinis  = State(initialValue : yarnToEdit.hasTwoMinis)
            _archive      = State(initialValue : yarnToEdit.isArchived)
            _images       = State(initialValue : yarnToEdit.uiImages)
            _composition  = State(initialValue : yarnToEdit.compositionItems)
            _colorPickers = State(initialValue : yarnToEdit.colorPickerItems)
            
            _weightAndYardage = State(
                initialValue: WeightAndYardage(
                    weight            : yarnToEdit.weight != nil ? Weight(rawValue: yarnToEdit.weight!)! : Weight.none,
                    unitOfMeasure     : yarnToEdit.unitOfMeasure != nil ? UnitOfMeasure(rawValue: yarnToEdit.unitOfMeasure!)! : UnitOfMeasure.yards,
                    length            : yarnToEdit.length != 0 ? yarnToEdit.length : nil,
                    grams             : yarnToEdit.grams != 0 ? Int(yarnToEdit.grams) : nil,
                    hasBeenWeighed    : Int(yarnToEdit.hasBeenWeighed),
                    totalGrams        : yarnToEdit.totalGrams != 0 ? Int(yarnToEdit.totalGrams) : nil,
                    skeins            : yarnToEdit.skeins,
                    hasPartialSkein   : yarnToEdit.hasPartialSkein,
                    exactLength       : yarnToEdit.exactLength
                )
            )
            
            _mini1WeightAndYardage = State(
                initialValue: WeightAndYardage(
                    unitOfMeasure     : yarnToEdit.mini1UnitOfMeasure != nil ? UnitOfMeasure(rawValue: yarnToEdit.mini1UnitOfMeasure!)! : UnitOfMeasure.yards,
                    length            : yarnToEdit.mini1Length != 0 ? yarnToEdit.mini1Length : nil,
                    grams             : yarnToEdit.mini1Grams != 0 ? Int(yarnToEdit.mini1Grams) : nil,
                    hasBeenWeighed    : Int(yarnToEdit.mini1HasBeenWeighed),
                    totalGrams        : yarnToEdit.mini1TotalGrams != 0 ? Int(yarnToEdit.mini1TotalGrams) : nil,
                    skeins            : yarnToEdit.mini1Skeins,
                    hasPartialSkein   : yarnToEdit.mini1HasPartialSkein,
                    exactLength       : yarnToEdit.mini1ExactLength
                )
            )
            
            _mini2WeightAndYardage = State(
                initialValue: WeightAndYardage(
                    unitOfMeasure     : yarnToEdit.mini2UnitOfMeasure != nil ? UnitOfMeasure(rawValue: yarnToEdit.mini2UnitOfMeasure!)! : UnitOfMeasure.yards,
                    length            : yarnToEdit.mini2Length != 0 ? yarnToEdit.mini2Length : nil,
                    grams             : yarnToEdit.mini2Grams != 0 ? Int(yarnToEdit.mini2Grams) : nil,
                    hasBeenWeighed    : Int(yarnToEdit.mini2HasBeenWeighed),
                    totalGrams        : yarnToEdit.mini2TotalGrams != 0 ? Int(yarnToEdit.mini2TotalGrams) : nil,
                    skeins            : yarnToEdit.mini2Skeins,
                    hasPartialSkein   : yarnToEdit.mini2HasPartialSkein,
                    exactLength       : yarnToEdit.mini2ExactLength
                )
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
                ImageCarousel(images : $images, editMode: true, editExistingImages : yarnToEdit != nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .background(Color(UIColor.systemGroupedBackground))
                
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
                        
                        
                    }
                }
                
                Section(header: Text("General Information")) {
                    TextField("Name", text: $name).disableAutocorrection(true)
                    
                    TextFieldTypeahead(field: $dyer, label: "Dyer", allResults: uniqueDyers)
                    
                    Toggle("Sock Set", isOn: $isSockSet.animation())
                        .onChange(of: isSockSet) {
                            if isSockSet && weightAndYardage.weight == Weight.none {
                                weightAndYardage.weight = Weight.one
                            } else if !isSockSet && weightAndYardage.weight == Weight.one {
                                weightAndYardage.weight = Weight.none
                            }
                        }
                }
                
                if isSockSet {
                    VStack {
                        Divider()
                        
                        HStack {
                            Text("Main Skein").bold().font(.title)
                            
                            Spacer()
                        }
                    }
                    .transition(.slide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .background(Color(UIColor.systemGroupedBackground))
                }
                
                WeightAndYardageForm(weightAndYardage: $weightAndYardage, isSockSet: isSockSet, skeinIndex: 0, hasTwoMinis: $hasTwoMinis)
                
                if isSockSet {
                    VStack {
                        Divider()
                        
                        HStack {
                            Text(hasTwoMinis ? "Mini #1" : "Mini").bold().font(.title)
                            
                            Spacer()
                        }
                    }
                    .transition(.slide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    WeightAndYardageForm(weightAndYardage: $mini1WeightAndYardage, isSockSet: isSockSet, skeinIndex: 1, hasTwoMinis: $hasTwoMinis)
                        .transition(.slide)
                    
                    if hasTwoMinis {
                        VStack {
                            Divider()
                            
                            HStack {
                                Text("Mini #2").bold().font(.title)
                                
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        hasTwoMinis = false
                                    }
                                } label: {
                                    Label("", systemImage : "xmark.circle")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                                
                            }
                        }
                        .transition(.slide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .background(Color(UIColor.systemGroupedBackground))
                        
                        WeightAndYardageForm(weightAndYardage: $mini2WeightAndYardage, isSockSet: isSockSet, skeinIndex: 2, hasTwoMinis: $hasTwoMinis)
                            .transition(.slide)
                    }
                    
                    Divider()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .background(Color(UIColor.systemGroupedBackground))
                }
                
                if !composition.isEmpty {
                    VStack {
                        CompositionChart(composition: composition)
                        CompositionText(composition: composition)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets())
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    
                }
                
                Section() {
                    NavigationLink {
                        EditComposition(composition: $composition)
                    } label: {
                        Label("Composition", systemImage : "chart.pie")
                    }
                    .id(UUID())
                }
                
                Section(header: Text("Additional Information")) {
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
                        let distinctColors = AnalyzeColorUtils.shared.yarnColors(from: images.first!, with: maskImage!)
                        
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
    
    private func removeColorPicker(_ item: ColorPickerItem) {
        colorPickers.removeAll { $0.id == item.id }
    }
    
    func performSegmentation() {
        guard let inputImage = self.images.first else { return }
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
        yarn.id = yarn.id != nil ? yarn.id : UUID()
        yarn.name = name
        yarn.dyer = dyer
        yarn.isSockSet = isSockSet
        yarn.hasTwoMinis = hasTwoMinis
        
        // main skein
        yarn.weight            = weightAndYardage.weight.rawValue
        yarn.unitOfMeasure     = weightAndYardage.unitOfMeasure.rawValue
        yarn.length            = weightAndYardage.length ?? 0
        yarn.grams             = Int16(weightAndYardage.grams ?? 0)
        yarn.hasBeenWeighed    = Int16(weightAndYardage.hasBeenWeighed)
        yarn.totalGrams        = Int16(weightAndYardage.totalGrams ?? 0)
        yarn.skeins            = weightAndYardage.skeins
        yarn.hasPartialSkein   = weightAndYardage.hasBeenWeighed == 0 ? weightAndYardage.hasPartialSkein : false
        yarn.exactLength       = weightAndYardage.hasBeenWeighed == 1 ? weightAndYardage.exactLength : 0
        yarn.approximateLength = (yarn.exactLength == 0 && weightAndYardage.length != nil) ? weightAndYardage.length! * weightAndYardage.skeins : 0
        
        // first mini
        yarn.mini1UnitOfMeasure     = mini1WeightAndYardage.unitOfMeasure.rawValue
        yarn.mini1Length            = mini1WeightAndYardage.length ?? 0
        yarn.mini1Grams             = Int16(mini1WeightAndYardage.grams ?? 0)
        yarn.mini1HasBeenWeighed    = Int16(mini1WeightAndYardage.hasBeenWeighed)
        yarn.mini1TotalGrams        = Int16(mini1WeightAndYardage.totalGrams ?? 0)
        yarn.mini1Skeins            = mini1WeightAndYardage.skeins
        yarn.mini1HasPartialSkein   = mini1WeightAndYardage.hasBeenWeighed == 0 ? mini1WeightAndYardage.hasPartialSkein : false
        yarn.mini1ExactLength       = mini1WeightAndYardage.hasBeenWeighed == 1 ? mini1WeightAndYardage.exactLength : 0
        yarn.mini1ApproximateLength = (yarn.mini1ExactLength == 0 && mini1WeightAndYardage.length != nil) ? mini1WeightAndYardage.length! * mini1WeightAndYardage.skeins : 0
        
        // second mini
        yarn.mini2UnitOfMeasure     = mini2WeightAndYardage.unitOfMeasure.rawValue
        yarn.mini2Length            = mini2WeightAndYardage.length ?? 0
        yarn.mini2Grams             = Int16(mini2WeightAndYardage.grams ?? 0)
        yarn.mini2HasBeenWeighed    = Int16(mini2WeightAndYardage.hasBeenWeighed)
        yarn.mini2TotalGrams        = Int16(mini2WeightAndYardage.totalGrams ?? 0)
        yarn.mini2Skeins            = mini2WeightAndYardage.skeins
        yarn.mini2HasPartialSkein   = mini2WeightAndYardage.hasBeenWeighed == 0 ? mini2WeightAndYardage.hasPartialSkein : false
        yarn.mini2ExactLength       = mini2WeightAndYardage.hasBeenWeighed == 1 ? mini2WeightAndYardage.exactLength : 0
        yarn.mini2ApproximateLength = (yarn.mini2ExactLength == 0 && mini2WeightAndYardage.length != nil) ? mini2WeightAndYardage.length! * mini2WeightAndYardage.skeins : 0
        
        yarn.isCaked = caked
        yarn.isArchived = archive
        yarn.notes = notes
        
        let storedColors: [StoredColor] = colorPickers.map { item in
            return StoredColor.from(color: item.color, name: item.name, context: managedObjectContext)
        }
        
        yarn.colors = NSSet(array: storedColors)
        
        let compositions: [Composition] = composition.map { item in
            return Composition.from(compositionItem: item, context: managedObjectContext)
        }
        
        yarn.composition = NSSet(array: compositions)
        
        let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
            return StoredImage.from(image: element, order: index, context: managedObjectContext)
        }
        
        yarn.images = NSSet(array: storedImages)
        
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
