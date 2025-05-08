//
//  YarnInfo.swift
//  WoolWallet
//
//  Created by Mac on 3/15/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternSuggestion {
    var yarnWAndY : WeightAndYardage
    var suggestedWAndY : [WeightAndYardage] = []
}

struct DetailProp : Hashable {
    var id : String { UUID().uuidString }
    
    var text : String
    var icon : String
    var useImage : Bool = false
}

struct YarnInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext

    
    @ObservedObject var yarn : Yarn
    @Binding var selectedTab: YarnTab
    @Binding var browseMode : Bool
    @Binding var projectPairing : [ProjectPairingItem]
    var patternWAndYBrowsingFor : WeightAndYardage?
    var isNewYarn : Bool
    var isPopover : Bool
    
    init(
        yarn: Yarn,
        selectedTab : Binding<YarnTab> = .constant(YarnTab.active),
        browseMode: Binding<Bool> = .constant(false),
        projectPairing : Binding<[ProjectPairingItem]> = .constant([]),
        patternWAndYBrowsingFor : WeightAndYardage? = nil,
        isNewYarn : Bool = false,
        isPopover : Bool = false
    ) {
        self.yarn = yarn
        self._selectedTab = selectedTab
        self._browseMode = browseMode
        self._projectPairing = projectPairing
        self.patternWAndYBrowsingFor = patternWAndYBrowsingFor
        self.isNewYarn = isNewYarn
        self.isPopover = isPopover
    }
    
    // Internal state trackers
    @State private var showEditYarnForm        : Bool = false
    @State private var yarnInfoToast           : Toast? = nil
    @State private var showDeleteConfirmation  : Bool = false
    @State private var showChoosePatternDialog : Bool = false
    @State private var showChooseSkeinDialog   : Bool = false
    @State private var showAddProjectForm      : Bool = false
    @State private var animateCheckmark        : Bool = false
    @State private var patternSuggestions      : [PatternSuggestion] = []
    @State private var favoritedPatterns       : [FavoritePairing] = []
    @State private var patternWAndYForProject  : WeightAndYardage? = nil
    @State private var newProject              : Project? = nil
    @State private var displayedProject        : Project? = nil
    
    var projects: [Project] {
        return YarnUtils.shared.getProjects(for: yarn, in: managedObjectContext)
    }
    
    var yarnProperties: [DetailProp] {
        var props : [DetailProp] = []
        
        if yarn.isArchived {
            props.append(DetailProp(text: "Archived", icon: "tray.and.arrow.down"))
        }
        
        if yarn.isCaked {
            props.append(DetailProp(text: "Caked", icon: "birthday.cake"))
        }
        
        if yarn.isSockSet {
            props.append(DetailProp(text: "Sock Set", icon: "shoeprints.fill"))
        }
        
        if yarn.isMini {
            props.append(DetailProp(text: "Mini", icon: "arrow.down.right.and.arrow.up.left"))
        }
        
        if yarn.colorType == ColorType.variegated.rawValue {
            props.append(DetailProp(text: "Variegated", icon: "swirl.circle.righthalf.filled"))
        } else if yarn.colorType == ColorType.tonal.rawValue {
            props.append(DetailProp(text: "Tonal", icon: "circle.fill"))
        }
                         
        props.append(DetailProp(text: "\(projects.count == 1 ? "1 project" : "\(projects.count) projects")", icon: "hammer"))
                      
        return props
    }
    
    var body: some View {
        VStack {
            if isNewYarn || isPopover {
                NewItemHeader(onClose: { dismiss() })
            }
            
            ScrollView {
                if isNewYarn {
                    VStack {
                        Label("", systemImage: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#008000")) // Set text color
                            .symbolEffect(.bounce, value: animateCheckmark)
                            .padding()
                        
                        Text("Successfully created yarn")
                            .font(.title2)
                        
                        Text("Now get crafting!")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .onAppear {
                        animateCheckmark.toggle()
                    }
                }
                
                ConditionalStack() {
                    ImageCarousel(images : .constant(yarn.uiImages))
                    
                    LazyVStack {
                        VStack {
                            Text(yarn.name ?? "N/A").bold().font(.largeTitle).foregroundStyle(Color.primary).multilineTextAlignment(.center)
                            
                            Text(yarn.dyer ?? "N/A").bold().foregroundStyle(Color(UIColor.secondaryLabel))
                        }
                        
                        InfoCapsules(detailProps: yarnProperties)
                        
                        VStack {
                            InfoCard() {
                                HStack {
                                    Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                                    Spacer()
                                    Text(yarn.weightAndYardageItems.first?.weight.rawValue ?? "N/A")
                                        .font(.headline).bold().foregroundStyle(Color.primary)
                                }
                            }
                            
                            ForEach(yarn.weightAndYardageArray, id: \.id) { wAndY in
                                if wAndY.originalLength != wAndY.currentLength {
                                    InfoCard() {
                                        VStack {
                                            HStack {
                                                Text("Original Length").foregroundStyle(Color(UIColor.secondaryLabel))
                                                Spacer()
                                                Text("\(wAndY.isExact ? "" : "~")\(wAndY.originalLength.formatted) \(wAndY.unitOfMeasure!.lowercased())")
                                                    .font(.headline).bold().foregroundStyle(Color.primary)
                                            }
                                            .yarnDataRow()
                                            
                                            Divider()
                                            
                                            HStack {
                                                Text("Original Skeins").foregroundStyle(Color(UIColor.secondaryLabel))
                                                Spacer()
                                                Text(wAndY.originalSkeins.formatted)
                                                    .font(.headline).bold().foregroundStyle(Color.primary)
                                            }
                                            .yarnDataRow()
                                        }
                                        
                                    }
                                }
                                    
                                ViewWeightAndYardage(
                                    weightAndYardage: wAndY,
                                    isSockSet: yarn.isSockSet,
                                    totalCount: yarn.weightAndYardageArray.count
                                )
                                
                                if let suggestion : PatternSuggestion = patternSuggestions.first(where: {$0.yarnWAndY.id == wAndY.id}) {
                                    PossiblePatterns(
                                        patternSuggestion : suggestion,
                                        favoritedPatterns : $favoritedPatterns
                                    )
                                }
                            }
                            
                            if !yarn.compositionItems.isEmpty {
                                InfoCard(
                                    header : {
                                        HStack {
                                            Spacer()
                                            Text("Composition")
                                            Spacer()
                                        }
                                    }
                                ) {
                                    VStack {
                                        CompositionChart(composition: yarn.compositionItems, smallMode: true)
                                        CompositionText(composition: yarn.compositionItems)
                                    }
                                }
                            }
                            
                            if projects.count > 0 {
                                Text("Project\(projects.count > 1 ? "s" : "")")
                                    .infoCardHeader()
                                
                                SimpleHorizontalScroll(count: projects.count, halfWidthInLandscape : true) {
                                    ForEach(projects, id : \.id) { project in
                                        ProjectPreview(
                                            project: project,
                                            displayedProject: $displayedProject,
                                            yarnId : yarn.id,
                                            disableOnTap : isPopover
                                        )
                                    }
                                }
                            }
                            
                            InfoCard(noPadding: true) {
                                ForEach(yarn.colorPickerItems, id: \.id) { colorPickerItem in
                                    VStack {
                                        colorPickerItem.color
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                            .frame(height: 35)
                                            .clipShape(
                                                .rect(
                                                    topLeadingRadius: 10,
                                                    bottomLeadingRadius: 0,
                                                    bottomTrailingRadius: 0,
                                                    topTrailingRadius: 10
                                                )
                                            )
                                        
                                        let colorName = colorPickerItem.description != "" ? colorPickerItem.description : colorPickerItem.name
                                        
                                        HStack {
                                            Text("Color").foregroundStyle(Color(UIColor.secondaryLabel))
                                            Spacer()
                                            Text(colorName).font(.headline).bold().foregroundStyle(Color.primary)
                                        }
                                        .padding(.horizontal, 15)
                                        .padding(.top, 8)
                                        .padding(.bottom, 15)
                                    }
                                }
                            }
                            
                            if yarn.notes != nil && yarn.notes != "" {
                                InfoCard() {
                                    Text(yarn.notes!)
                                        .foregroundStyle(Color.primary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    
                }
                .foregroundStyle(Color.black)
                .padding()
            }
            .toastView(toast: $yarnInfoToast)
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(yarn.name ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if browseMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button() {
                            if yarn.weightAndYardageArray.count > 1 {
                                showChooseSkeinDialog = true
                            } else {
                                // TODO: Let user choose skein
                                projectPairing.append(
                                    ProjectPairingItem(
                                        patternWeightAndYardage: patternWAndYBrowsingFor!,
                                        yarnWeightAndYardage: yarn.weightAndYardageArray.first!
                                    )
                                )
                                browseMode = false
                            }
                        } label: {
                            Text("Select")
                        }
                    }
                } else if !projectPairing.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView("")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showEditYarnForm = true
                            } label : {
                                Label("Edit", systemImage : "pencil")
                            }
                            
                            if !favoritedPatterns.isEmpty {
                                Button {
                                    if favoritedPatterns.count > 1 {
                                        showChoosePatternDialog = true
                                    } else {
                                        showAddProjectForm = true
                                    }
                                } label : {
                                    Label("Start a Project", systemImage : "hammer")
                                }
                            }
                            
                            Button {
                                YarnUtils.shared.toggleYarnArchived(at: yarn)
                                
                                selectedTab = selectedTab == YarnTab.active ? YarnTab.archived : YarnTab.active
                            } label: {
                                Label(yarn.isArchived ? "Unarchive" : "Archive", systemImage : yarn.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage : "trash")
                            }
                            
                        } label: {
                            Label("more", systemImage : "ellipsis")
                        }
                        
                    }
                }
               
            }
            .alert("Are you sure you want to delete this yarn?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm, onDismiss: getSuggestions) {
                AddOrEditYarnForm(yarnToEdit : yarn)
            }
            .sheet(isPresented: $showAddProjectForm) {
                let firstFavorite : WeightAndYardage = favoritedPatterns.first.unsafelyUnwrapped.patternWeightAndYardage!
                let patternWandY : WeightAndYardage = patternWAndYForProject == nil ? firstFavorite : patternWAndYForProject!
                
                let yarnWandY : WeightAndYardage = favoritedPatterns.first(where: {
                    $0.patternWeightAndYardage == patternWandY
                }).unsafelyUnwrapped.yarnWeightAndYardage!
                
                AddOrEditProjectForm(
                    projectToEdit: nil,
                    preSelectedPattern: patternWandY.pattern!,
                    preSelectedPairings : [ProjectPairingItem(patternWeightAndYardage: patternWandY, yarnWeightAndYardage: yarnWandY)]
                ) { addedProject in
                    // Capture the newly added project
                    newProject = addedProject
                    showAddProjectForm = false
                }
            }
            .sheet(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true, isPopover: true)
            }
            .confirmationDialog("", isPresented: $showChoosePatternDialog) {
                ForEach(favoritedPatterns, id: \.id) {element in
                    let wAndY = element.patternWeightAndYardage!
                    
                    let text = "\(wAndY.pattern!.name!) \(wAndY.pattern!.weightAndYardageArray.count > 1 ? "(Color \(PatternUtils.shared.getLetter(for: Int(wAndY.order))))" : "")"


                    Button("\(text)") {
                        patternWAndYForProject = wAndY
                        showAddProjectForm = true
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You've favorited multiple patterns. Which pattern would you like to use this yarn for?")
            }
            .confirmationDialog("", isPresented: $showChooseSkeinDialog) {
                ForEach(yarn.weightAndYardageArray, id: \.id) {element in
                    let text = "\(element.order == 0 ? "Main Skein" : (element.order == 1 ? "Mini Skein" : "Mini #2"))"
                    
                    Button("\(text)") {
                        projectPairing.append(
                            ProjectPairingItem(
                                patternWeightAndYardage: patternWAndYBrowsingFor!,
                                yarnWeightAndYardage: element
                            )
                        )
                        
                        browseMode = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This yarn has multiple skeins. Which one would you like to use for the project?")
            }
            .sheet(item: $displayedProject) { project in
                ProjectInfo(project: project, isPopover: true)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            getSuggestions()
        }
    }
    
    func getSuggestions() {
        DispatchQueue.global(qos: .background).async {
            var temp : [PatternSuggestion] = []
            
            for wAndY in yarn.weightAndYardageItems {
                temp.append(
                    PatternSuggestion(
                        yarnWAndY: wAndY.existingItem!,
                        suggestedWAndY: YarnUtils.shared.getMatchingPatterns(for: wAndY, in: managedObjectContext)
                    )
                )
            }
            
            let favorites = YarnUtils.shared.favoritedPatterns(for: yarn, in: managedObjectContext)
            
            DispatchQueue.main.async { // Ensure UI updates are performed on the main thread
                self.patternSuggestions = temp
                self.favoritedPatterns = favorites
            }
        }
    }
}

struct YarnDataRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
    }
}


