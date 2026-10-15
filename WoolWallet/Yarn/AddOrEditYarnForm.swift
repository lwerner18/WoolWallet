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
    /// Colors found in the first photo, offered to the user rather than applied automatically
    @State private var suggestedColors       : [Color]? = nil
    @State private var selectedSuggestions   : Set<Int> = []
    /// The photo colors were last detected from, so adding more photos doesn't detect again
    @State private var analyzedImageID       : UUID? = nil
    @State private var imagesChanged         : Bool = false
    @State private var showLabelScanner      : Bool = false
    @State private var photoLabel            : PhotoLabel? = nil
    @State private var showPhotoLabelReview  : Bool = false
    /// The version of each photo last read for a label, so a rotated photo is read again
    @State private var labelCheckedImages    : [UUID: UIImage] = [:]
    /// Renewed after returning from the composition screen to clear the row's stuck highlight;
    /// a new ID on every render would rebuild the row on each keystroke
    @State private var compositionLinkID     = UUID()
    @State private var photosOnScreen        : Bool = true
    @State private var isSaving              : Bool = false
    @State private var encodedPhotos         : [UUID: Data] = [:]
    @State private var duplicateCheck        : DuplicateCheck? = nil
    @State private var duplicateConfirmed    : Bool = false
    @State private var showNewColorPicker    : Bool = false
    
    /// Presented as a sheet item so the sheet is built with the matches rather than an earlier, empty list
    private struct DuplicateCheck: Identifiable {
        let id = UUID()
        let matches : [Yarn]
    }
    
    private struct PhotoLabel {
        var label : ScannedYarnLabel
        var imageID : UUID
        var image : UIImage
    }
    
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
            let initialImages  = isCopy ? [] : yarnToEdit.uiImages
            _images            = State(initialValue : initialImages)
            _analyzedImageID   = State(initialValue : initialImages.first?.id)
            
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
                _colorPickers      = State(initialValue : yarnToEdit.colorPickerItems)
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
                Section {
                    Button {
                        showLabelScanner = true
                    } label: {
                        Label("Scan Yarn Label", systemImage: "text.viewfinder")
                    }
                } footer: {
                    Text("Fill in the name, weight, yardage, and composition from the label.")
                }
                
                photoLabelPrompt
                
                Section(header: Text("Images")) {
                    ImageCarousel(images : $images, editMode: true, editExistingImages : yarnToEdit != nil && !isCopy, allowsZoom: true)
                        .customFormSection()
                        .onAppear { photosOnScreen = true }
                        .onDisappear { photosOnScreen = false }
                }
                
                if !images.isEmpty && (processingColor || suggestedColors != nil) {
                    colorSuggestion
                } else if !images.isEmpty {
                    colorSection
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
                        CompositionChart(composition: composition, yarnColors: colorPickers.map(\.color))
                        CompositionText(composition: composition)
                    }
                    .customFormSection()
                    
                    
                }
                
                Section(header: Text("What is this yarn made of?")) {
                    NavigationLink {
                        EditComposition(composition: $composition, photos: images.map(\.image))
                            .onDisappear { compositionLinkID = UUID() }
                    } label: {
                        Label("Composition", systemImage : "chart.pie")
                    }
                    .id(compositionLinkID)
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
                
                Button(isCreatingNewYarn ? "Add" : "Save", action: save)
                    .disabled(name.isEmpty || images.isEmpty || isSaving)
            }
            .overlay {
                if !images.isEmpty {
                    FloatingPhotoReference(images: images.map(\.image), isVisible: !photosOnScreen)
                }
            }
            .onChange(of: images) {
                guard let firstImage = images.first else {
                    analyzedImageID = nil
                    processingColor = false
                    suggestedColors = nil
                    return
                }
                
                if firstImage.id != analyzedImageID {
                    analyzedImageID = firstImage.id
                    detectColors(in: firstImage)
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
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isCreatingNewYarn ? "Add" : "Save", action: save)
                            .disabled(name.isEmpty || images.isEmpty)
                    }
                }
            }
            .onChange(of: images) {
                imagesChanged = true
                checkNewPhotosForLabel()
            }
            .fullScreenCover(isPresented: $showLabelScanner) {
                LabelScannerSheet(knownDyers: uniqueDyers) { label, fields, photo in
                    applyScannedLabel(label, fields: fields, photo: photo)
                }
            }
            .sheet(isPresented: $showPhotoLabelReview) {
                photoLabelReview
            }
            .sheet(item: $duplicateCheck, onDismiss: {
                // Saved once the sheet is gone, since a new yarn swaps this form for its success screen
                if duplicateConfirmed {
                    duplicateConfirmed = false
                    performSave()
                }
            }) { check in
                DuplicateYarnSheet(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    dyer: dyer.trimmingCharacters(in: .whitespacesAndNewlines),
                    matches: check.matches,
                    isEditing: !isCreatingNewYarn
                ) {
                    duplicateConfirmed = true
                }
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = snapshot
                }
            }
        }
        .interactiveDismissDisabled(hasChanges || isSaving)
    }
    
    private func save() {
        guard !isSaving else { return }
        
        hideKeyboard()
        
        let matches = possibleDuplicates
        if !matches.isEmpty {
            duplicateCheck = DuplicateCheck(matches: matches)
            return
        }
        
        performSave()
    }
    
    private func performSave() {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            encodedPhotos = await StoredImage.encodeNewPhotos(images)
            createOrUpdateYarn()
        }
    }
    
    /// Other yarn with the same name and dyer, ignoring case, accents, and spacing. Copies are skipped since they're
    /// duplicates on purpose, and so are edits that leave the name and dyer as they were.
    private var possibleDuplicates : [Yarn] {
        guard !isCopy else { return [] }
        
        let nameKey = Self.matchKey(name)
        let dyerKey = Self.matchKey(dyer)
        
        if let yarnToEdit, Self.matchKey(yarnToEdit.name ?? "") == nameKey, Self.matchKey(yarnToEdit.dyer ?? "") == dyerKey {
            return []
        }
        
        return yarns.filter { yarn in
            yarn != yarnToEdit
                && !yarn.isDeleted
                && Self.matchKey(yarn.name ?? "") == nameKey
                && Self.matchKey(yarn.dyer ?? "") == dyerKey
        }
    }
    
    private static func matchKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    private func createOrUpdateYarn() {
        let yarn = isCreatingNewYarn ? Yarn(context: managedObjectContext) : yarnToEdit!
        let newYarn = persistYarn(yarn: yarn)
        
        if let onAdd {
            onAdd(newYarn)
        } else {
            dismiss()
        }
    }
    
    private func applyScannedLabel(_ label: ScannedYarnLabel, fields: Set<LabelField>, photo: UIImage?) {
        if fields.contains(.name), let scannedName = label.name {
            name = scannedName
        }
        
        if fields.contains(.dyer), let scannedDyer = label.dyer {
            dyer = scannedDyer
        }
        
        if fields.contains(.sockSet), label.isSockSet, !isSockSet {
            // The toggle's onChange adds the mini skein, same as flipping it by hand
            withAnimation {
                isSockSet = true
            }
        }
        
        if fields.contains(.weight), let weight = label.weight {
            weightAndYardages[0].weight = weight
        }
        
        if fields.contains(.length), let length = label.length {
            // Keep the form's unit; changing it would make the unit picker re-convert the new value
            let labelUnit = label.unitOfMeasure ?? .yards
            let yardsToMeters = 0.9144
            
            switch (labelUnit, weightAndYardages[0].unitOfMeasure) {
            case (.meters, .yards): weightAndYardages[0].yardage = (length / yardsToMeters).rounded()
            case (.yards, .meters): weightAndYardages[0].yardage = (length * yardsToMeters).rounded()
            default:                weightAndYardages[0].yardage = length
            }
        }
        
        if fields.contains(.grams), let grams = label.grams {
            weightAndYardages[0].grams = grams
        }
        
        if fields.contains(.composition), !label.composition.isEmpty {
            composition = label.composition
        }
        
        var labelNotes : [String] = []
        
        if fields.contains(.colorway), let colorway = label.colorway {
            labelNotes.append("Colorway: \(colorway)")
        }
        
        if fields.contains(.dyeLot), let dyeLot = label.dyeLot {
            labelNotes.append("Dye lot: \(dyeLot)")
        }
        
        if fields.contains(.otherInfo), let otherInfo = label.otherInfo {
            labelNotes.append(otherInfo)
        }
        
        if !labelNotes.isEmpty {
            notes = ([notes].filter { !$0.isEmpty } + labelNotes).joined(separator: "\n")
        }
        
        if let photo {
            let imageData = ImageData(image: photo)
            // Already read, so don't offer the same label again
            labelCheckedImages[imageData.id] = imageData.image
            images.append(imageData)
        }
    }
    
    @ViewBuilder
    private var photoLabelPrompt: some View {
        if let photoLabel {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "text.viewfinder")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Found label info in your photo")
                            .font(.subheadline)
                            .bold()
                        
                        Text(LabelField.found(in: photoLabel.label).map(\.shortTitle).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Review") {
                        showPhotoLabelReview = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button {
                        withAnimation {
                            self.photoLabel = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
            }
            .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private var photoLabelReview: some View {
        if let photoLabel {
            // Shows any rotation made since the label was found
            let image = images.first(where: { $0.id == photoLabel.imageID })?.image ?? photoLabel.image
            
            NavigationStack {
                LabelScanReview(label: photoLabel.label, image: image, allowsAddingPhoto: false) { editedLabel, fields, _ in
                    applyScannedLabel(editedLabel, fields: fields, photo: nil)
                    showPhotoLabelReview = false
                    self.photoLabel = nil
                }
                .navigationTitle("Label Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showPhotoLabelReview = false }
                    }
                }
            }
        }
    }
    
    private func checkNewPhotosForLabel() {
        // Text reads poorly sideways, so a rotated photo is read again
        let newImages = images.filter { $0.existingItem == nil && labelCheckedImages[$0.id] !== $0.image }
        guard !newImages.isEmpty else { return }
        
        for imageData in newImages {
            labelCheckedImages[imageData.id] = imageData.image
        }
        let knownDyers = uniqueDyers
        
        Task {
            for imageData in newImages {
                guard photoLabel == nil || photoLabel?.imageID == imageData.id,
                      let label = try? await YarnLabelReader.read(imageData.image, knownDyers: knownDyers) else { continue }
                
                // Any text can look like a name, so wait for something only a yarn label would have
                guard LabelField.found(in: label).filter({ $0 != .otherInfo }).count >= 2, label.labelDetailCount >= 1 else { continue }
                
                // The photo may have been removed or rotated again while it was being read
                guard images.first(where: { $0.id == imageData.id })?.image === imageData.image else { continue }
                
                withAnimation {
                    photoLabel = PhotoLabel(label: label, imageID: imageData.id, image: imageData.image)
                }
            }
        }
    }
    
    private var colorSection: some View {
        Section(header: Text(colorPickers.count == 1 ? "Color" : "Colors")) {
            ForEach($colorPickers) { $item in
                ColorRow(item: $item, photos: images.map(\.image)) {
                    withAnimation {
                        removeColorPicker(item)
                    }
                }
            }
            .onDelete { offsets in
                colorPickers.remove(atOffsets: offsets)
            }
            
            // Picked first, so there's no placeholder color to replace
            Button {
                hideKeyboard()
                showNewColorPicker = true
            } label: {
                Label("Add Color", systemImage: "plus.circle")
            }
            .sheet(isPresented: $showNewColorPicker) {
                YarnColorPickerSheet(color: colorPickers.last?.color ?? Color.white, photos: images.map(\.image)) { color in
                    withAnimation {
                        colorPickers.append(ColorPickerItem(color: color, name: ColorNaming.closestName(to: UIColor(color)) ?? ""))
                    }
                }
            }
            
            if !colorPickers.isEmpty {
                Picker("Color Type", selection: $colorType) {
                    ForEach(ColorType.allCases, id: \.id) { colorTypeEnum in
                        Text(colorTypeEnum.rawValue).tag(colorTypeEnum as ColorType?)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
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
    
    private func detectColors(in imageData: ImageData) {
        let image = imageData.image
        processingColor = true
        suggestedColors = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            AnalyzeColorUtils.shared.classifyImageWithModel(image: image) { mask in
                DispatchQueue.global(qos: .userInitiated).async {
                    let colors = mask.flatMap { try? AnalyzeColorUtils.shared.yarnColors(from: image, with: $0) } ?? []
                    
                    DispatchQueue.main.async {
                        // The first photo changed while this one was being read
                        guard analyzedImageID == imageData.id else { return }
                        
                        withAnimation {
                            processingColor = false
                            suggestedColors = colors.isEmpty ? nil : colors
                            selectedSuggestions = Set(colors.indices)
                        }
                    }
                }
            }
        }
    }
    
    private func useSuggestedColors() {
        guard let suggestedColors else { return }
        
        withAnimation {
            colorPickers = suggestedColors.indices
                .filter { selectedSuggestions.contains($0) }
                .map { ColorPickerItem(color: suggestedColors[$0], name: "") }
            self.suggestedColors = nil
        }
    }
    
    @ViewBuilder
    private var colorSuggestion: some View {
        if processingColor {
            Section(header: Text("Color")) {
                HStack(spacing: 12) {
                    ProgressView()
                    
                    Text("Finding colors in your photo...")
                        .foregroundStyle(Color.secondary)
                }
            }
        } else if let suggestedColors {
            Section(header: Text("Color")) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(
                        suggestedColors.count == 1 ? "Found a color in your photo" : "Found \(suggestedColors.count) colors in your photo",
                        systemImage: "sparkles"
                    )
                    .font(.subheadline.bold())
                    
                    if suggestedColors.count > 1 {
                        Text("Tap a color to leave it out.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    HStack(spacing: 10) {
                        ForEach(suggestedColors.indices, id: \.self) { index in
                            suggestionSwatch(suggestedColors[index], index: index, isToggleable: suggestedColors.count > 1)
                        }
                    }
                    
                    HStack {
                        Button(addSuggestionsTitle, action: useSuggestedColors)
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedSuggestions.isEmpty)
                        
                        Button("No Thanks") {
                            withAnimation {
                                self.suggestedColors = nil
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.small)
                    
                    if !colorPickers.isEmpty {
                        Text("Replaces the yarn's current colors.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var addSuggestionsTitle: String {
        selectedSuggestions.count == 1 ? "Add Color" : "Add \(selectedSuggestions.count) Colors"
    }
    
    private func suggestionSwatch(_ color: Color, index: Int, isToggleable: Bool) -> some View {
        let isSelected = selectedSuggestions.contains(index)
        
        return Button {
            withAnimation(.snappy) {
                if isSelected {
                    selectedSuggestions.remove(index)
                } else {
                    selectedSuggestions.insert(index)
                }
            }
        } label: {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Color.primary.opacity(0.15)))
                .overlay(alignment: .bottomTrailing) {
                    if isToggleable {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.footnote.bold())
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .background(Circle().fill(Color(UIColor.systemBackground)))
                            .offset(x: 3, y: 3)
                    }
                }
                .opacity(isSelected ? 1 : 0.35)
        }
        .buttonStyle(.borderless)
        .disabled(!isToggleable)
        .accessibilityLabel("Color \(index + 1)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                // Rotated photos keep their ID but are saved as new, so match on the saved photo itself
                if !images.contains(where: { $0.existingItem == item.existingItem }) {
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
            StoredImage.from(data: element, order: index, context: managedObjectContext, encodedPhotos: encodedPhotos)
        }
    }
}
