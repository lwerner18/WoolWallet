//
//  AddOrEditPattern.swift
//  WoolWallet
//
//  Created by Mac on 9/29/24.
//

import Foundation
import SwiftUI
import CoreData
import PhotosUI

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
    /// Renewed after returning from yarn specs to clear the row's stuck highlight;
    /// a new ID on every render would rebuild the row on each keystroke
    @State private var yarnSpecsLinkID          = UUID()
    @State private var isSaving                 : Bool = false
    @State private var saveFailed               : Bool = false
    @State private var encodedPhotos            : [UUID: Data] = [:]
    
    // Pattern file
    @State private var documentData             : Data? = nil
    @State private var documentName             : String? = nil
    /// Renewed whenever the file is added, replaced, or removed, so unsaved changes don't need the file compared byte by byte
    @State private var documentVersion          : UUID? = nil
    @State private var documentChanged          : Bool = false
    @State private var documentFirstPage        : UIImage? = nil
    @State private var documentPageCount        : Int = 0
    /// Cover-card cache only — not added to the pattern's photo album
    @State private var documentThumbnail        : Data? = nil
    @State private var isReadingDocument        : Bool = false
    @State private var documentMessage          : String? = nil
    @State private var patternReview            : PatternReviewItem? = nil
    @State private var showFileImporter         : Bool = false
    @State private var showPhotoPicker          : Bool = false
    @State private var photoSelection           : [PhotosPickerItem] = []
    @State private var showDocumentScanner      : Bool = false
    @State private var showDocumentPreview      : Bool = false
    @State private var showLinkImport           : Bool = false
    /// Held until the link sheet closes, since the review sheet can't open while it's still on screen
    @State private var linkedFile               : PatternLink.File? = nil
    /// Read from a web page when it was imported; not saved, so a saved pattern is read from its PDF
    @State private var documentPageText         : PatternText? = nil
    @State private var documentPagePhoto        : UIImage? = nil
    
    private struct PatternReviewItem: Identifiable {
        let id = UUID()
        let pattern : ScannedPattern
        let photo : UIImage?
        let photoIsFirstPage : Bool
    }
    
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
    
    @State private var initialSnapshot      : FormSnapshot? = nil
    
    private struct FormSnapshot: Equatable {
        var patternType          : PatternType
        var name                 : String
        var designer             : String
        var items                : [PatternItemField]
        var oneSize              : Bool
        var owned                : Bool
        var intendedSize         : String
        var crochetHookSizes     : [Hook]
        var knittingNeedleSizes  : [Needle]
        var recWeightAndYardages : [WeightAndYardageData]
        var notes                : String
        var images               : [ImageData]
        var notions              : [NotionItem]
        var techniques           : [TechniqueItem]
        var documentVersion      : UUID?
    }
    
    private var snapshot: FormSnapshot {
        FormSnapshot(
            patternType: patternType,
            name: name,
            designer: designer,
            items: items,
            oneSize: oneSize,
            owned: owned,
            intendedSize: intendedSize,
            crochetHookSizes: crochetHookSizes,
            knittingNeedleSizes: knittingNeedleSizes,
            recWeightAndYardages: recWeightAndYardages,
            notes: notes,
            images: images,
            notions: notions,
            techniques: techniques,
            documentVersion: documentVersion
        )
    }
    
    private var hasChanges: Bool {
        initialSnapshot.map { $0 != snapshot } ?? false
    }
    
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
            
            if let document = patternToEdit.document, let data = document.data {
                _documentData      = State(initialValue : data)
                _documentName      = State(initialValue : document.fileName)
                _documentVersion   = State(initialValue : UUID())
                _documentPageCount = State(initialValue : PatternFile.pageCount(of: data))
            }
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
                documentSection
                
                Section(header: Text("General Information")) {
                    Picker("Type", selection: $patternType) {
                        ForEach(PatternType.allCases, id: \.id) { patternType in
                            Text(patternType.rawValue).tag(patternType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: patternType) {
                        // Techniques filled in from a pattern file already suit its type
                        let available = techniqueList(for: patternType)
                        let kept = techniques.filter { $0.technique != .none && ($0.technique == .other || available.contains($0.technique)) }
                        techniques = kept.isEmpty ? [TechniqueItem(technique: PatternTechnique.none)] : kept
                    }
                    
                    TextField("Name", text: $name).autocorrectionDisabled()
                    
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
                                TextField("Description", text: $items[index].description).autocorrectionDisabled()
                            }
                        }
                        .onDelete(perform: deleteItem)
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    Toggle("One Size", isOn: $oneSize)
                    
                    if !oneSize {
                        TextField("Intended Size", text: $intendedSize).autocorrectionDisabled()
                    }
                    
                    Toggle("Owned", isOn: $owned)
                }
                
                Section(header: Text("What kind of yarn do you need?")) {
                    NavigationLink {
                        RecYarnForm(recWeightAndYardages: $recWeightAndYardages)
                            .onDisappear { yarnSpecsLinkID = UUID() }
                    } label: {
                        Label("Yarn Specs", systemImage : "volleyball")
                          
                    }
                    .id(yarnSpecsLinkID)
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
                                ForEach(techniqueList(for: patternType), id: \.id) { technique in
                                    Text(technique.rawValue).tag(technique)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .deleteDisabled(techniques.count < 2)
                            
                            if techniques[index].technique == PatternTechnique.other {
                                TextField("Description", text: $techniques[index].description).autocorrectionDisabled()
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
                                TextField("Description", text: $notions[index].description).autocorrectionDisabled()
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
                
                Button(patternToEdit == nil ? "Add" : "Save", action: save)
                    .disabled(name.isEmpty || isSaving)
            }
            .navigationTitle(patternToEdit == nil ? "New Pattern" : "Edit Pattern")
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
                        Button(patternToEdit == nil ? "Add" : "Save", action: save)
                            .disabled(name.isEmpty)
                    }
                }
            }
            .onChange(of: images) {
                imagesChanged = true
            }
            .alert("Couldn't Save", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong saving this pattern. Please try again.")
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = snapshot
                }
            }
            .task(id: documentVersion) {
                if let documentData, documentFirstPage == nil {
                    documentFirstPage = await PatternFile.firstPageImage(of: documentData, maxPixels: 300)
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    Task {
                        do {
                            let file = try await PatternFile.load(from: urls)
                            setDocument(file.data, name: file.name)
                        } catch {
                            documentMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    documentMessage = error.localizedDescription
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoSelection, maxSelectionCount: 30, matching: .images)
            .onChange(of: photoSelection) {
                let selection = photoSelection
                guard !selection.isEmpty else { return }
                photoSelection = []
                
                Task {
                    var photos : [UIImage] = []
                    for item in selection {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            photos.append(image)
                        }
                    }
                    
                    guard !photos.isEmpty else {
                        documentMessage = "Those photos couldn't be loaded."
                        return
                    }
                    
                    setDocument(await PatternFile.pdfData(from: photos), name: "Pattern Photos")
                }
            }
            .fullScreenCover(isPresented: $showDocumentScanner) {
                DocumentScanner { pages in
                    showDocumentScanner = false
                    
                    Task {
                        setDocument(await PatternFile.pdfData(from: pages), name: "Scanned Pattern")
                    }
                } onCancel: {
                    showDocumentScanner = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showLinkImport) {
                if let linkedFile {
                    self.linkedFile = nil
                    setDocument(linkedFile.data, name: linkedFile.name, pageText: linkedFile.text, pagePhoto: linkedFile.photo)
                }
            } content: {
                PatternLinkSheet { file in
                    linkedFile = file
                }
            }
            .fullScreenCover(isPresented: $showDocumentPreview) {
                if let documentData {
                    PatternReader(data: documentData, title: name.isEmpty ? (documentName ?? "Pattern") : name)
                }
            }
            .sheet(item: $patternReview) { review in
                PatternFillReview(
                    pattern: review.pattern,
                    photo: review.photo,
                    photoIsFirstPage: review.photoIsFirstPage,
                    // PDF first pages stay in the file — don't copy them into pattern photos
                    allowsAddingPhoto: !review.photoIsFirstPage && review.photo != nil,
                    suggestsPhoto: images.isEmpty && !review.photoIsFirstPage
                ) { pattern, fields, includePhoto in
                    let photo = includePhoto && !review.photoIsFirstPage ? review.photo : nil
                    applyScannedPattern(pattern, fields: fields, photo: photo)
                }
            }
        }
        .interactiveDismissDisabled(hasChanges || isSaving)
    }
    
    // MARK: - Pattern file
    
    @ViewBuilder
    private var documentSection: some View {
        Section {
            if let documentData {
                Button {
                    showDocumentPreview = true
                } label: {
                    HStack(spacing: 12) {
                        Group {
                            if let documentFirstPage {
                                Image(uiImage: documentFirstPage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(Color.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(UIColor.secondarySystemFill))
                            }
                        }
                        .frame(width: 44, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                        .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(documentName ?? "Pattern")
                                .foregroundStyle(Color.primary)
                                .lineLimit(2)
                            
                            Text("\(documentPageCount) page\(documentPageCount == 1 ? "" : "s") · \(ByteCountFormatter.string(fromByteCount: Int64(documentData.count), countStyle: .file))")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                    }
                }
                .accessibilityHint("Opens the pattern")
                
                if isReadingDocument {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Reading the pattern…")
                            .foregroundStyle(Color.secondary)
                    }
                } else {
                    Button {
                        readDocument(documentData)
                    } label: {
                        Label("Fill Form from Pattern", systemImage: "wand.and.stars")
                    }
                }
                
                Menu {
                    addDocumentButtons
                } label: {
                    Label("Replace File", systemImage: "arrow.triangle.2.circlepath")
                }
                
                Button(role: .destructive) {
                    withAnimation {
                        self.documentData = nil
                        documentName = nil
                        documentFirstPage = nil
                        documentPageCount = 0
                        documentMessage = nil
                        documentVersion = nil
                        documentChanged = true
                        documentPageText = nil
                        documentPagePhoto = nil
                    }
                } label: {
                    Label("Remove File", systemImage: "trash")
                        .foregroundStyle(Color.red)
                }
            } else {
                addDocumentButtons
            }
        } header: {
            Text("Pattern File")
        } footer: {
            if let documentMessage {
                Text(documentMessage)
            } else if documentData == nil {
                Text("Add the pattern to fill in this form for you, and to read it while working on a project. Files includes Dropbox, Google Drive, and other storage apps on your phone.")
            }
        }
    }
    
    @ViewBuilder
    private var addDocumentButtons: some View {
        Button {
            showFileImporter = true
        } label: {
            Label("Import from Files", systemImage: "doc.badge.plus")
        }
        
        Button {
            showPhotoPicker = true
        } label: {
            Label("Choose from Photos", systemImage: "photo.on.rectangle")
        }
        
        Button {
            showLinkImport = true
        } label: {
            Label("Import from Link", systemImage: "link")
        }
        
        if DocumentScanner.isSupported {
            Button {
                showDocumentScanner = true
            } label: {
                Label("Scan Paper Pattern", systemImage: "doc.viewfinder")
            }
        }
    }
    
    private func setDocument(_ data: Data, name fileName: String, pageText: PatternText? = nil, pagePhoto: UIImage? = nil) {
        withAnimation {
            documentData = data
            documentName = fileName
            documentFirstPage = nil
            documentPageCount = PatternFile.pageCount(of: data)
            documentMessage = nil
            documentVersion = UUID()
            documentChanged = true
            documentPageText = pageText
            documentPagePhoto = pagePhoto
        }
        
        readDocument(data, fileName: fileName)
    }
    
    private func readDocument(_ data: Data, fileName: String? = nil) {
        guard !isReadingDocument else { return }
        isReadingDocument = true
        documentMessage = nil
        
        let pageText = documentPageText
        let pagePhoto = documentPagePhoto
        
        Task {
            let text : PatternText
            if let pageText {
                text = pageText
            } else {
                text = await PatternTextExtractor.extract(from: data)
            }
            
            let scanned = PatternParser.parse(text, fileName: fileName ?? documentName)
            
            // Preview only — a PDF page is never added as a pattern photo
            let preview: UIImage?
            if let pagePhoto {
                preview = pagePhoto
            } else {
                preview = await PatternFile.firstPageImage(of: data)
            }
            
            isReadingDocument = false
            
            if scanned.isEmpty {
                documentMessage = "No pattern details could be found in this file, but it will still be saved to read while you work."
            } else {
                patternReview = PatternReviewItem(
                    pattern: scanned,
                    photo: preview,
                    photoIsFirstPage: pagePhoto == nil
                )
            }
        }
    }
    
    private func applyScannedPattern(_ scanned: ScannedPattern, fields: Set<PatternField>, photo: UIImage?) {
        if fields.contains(.type), let type = scanned.type {
            patternType = type
        }
        
        if fields.contains(.name), let scannedName = scanned.name {
            name = scannedName
        }
        
        if fields.contains(.designer), let scannedDesigner = scanned.designer {
            designer = scannedDesigner
        }
        
        if fields.contains(.items) {
            items = merged(items, adding: scanned.items.map { PatternItemField(item: $0) }, placeholder: { $0.item == .none }, same: { $0.item == $1.item && $0.item != .other })
        }
        
        if fields.contains(.tools) {
            crochetHookSizes = merged(crochetHookSizes, adding: scanned.hooks.map { Hook(hook: $0) }, placeholder: { $0.hook == .none }, same: { $0.hook == $1.hook })
            knittingNeedleSizes = merged(knittingNeedleSizes, adding: scanned.needles.map { Needle(needle: $0) }, placeholder: { $0.needle == .none }, same: { $0.needle == $1.needle })
        }
        
        if fields.contains(.yarn) {
            var yarn = recWeightAndYardages.first ?? WeightAndYardageData(parent: WeightAndYardageParent.pattern)
            
            if let weight = scanned.weight {
                yarn.weight = weight
            }
            
            if let unit = scanned.unitOfMeasure {
                yarn.unitOfMeasure = unit
            }
            
            if let yardage = scanned.yardagePerSkein {
                yarn.yardage = yardage
            }
            
            if let grams = scanned.gramsPerSkein {
                yarn.grams = grams
            }
            
            if let total = scanned.totalLength {
                yarn.hasExactLength = 1
                yarn.length = total
            } else if let skeins = scanned.skeins {
                yarn.hasExactLength = 0
                yarn.skeins = skeins
                yarn.length = yarn.yardage.map { $0 * skeins }
            }
            
            if recWeightAndYardages.isEmpty {
                recWeightAndYardages = [yarn]
            } else {
                recWeightAndYardages[0] = yarn
            }
        }
        
        if fields.contains(.size) {
            oneSize = scanned.oneSize
            
            if let size = scanned.intendedSize {
                intendedSize = size
            }
        }
        
        if fields.contains(.techniques) {
            techniques = merged(techniques, adding: scanned.techniques.map { TechniqueItem(technique: $0) }, placeholder: { $0.technique == .none }, same: { $0.technique == $1.technique })
        }
        
        if fields.contains(.notions) {
            let found = scanned.notions.map { NotionItem(notion: $0) } + scanned.otherNotions.map { NotionItem(notion: .other, description: $0) }
            notions = merged(notions, adding: found, placeholder: { $0.notion == .none }, same: { $0.notion == $1.notion && $0.description.lowercased() == $1.description.lowercased() })
        }
        
        if fields.contains(.gauge), let gauge = scanned.gauge, !notes.contains(gauge) {
            notes = notes.isEmpty ? "Gauge: \(gauge)" : notes + "\n\nGauge: \(gauge)"
        }
        
        if let photo {
            images.append(ImageData(image: photo))
        }
    }
    
    /// Adds what isn't there yet, dropping the empty "--" row the form starts with
    private func merged<T>(_ current: [T], adding new: [T], placeholder: (T) -> Bool, same: (T, T) -> Bool) -> [T] {
        guard !new.isEmpty else { return current }
        
        var result = current.filter { !placeholder($0) }
        for item in new where !result.contains(where: { same($0, item) }) {
            result.append(item)
        }
        
        return result
    }
    
    private func techniqueList(for type: PatternType) -> [PatternTechnique] {
        switch type {
        case .crochet:  return PatternUtils.shared.crochetTechniques()
        case .knit:     return PatternUtils.shared.knitTechniques()
        case .tunisian: return PatternUtils.shared.tunisianTechniques()
        }
    }
    
    private func save() {
        guard !isSaving else { return }
        
        hideKeyboard()
        isSaving = true
        
        Task { @MainActor in
            encodedPhotos = await StoredImage.encodeNewPhotos(images)
            if documentChanged, let documentData {
                documentThumbnail = await PatternFile.coverThumbnailData(of: documentData)
            }
            createOrUpdatePattern()
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
            guard let newPattern = persistPattern(pattern: patternToEdit == nil ? Pattern(context: managedObjectContext) : patternToEdit!) else {
                isSaving = false
                saveFailed = true
                return
            }
            
            if onAdd != nil {
                onAdd!(newPattern)
            } else {
                hideKeyboard()
                dismiss()
            }
        }
    }
    
    func persistPattern(pattern : Pattern) -> Pattern? {
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
                    // Rotated photos keep their ID but are saved as new, so match on the saved photo itself
                    if !images.contains(where: {element in element.existingItem == item.existingItem}) {
                        managedObjectContext.delete(item.existingItem!)
                    }
                }
            }
        }
        
        // weightAndYardages
        let weightAndYardageArray: [WeightAndYardage] = recWeightAndYardages.enumerated().map { (index, element) in
            let data = element
            
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
                return StoredImage.from(data: element, order: index, context: managedObjectContext, encodedPhotos: encodedPhotos)
            }
            
            pattern.images = NSSet(array: storedImages)
            StoredImage.invalidateThumbnailCache()
        }
        
        if documentChanged {
            if let documentData {
                let document = pattern.document ?? PatternDocument(context: managedObjectContext)
                // A new ID for a replaced file so its old cover isn't shown from the cache
                document.id = UUID()
                document.data = documentData
                document.fileName = documentName
                document.lastPage = 0
                document.pageCount = Int16(clamping: documentPageCount)
                document.thumbnail = documentThumbnail
                pattern.document = document
            } else if let document = pattern.document {
                managedObjectContext.delete(document)
            }
        }
        
        guard PersistenceController.shared.save() else { return nil }
        
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
