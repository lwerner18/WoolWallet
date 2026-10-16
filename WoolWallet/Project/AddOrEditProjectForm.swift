//
//  AddOrEditProjectForm.swift
//  WoolWallet
//
//  Created by Mac on 10/23/24.
//

import Foundation
import SwiftUI

struct ProjectPairingItem : Identifiable, Equatable, Hashable {
    var id : UUID = UUID()
    var patternWeightAndYardage : WeightAndYardage
    var yarnWeightAndYardage : WeightAndYardage
    var lengthUsed : Double? = nil
    var existingItem : ProjectPairing?
}

struct AddOrEditProjectForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    var projectToEdit: Project?
    var preSelectedPattern: Pattern?
    var preSelectedPairings: [ProjectPairingItem]
    var onAdd: ((Project) -> Void)?
    var yarnSuggestions : [YarnSuggestion] = []
    
    // Form fields
    @State private var notes                   : String = ""
    @State private var inProgress              : Bool = true
    @State private var projectPairing          : [ProjectPairingItem] = []
    @State private var pattern                 : Pattern? = nil
    @State private var browsingPattern         : Bool = false
    @State private var browsingYarn            : Bool = false
    @State private var yarnBrowsingWeight      : Weight? = nil
    @State private var patternWAndYBrowsingFor : WeightAndYardage? = nil
    @State private var images                  : [ImageData] = []
    @State private var statusSelection         : Int = -1
    @State private var persisting              : Bool = false
    @State private var saveFailed              : Bool = false
    @State private var encodedPhotos           : [UUID: Data] = [:]
    @State private var imagesChanged           : Bool = false
    
    @State private var initialSnapshot         : FormSnapshot? = nil
    
    private struct FormSnapshot: Equatable {
        var notes           : String
        var inProgress      : Bool
        var projectPairing  : [ProjectPairingItem]
        var pattern         : Pattern?
        var images          : [ImageData]
        var statusSelection : Int
    }
    
    private var snapshot: FormSnapshot {
        FormSnapshot(
            notes: notes,
            inProgress: inProgress,
            projectPairing: projectPairing,
            pattern: pattern,
            images: images,
            statusSelection: statusSelection
        )
    }
    
    private var hasChanges: Bool {
        initialSnapshot.map { $0 != snapshot } ?? false
    }
    
    init(
        projectToEdit : Project?,
        preSelectedPattern : Pattern?,
        preSelectedPairings : [ProjectPairingItem] = [],
        yarnSuggestions : [YarnSuggestion] = [],
        onAdd: ((Project) -> Void)? = nil
    ) {
        self.projectToEdit = projectToEdit
        self.preSelectedPattern = preSelectedPattern
        self.preSelectedPairings = preSelectedPairings
        self.yarnSuggestions = yarnSuggestions
        self.onAdd = onAdd
        
        if let preSelectedPattern = preSelectedPattern {
            _pattern = State(initialValue: preSelectedPattern)
        }
        
        if !preSelectedPairings.isEmpty {
            _projectPairing = State(initialValue: preSelectedPairings)
        }
        
        if let projectToEdit = projectToEdit {
            _notes           = State(initialValue : projectToEdit.notes ?? "")
            _images          = State(initialValue : projectToEdit.uiImages)
            _inProgress      = State(initialValue : projectToEdit.inProgress)
            _projectPairing  = State(initialValue : projectToEdit.projectPairingItems)
            _pattern         = State(initialValue : projectToEdit.pattern)
            _statusSelection = State(initialValue : projectToEdit.complete ? 1 : (projectToEdit.inProgress ? 0 : -1))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                patternSection
                
                if let pattern {
                    yarnSections(for: pattern)
                }
                
                Section {
                    if projectToEdit != nil {
                        Picker("Status", selection: $statusSelection) {
                            Text("In Progress").tag(0)
                            Text("Complete").tag(1)
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Toggle("Start in progress", isOn: $inProgress)
                    }
                } header: {
                    Text(projectToEdit != nil ? "Status" : "Getting started")
                }
                
                Section("Photos") {
                    ImageCarousel(images : $images, editMode: true, editExistingImages : projectToEdit != nil)
                        .customFormSection()
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Button(projectToEdit == nil ? "Add Project" : "Save", action: save)
                    .disabled(pattern == nil || persisting)
            }
            .navigationTitle(projectToEdit == nil ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DiscardChangesButton(hasChanges: hasChanges) {
                        dismiss()
                    }
                    .disabled(persisting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if persisting {
                        ProgressView()
                    } else {
                        Button(projectToEdit == nil ? "Add" : "Save", action: save)
                            .disabled(pattern == nil)
                    }
                }
            }
            .navigationDestination(isPresented: $browsingPattern) {
                PatternList(browseMode: $browsingPattern, browsePattern : $pattern)
            }
            .navigationDestination(isPresented: $browsingYarn) {
                YarnList(
                    browseMode: $browsingYarn, 
                    preSelectedWeightFilter : yarnBrowsingWeight != nil && yarnBrowsingWeight != Weight.none ? [yarnBrowsingWeight!] : [],
                    projectPairing : $projectPairing,
                    patternWAndYBrowsingFor : patternWAndYBrowsingFor
                )
            }
            .onChange(of: images) {
                imagesChanged = true
            }
            .onChange(of: pattern?.objectID) { previous, _ in
                // Pairings belong to the previous pattern's colorways
                if previous != nil {
                    projectPairing = []
                }
            }
            .alert("Couldn't Save", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong saving this project. Please try again.")
            }
            .onAppear {
                if initialSnapshot == nil {
                    initialSnapshot = snapshot
                }
            }
        }
        .interactiveDismissDisabled(hasChanges || persisting)
    }
    
    // MARK: - Sections
    
    private var patternSection: some View {
        Section {
            if let pattern {
                Button {
                    browsingPattern = true
                } label: {
                    PatternPreview(pattern: pattern)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Choose a different pattern")
            } else {
                Button {
                    browsingPattern = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 36, height: 36)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Choose Pattern")
                                .font(.body.bold())
                                .foregroundStyle(Color.primary)
                            
                            Text("Tap a pattern in your library to select it")
                                .font(.caption)
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                        }
                        
                        Spacer(minLength: 0)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(Color(UIColor.tertiaryLabel))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                Text("Pattern")
                
                Spacer()
                
                if pattern != nil {
                    Button("Clear") {
                        withAnimation {
                            pattern = nil
                            projectPairing = []
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .accessibilityLabel("Remove Pattern")
                }
            }
        }
    }
    
    @ViewBuilder
    private func yarnSections(for pattern: Pattern) -> some View {
        ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
            let wAndY = pattern.weightAndYardageItems[index]
            let header = pattern.weightAndYardageItems.count > 1
                ? "Color \(PatternUtils.shared.getLetter(for: index))"
                : "Yarn"
            let pairing = projectPairing.first { $0.patternWeightAndYardage.id == wAndY.id }
            let yarnWandY = pairing?.yarnWeightAndYardage
            
            Section {
                if let yarnWandY {
                    Button {
                        browsingYarn = true
                        yarnBrowsingWeight = wAndY.weight
                        patternWAndYBrowsingFor = wAndY.existingItem
                    } label: {
                        YarnPreview(yarnWandY: yarnWandY)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Choose a different yarn")
                } else {
                    Button {
                        browsingYarn = true
                        yarnBrowsingWeight = wAndY.weight
                        patternWAndYBrowsingFor = wAndY.existingItem
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "volleyball")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(header == "Yarn" ? "Choose Yarn" : "Choose Yarn for \(header)")
                                    .font(.body.bold())
                                    .foregroundStyle(Color.primary)
                                
                                Text("Browse stash or pick a suggestion below")
                                    .font(.caption)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                            }
                            
                            Spacer(minLength: 0)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                if yarnWandY == nil, let existing = wAndY.existingItem {
                    yarnSuggestions(
                        for: existing,
                        data: wAndY,
                        colorIndex: index,
                        colorCount: pattern.weightAndYardageArray.count
                    )
                }
            } header: {
                HStack {
                    Text(header)
                    
                    Spacer()
                    
                    if pairing != nil {
                        Button("Clear") {
                            withAnimation {
                                projectPairing.removeAll { $0 == pairing }
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                        .accessibilityLabel("Remove Yarn")
                    }
                }
            } footer: {
                yarnFooter(for: wAndY)
            }
        }
    }
    
    @ViewBuilder
    private func yarnSuggestions(
        for patternWAndY: WeightAndYardage,
        data: WeightAndYardageData,
        colorIndex: Int,
        colorCount: Int
    ) -> some View {
        let matches: [WeightAndYardage] = {
            if let suggestion = yarnSuggestions.first(where: { $0.patternWAndY.id == patternWAndY.id }) {
                return suggestion.suggestedWAndY
            }
            return PatternUtils.shared.getMatchingYarns(for: data, in: managedObjectContext)
        }()
        
        if !matches.isEmpty {
            YarnSuggestionCarousel(
                weightAndYardage: patternWAndY,
                matchingWeightAndYardage: matches,
                forProject: true,
                title: colorCount > 1
                    ? "Suggestions for Color \(PatternUtils.shared.getLetter(for: colorIndex))"
                    : "Suggested from stash",
                projectPairing: $projectPairing
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private func yarnFooter(for wAndY: WeightAndYardageData) -> some View {
        if wAndY.hasBeenEdited(), let existing = wAndY.existingItem {
            let unit = wAndY.unitOfMeasure.rawValue.lowercased()
            let currentLength = existing.currentLength
            let length = currentLength > 0
                ? "\(existing.isExact ? "" : "~")\(currentLength.formatted) \(unit)"
                : ""
            let yardage = wAndY.yardage != nil && wAndY.grams != nil
                ? "\(wAndY.yardage!.formatted) \(unit) / \(wAndY.grams!) grams"
                : ""
            let text = [
                wAndY.weight != Weight.none ? "\(wAndY.weight.getDisplay()) weight" : nil,
                length.isEmpty ? nil : "needs \(length)",
                yardage.isEmpty ? nil : yardage
            ].compactMap { $0 }.joined(separator: " · ")
            
            if !text.isEmpty {
                Label(text, systemImage: "info.circle")
                    .font(.caption2)
            }
        }
    }
    
    private func save() {
        guard !persisting else { return }
        
        hideKeyboard()
        persisting = true
        
        Task { @MainActor in
            encodedPhotos = await StoredImage.encodeNewPhotos(images)
            createOrUpdateProject()
        }
    }
    
    private func createOrUpdateProject() {
        guard let newProject = persistProject(project: projectToEdit == nil ? Project(context: managedObjectContext) : projectToEdit!) else {
            persisting = false
            saveFailed = true
            return
        }
        
        if onAdd != nil {
            onAdd!(newProject)
        } else {
            hideKeyboard()
            dismiss()
        }
    }
    
    func persistProject(project : Project) -> Project? {
        project.id = project.id != nil ? project.id : UUID()
        project.inProgress = statusSelection != -1 ? statusSelection == 0 : inProgress
        project.complete = statusSelection == 1
        project.notes = notes
        
        project.pattern = pattern
        
        // delete any items that we don't need anymore
        if projectToEdit != nil {
            projectToEdit?.projectPairingItems.forEach { item in
                if !projectPairing.contains(where: {element in element.id == item.id}) {
                    managedObjectContext.delete(item.existingItem!)
                }
            }
            
            if imagesChanged {
                projectToEdit?.uiImages.forEach { item in
                    // Rotated photos keep their ID but are saved as new, so match on the saved photo itself
                    if !images.contains(where: {element in element.existingItem == item.existingItem}) {
                        managedObjectContext.delete(item.existingItem!)
                    }
                }
            }
        }
        
        if project.inProgress && project.startDate == nil {
            project.startDate = Date.now
            project.endDate = nil
        }
        
        if project.complete && project.endDate == nil {
            project.endDate = Date.now
        }
        
        if imagesChanged {
            // images
            let storedImages: [StoredImage] = images.enumerated().map { (index, element) in
                return StoredImage.from(data: element, order: index, context: managedObjectContext, encodedPhotos: encodedPhotos)
            }
            
            project.images = NSSet(array: storedImages)
            // List cards may have cached a failed load from before these photos existed
            StoredImage.invalidateThumbnailCache()
        }
    
        // pairings
        let pairings: [ProjectPairing] = projectPairing.enumerated().map { (index, element) in
            return ProjectPairing.from(data: element, context: managedObjectContext)
        }
        
        project.pairings = NSSet(array: pairings)
        
        
        guard PersistenceController.shared.save() else { return nil }
        
        return project
    }
}

