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
    @State private var imagesChanged           : Bool = false
    
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
                Section(
                    header : HStack {
                        Text("Pattern")
                        
                        Spacer()
                        
                        if pattern != nil {
                            Button(action: {
                                pattern = nil
                            }) {
                                Label("", systemImage : "xmark.circle")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                        }
                    }
                ) {
                    if let pattern = pattern {
                        PatternPreview(pattern: pattern)
                    } else {
                        Button {
                            browsingPattern = true
                        } label : {
                            HStack {
                                Label("Browse patterns", systemImage : "newspaper")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                            .contentShape(Rectangle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if let pattern = pattern {
                    ForEach(pattern.weightAndYardageItems.indices, id: \.self) { index in
                        let wAndY : WeightAndYardageData = pattern.weightAndYardageItems[index]
                        let header = pattern.weightAndYardageItems.count > 1 ? "Color \(PatternUtils.shared.getLetter(for: index))" : "Yarn"
                        let pairing : ProjectPairingItem? = projectPairing.first(where: {$0.patternWeightAndYardage.id == wAndY.id}) ?? nil
                        
                        let yarnWandY : WeightAndYardage? = pairing != nil ? pairing!.yarnWeightAndYardage : nil
                        let yarn = yarnWandY != nil ? yarnWandY!.yarn! : nil
                        
//                        if index > 0 {
//                            Divider()
//                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                                .listRowInsets(EdgeInsets())
//                                .background(Color(UIColor.systemGroupedBackground))
//                        }
                        Section(
                            header : HStack {
                                Text(header)
                                
                                Spacer()
                                
                                if pairing != nil {
                                    Button(action: {
                                        withAnimation {
                                            projectPairing.removeAll(where: {$0 == pairing})
                                        }
                                    }) {
                                        Label("", systemImage : "xmark.circle")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                    }
                                }
                            },
                            footer: HStack {
                                if wAndY.hasBeenEdited() {
                                    let unit = wAndY.unitOfMeasure.rawValue.lowercased()
                                    
                                    let currentLength = wAndY.existingItem!.currentLength
                                    
                                    let length = currentLength > 0
                                    ? "\(wAndY.existingItem!.isExact ? "" : "~")\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: currentLength)) ?? "1") \(unit)"
                                        : ""
                                    
                                    let yardage = wAndY.yardage != nil && wAndY.grams != nil
                                    ? "\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndY.yardage!)) ?? "") \(unit) / \(wAndY.grams!) grams"
                                    : ""
                                    
                                    let text = "\(wAndY.weight != Weight.none ? "\(wAndY.weight.getDisplay()) weight," : "") \(length != "" ? "needs \(length)," : "") \(yardage == "" ? "" : yardage)"
                                    
                                    Label(text, systemImage : "info.circle")
                                        .font(.caption2)
                                    
                                    Spacer()
                                }
                            }
                        ) {
                            if yarnWandY != nil {
                                YarnPreview(yarnWandY : yarnWandY!)
                                .padding(.vertical, 4)
                            } else {
                                Button {
                                    browsingYarn = true
                                    yarnBrowsingWeight = wAndY.weight
                                    patternWAndYBrowsingFor = wAndY.existingItem!
                                } label : {
                                    HStack {
                                        Label("Browse \(header == "Yarn" ? "yarn" : "yarn for \(header)")", systemImage : "volleyball")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                    }
                                    .contentShape(Rectangle())
                                    
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        if yarn == nil {
                            if !yarnSuggestions.isEmpty {
                                if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == wAndY.id}) {
                                    if !suggestion.suggestedWAndY.isEmpty {
                                        YarnSuggestionCollapsible(
                                            weightAndYardage: wAndY.existingItem!,
                                            matchingWeightAndYardage: suggestion.suggestedWAndY,
                                            allowEdits : false,
                                            forProject: true,
                                            openByDefault : true,
                                            title : pattern.weightAndYardageItems.count > 1
                                            ? "Color \(PatternUtils.shared.getLetter(for: Int(wAndY.existingItem!.order)))"
                                            : "Yarn Suggestions",
                                            projectPairing: $projectPairing
                                        )
                                        .listRowSeparator(.hidden)
                                        .customFormSection()
                                    }
                                }
                            } else {
                                let matchingWeightAndYardage = PatternUtils.shared.getMatchingYarns(for: wAndY, in: managedObjectContext)
                                
                                if !matchingWeightAndYardage.isEmpty {
                                    YarnSuggestionCollapsible(
                                        weightAndYardage: wAndY.existingItem!,
                                        matchingWeightAndYardage: matchingWeightAndYardage,
                                        allowEdits : false,
                                        forProject : true,
                                        openByDefault : true,
                                        title : pattern.weightAndYardageItems.count > 1
                                        ? "Color \(PatternUtils.shared.getLetter(for: Int(wAndY.existingItem!.order))) Suggestions"
                                        : "Yarn Suggestions",
                                        projectPairing: $projectPairing
                                    )
                                    .listRowSeparator(.hidden)
                                    .customFormSection()
                                }
                                
                            }
                        }
                    }
                }
                
                
                Section(header: Text(projectToEdit != nil ? "Is this project in progress or complete?" : "")) {
                    if projectToEdit != nil {
                        Picker("", selection: $statusSelection) {
                            Text("In Progress").tag(0)
                            Text("Complete").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        Toggle("In Progress", isOn: $inProgress)
                    }
                }
                
                Section(header: Text("Images")) {
                    ImageCarousel(images : $images, editMode: true, editExistingImages : projectToEdit != nil)
                        .customFormSection()
                }
                
                
                Section(header: Text("Anything else you'd like to note?")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Button(projectToEdit == nil ? "Add" : "Save", action: {
                    createOrUpdatePattern()
                })
                .disabled(pattern == nil)
            }
            .navigationTitle(projectToEdit == nil ? "New Project" : "Edit Project")
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
                        if persisting {
                            ProgressView("")
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(projectToEdit == nil ? "Add" : "Save")
                        }
                      
                    }
                    .disabled(pattern == nil)
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
        }
    }
    
    private func createOrUpdatePattern() {
        withAnimation {
            persisting = true
        }
        
        let newProject = persistProject(project: projectToEdit == nil ? Project(context: managedObjectContext) : projectToEdit!)
        
        if onAdd != nil {
            onAdd!(newProject)
        } else {
            hideKeyboard()
            dismiss()
        }
    }
    
    func persistProject(project : Project) -> Project {
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
                    if !images.contains(where: {element in element.id == item.id}) {
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
                return StoredImage.from(data: element, order: index, context: managedObjectContext)
            }
            
            project.images = NSSet(array: storedImages)
        }
    
        // pairings
        let pairings: [ProjectPairing] = projectPairing.enumerated().map { (index, element) in
            return ProjectPairing.from(data: element, context: managedObjectContext)
        }
        
        project.pairings = NSSet(array: pairings)
        
        
        PersistenceController.shared.save()
        
        return project
    }
}

