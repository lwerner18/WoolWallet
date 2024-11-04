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

struct YarnInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    
    @ObservedObject var yarn : Yarn
    @Binding var toast: Toast?
    @Binding var selectedTab: YarnTab
    @Binding var browseMode : Bool
    @Binding var projectPairing : [ProjectPairingItem]
    var patternWAndYBrowsingFor : WeightAndYardage?
    var isNewYarn : Bool?
    
    init(
        yarn: Yarn,
        toast : Binding<Toast?>,
        selectedTab : Binding<YarnTab>,
        browseMode: Binding<Bool> = .constant(false),
        projectPairing : Binding<[ProjectPairingItem]> = .constant([]),
        patternWAndYBrowsingFor : WeightAndYardage? = nil,
        isNewYarn : Bool? = false
    ) {
        self.yarn = yarn
        self._toast = toast
        self._selectedTab = selectedTab
        self._browseMode = browseMode
        self._projectPairing = projectPairing
        self.patternWAndYBrowsingFor = patternWAndYBrowsingFor
        self.isNewYarn = isNewYarn
    }
    
    // Internal state trackers
    @State private var showEditYarnForm : Bool = false
    @State private var isImageMaximized = false
    @State private var yarnInfoToast: Toast? = nil
    @State private var showDeleteConfirmation = false
    @State private var showChoosePatternDialog = false
    @State private var showChooseSkeinDialog = false
    @State private var showAddProjectForm : Bool = false
    @State private var animateCheckmark = false
    @State private var patternSuggestions : [PatternSuggestion] = []
    @State private var favoritedPatterns : [FavoritePairing] = []
    @State private var patternWAndYForProject : WeightAndYardage? = nil
    @State private var newProject             : Project? = nil
    
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    var body: some View {
        VStack {
            if isNewYarn! {
                NewItemHeader(onClose: { dismiss() })
            }
            
            ScrollView {
                if isNewYarn! {
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
                ConditionalStack(useVerticalLayout: isPortraitMode) {
                    ImageCarousel(images : .constant(yarn.uiImages))
                    
                    VStack {
                        Text(yarn.name ?? "N/A").bold().font(.largeTitle).foregroundStyle(Color.primary).multilineTextAlignment(.center)
                        
                        Text(yarn.dyer ?? "N/A").bold().foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                    
                    if yarn.isArchived || yarn.isCaked || yarn.isSockSet || yarn.isMini || yarn.colorType != nil {
                        HStack {
                            if yarn.isArchived {
                                Label("Archived", systemImage : "tray.and.arrow.down").infoCapsule()
                            }
                            
                            if yarn.isCaked {
                                Label("Caked", systemImage : "birthday.cake").infoCapsule()
                            }
                            
                            if yarn.isSockSet {
                                Label("Sock Set", systemImage : "shoeprints.fill").infoCapsule()
                            }
                            
                            if yarn.isMini {
                                Label("Mini", systemImage : "arrow.down.right.and.arrow.up.left").infoCapsule()
                            }
                            
                            if yarn.colorType == ColorType.variegated.rawValue {
                                Label("Variegated", systemImage : "swirl.circle.righthalf.filled").infoCapsule()
                            } else if yarn.colorType == ColorType.tonal.rawValue {
                                Label("Tonal", systemImage : "circle.fill").infoCapsule()
                            }
                            
                            Spacer()
                        }
                    }
                    
                    VStack {
                        InfoCard() {
                            HStack {
                                Text("Weight").foregroundStyle(Color(UIColor.secondaryLabel))
                                Spacer()
                                Text(yarn.weightAndYardageItems.first?.weight.rawValue ?? "N/A")
                                    .font(.headline).bold().foregroundStyle(Color.primary)
                            }
                        }
                        
                        if !yarn.compositionItems.isEmpty {
                            InfoCard() {
                                VStack {
                                    HStack {
                                        Text("Composition").font(.title3).bold().foregroundStyle(Color.primary)
                                        Spacer()
                                    }
                                    CompositionChart(composition: yarn.compositionItems, smallMode: true)
                                    CompositionText(composition: yarn.compositionItems).font(.title3)
                                }
                            }
                        }
                        
                        ForEach(yarn.weightAndYardageItems.indices, id: \.self) { index in
                            let item : WeightAndYardageData = yarn.weightAndYardageItems[index]
                            
                            ViewWeightAndYardage(
                                weightAndYardage: item,
                                isSockSet: yarn.isSockSet,
                                order: index,
                                totalCount: yarn.weightAndYardageItems.count
                            )
                            
                            if let suggestion : PatternSuggestion = patternSuggestions.first(where: {$0.yarnWAndY.id == item.id}) {
                                PossiblePatterns(
                                    patternSuggestion : suggestion,
                                    favoritedPatterns : $favoritedPatterns
                                )
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
                                    
                                    HStack {
                                        Text("Color").foregroundStyle(Color(UIColor.secondaryLabel))
                                        Spacer()
                                        Text(colorPickerItem.name).font(.headline).bold().foregroundStyle(Color.primary)
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.top, 8)
                                    .padding(.bottom, 15)
                                }
                            }
                        }
                        
                        if yarn.notes != "" {
                            InfoCard() {
                                Text(yarn.notes!)
                                    .frame(maxWidth: .infinity)
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
                            if yarn.weightAndYardageItems.count > 1 {
                                showChooseSkeinDialog = true
                            } else {
                                // TODO: Let user choose skein
                                projectPairing.append(
                                    ProjectPairingItem(
                                        patternWeightAndYardage: patternWAndYBrowsingFor!,
                                        yarnWeightAndYardage: yarn.weightAndYardageItems.first!.existingItem!
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
                    
                    toast = Toast(style: .success, message: "Successfully deleted yarn!")
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm, onDismiss: getSuggestions) {
                AddOrEditYarnForm(toast : $toast, yarnToEdit : yarn)
            }
            .popover(isPresented: $showAddProjectForm) {
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
            .popover(item: $newProject) { project in
                ProjectInfo(project: project, isNewProject : true)
            }
            .confirmationDialog("", isPresented: $showChoosePatternDialog) {
                ForEach(favoritedPatterns, id: \.id) {element in
                    let wAndY = element.patternWeightAndYardage!
                    
                    let text = "\(wAndY.pattern!.name!) \(wAndY.pattern!.weightAndYardageItems.count > 1 ? "(Color \(PatternUtils.shared.getLetter(for: Int(wAndY.order))))" : "")"


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
                ForEach(yarn.weightAndYardageItems, id: \.id) {element in
                    let existingItem : WeightAndYardage = element.existingItem!
                    let text = "\(existingItem.order == 0 ? "Main Skein" : (existingItem.order == 1 ? "Mini Skein" : "Mini #2"))"
                    
                    Button("\(text)") {
                        projectPairing.append(
                            ProjectPairingItem(
                                patternWeightAndYardage: patternWAndYBrowsingFor!,
                                yarnWeightAndYardage: existingItem
                            )
                        )
                        
                        browseMode = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This yarn has multiple skeins. Which one would you like to use for the project?")
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


