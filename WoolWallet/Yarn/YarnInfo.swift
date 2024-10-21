//
//  YarnInfo.swift
//  WoolWallet
//
//  Created by Mac on 3/15/24.
//

import Foundation
import SwiftUI
import CoreData

struct YarnInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    
    @ObservedObject var yarn : Yarn
    @Binding var toast: Toast?
    @Binding var selectedTab: Int
    var isNewYarn : Bool?
    
    init(yarn: Yarn, toast : Binding<Toast?>, selectedTab : Binding<Int>, isNewYarn : Bool? = false) {
        self.yarn = yarn
        self._toast = toast
        self._selectedTab = selectedTab
        self.isNewYarn = isNewYarn
    }
    
    // Internal state trackers
    @State private var showEditYarnForm : Bool = false
    @State private var isImageMaximized = false
    @State private var yarnInfoToast: Toast? = nil
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    var body: some View {
        VStack {
            if isNewYarn! {
                // Toolbar-like header
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                .padding(.bottom, 10) // Padding around the button
                .padding(.top, 20) // Padding around the button
                .padding(.horizontal, 20) // Padding around the button
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
                    
                    if yarn.isArchived || yarn.isCaked || yarn.isSockSet {
                        HStack {
                            if yarn.isArchived {
                                Label("Archived", systemImage : "tray.and.arrow.down")
                                    .infoCapsule()
                            }
                            
                            if yarn.isCaked {
                                Label("Caked", systemImage : "birthday.cake")
                                    .infoCapsule()
                            }
                            
                            if yarn.isSockSet {
                                Label("Sock Set", systemImage : "shoeprints.fill")
                                    .infoCapsule()
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
                            ViewWeightAndYardage(
                                weightAndYardage: yarn.weightAndYardageItems[index],
                                isSockSet: yarn.isSockSet,
                                order: index,
                                totalCount: yarn.weightAndYardageItems.count
                            )
                        }
                        
                        InfoCard(noPadding: true) {
                            ForEach(yarn.colorPickerItems) { colorPickerItem in
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditYarnForm = true
                        } label : {
                            Label("Edit", systemImage : "pencil")
                        }
                        
                        Button {
                            YarnUtils.shared.toggleYarnArchived(at: yarn)
                            
                            selectedTab = selectedTab == 0 ? 1 : 0
                        } label: {
                            Label(yarn.isArchived ? "Unarchive" : "Archive", systemImage : yarn.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                        }
                        
                        Button(role: .destructive) {
                            showConfirmationDialog = true
                        } label: {
                            Label("Delete", systemImage : "trash")
                        }
                        
                    } label: {
                        Label("more", systemImage : "ellipsis")
                    }
                }
            }
            .alert("Are you sure you want to delete this yarn?", isPresented: $showConfirmationDialog) {
                Button("Delete", role: .destructive) {
                    YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
                    
                    toast = Toast(style: .success, message: "Successfully deleted yarn!")
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm) {
                AddOrEditYarnForm(toast : $toast, yarnToEdit : yarn)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct YarnDataRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
    }
}


