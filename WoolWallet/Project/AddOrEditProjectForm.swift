//
//  AddOrEditProjectForm.swift
//  WoolWallet
//
//  Created by Mac on 10/23/24.
//

import Foundation
import SwiftUI

struct ProjectPairing : Equatable {
    var patternWeightAndYardageId : UUID
    var yarnWeightAndYardage : WeightAndYardage
}

struct AddOrEditProjectForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    var projectToEdit: Project?
    var preSelectedPattern: Pattern?
    var preSelectedPairings: [ProjectPairing]
    var onAdd: ((Project) -> Void)?
    var yarnSuggestions : [YarnSuggestion] = []
    
    // Form fields
    @State private var notes   : String = ""
    @State private var projectPairing : [ProjectPairing] = []
    @State private var pattern : Pattern? = nil
    @State private var browsingPattern : Bool = false
    @State private var browsingYarn : Bool = false
    @State private var yarnBrowsingWeight : Weight? = nil
    @State private var patternWAndYIdBrowsingFor : UUID? = nil
    
    init(
        projectToEdit : Project?,
        preSelectedPattern : Pattern?,
        preSelectedPairings : [ProjectPairing] = [],
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
                        HStack {
                            VStack {
                                let itemDisplay =
                                PatternUtils.shared.getItemDisplay(
                                    for: pattern.patternItems.isEmpty ? nil : pattern.patternItems.first?.item
                                )
                                
                                if itemDisplay.custom {
                                    Image(itemDisplay.icon)
                                        .iconCircle(background: itemDisplay.color, xl: true)
                                } else {
                                    Image(systemName: itemDisplay.icon)
                                        .iconCircle(background: itemDisplay.color, xl: true)
                                }
                                
                                Text(pattern.type!)
                                    .font(.caption)
                            }
                            
                            
                            Spacer()
                            
                            
                            VStack(alignment: .center) {
                                Text(pattern.name!)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.primary)
                                    .font(.title3)
                                    .bold()
                                
                                Text(pattern.designer!)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.footnote)
                                    .bold()
                                
                                Spacer()
                                
                                Text(
                                    PatternUtils.shared.joinedItems(patternItems: pattern.patternItems)
                                )
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                
                                Spacer()
                                
                                if pattern.oneSize != 0 {
                                    Text("One Size")
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.caption)
                                } else if pattern.intendedSize != nil {
                                    Text("Intended size: \(pattern.intendedSize!)")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
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
                        let pairing : ProjectPairing? = projectPairing.first(where: {$0.patternWeightAndYardageId == wAndY.id}) ?? nil
                        
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
                                
                                if yarn != nil {
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
                                    
                                    let length = wAndY.exactLength != nil && wAndY.exactLength! > 0
                                    ? "\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndY.exactLength!)) ?? "1") \(unit)"
                                    : (wAndY.approximateLength != nil && wAndY.approximateLength! > 0
                                       ?"~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: wAndY.approximateLength!)) ?? "1") \(unit)"
                                       : ""
                                    )
                                    
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
                            if let yarn = yarn {
                                HStack {
                                    VStack {
                                        ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
                                            .frame(width: 75, height: 100)
                                        
                                        if yarn.isSockSet {
                                            Text("Sock Set")
                                                .font(.caption)
                                            
                                            switch yarnWandY?.order {
                                            case 0: Text("Main Skein").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                            case 1: Text("Mini Skein").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                            case 2: Text("Mini #2").font(.caption).foregroundStyle(Color(UIColor.secondaryLabel))
                                            default: EmptyView()
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .center) {
                                        Text(yarn.name!)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(Color.primary)
                                            .bold()
                                        
                                        Text(yarn.dyer!)
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                            .font(.caption)
                                            .bold()
                                        
                                        Spacer()
                                        
                                        let unit = yarnWandY!.unitOfMeasure!.lowercased()
                                        
                                        
                                        if yarnWandY!.exactLength > 0 {
                                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: yarnWandY!.exactLength)) ?? "1") \(unit)")
                                                .font(.title3)
                                                .foregroundStyle(Color.primary)
                                        } else {
                                            Text("~\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: yarnWandY!.approxLength)) ?? "1") \(unit)")
                                                .font(.title3)
                                                .foregroundStyle(Color.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        if yarnWandY!.yardage > 0 && yarnWandY!.grams > 0 {
                                            Text("\(GlobalSettings.shared.numberFormatter.string(from: NSNumber(value: yarnWandY!.yardage)) ?? "") \(unit) / \(yarnWandY!.grams) grams")
                                                .font(.caption)
                                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                        }
                                        
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            } else {
                                Button {
                                    browsingYarn = true
                                    yarnBrowsingWeight = wAndY.weight
                                    patternWAndYIdBrowsingFor = wAndY.id
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
                                
                                if !yarnSuggestions.isEmpty {
                                    if let suggestion : YarnSuggestion = yarnSuggestions.first(where: {$0.patternWAndY.id == wAndY.id}) {
                                        if !suggestion.suggestedWAndY.isEmpty {
                                            YarnSuggestionCollapsible(
                                                weightAndYardage: wAndY.existingItem!,
                                                matchingWeightAndYardage: suggestion.suggestedWAndY,
                                                allowEdits : false,
                                                forProject: true,
                                                openByDefault : true,
                                                projectPairing: $projectPairing
                                            )
                                            .padding()
                                            .customFormSection(background: Color.accentColor.opacity(0.1))
                                           
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
                                            projectPairing: $projectPairing
                                         
                                        )
                                        .padding()
                                        .customFormSection(background: Color.accentColor.opacity(0.1))
                                    }
                                }
                            }
                        }
                    }
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
                        Text(projectToEdit == nil ? "Add" : "Save")
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
                    preSelectedWeightFilter : yarnBrowsingWeight != nil ? [yarnBrowsingWeight!] : [],
                    projectPairing : $projectPairing,
                    patternWAndYIdBrowsingFor : patternWAndYIdBrowsingFor
                )
            }
        }
    }
    
    private func createOrUpdatePattern() {
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
        project.notes = notes
        
        PersistenceController.shared.save()
        
        return project
    }
}

