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
                        Text(yarn.name ?? "N/A").bold().font(.largeTitle)
                        
                        Text(yarn.dyer ?? "N/A").bold().foregroundStyle(Color.gray)
                    }
                    
                    if yarn.isArchived || yarn.isCaked || yarn.isSockSet {
                        HStack {
                            if yarn.isArchived {
                                Label("Archived", systemImage : "tray.and.arrow.down")
                                    .fixedSize(horizontal: true, vertical: false)
                                    .font(.callout)
                                    .padding(.vertical, 8) // Padding for the section
                                    .padding(.horizontal, 12) // Padding for the section
                                    .background(Color.white) // Background color for the section
                                    .cornerRadius(25) // Rounded corners for the section
                                    .shadow(radius: 0.5)
                            }
                            
                            if yarn.isCaked {
                                Label("Caked", systemImage : "birthday.cake")
                                    .fixedSize(horizontal: true, vertical: false)
                                    .font(.callout)
                                    .padding(.vertical, 8) // Padding for the section
                                    .padding(.horizontal, 12) // Padding for the section
                                    .background(Color.white) // Background color for the section
                                    .cornerRadius(25) // Rounded corners for the section
                                    .shadow(radius: 0.5)
                            }
                            
                            if yarn.isSockSet {
                                Label("Sock Set", systemImage : "shoeprints.fill")
                                    .fixedSize(horizontal: true, vertical: false)
                                    .font(.callout)
                                    .padding(.vertical, 8) // Padding for the section
                                    .padding(.horizontal, 12) // Padding for the section
                                    .background(Color.white) // Background color for the section
                                    .cornerRadius(25) // Rounded corners for the section
                                    .shadow(radius: 0.5)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    VStack {
                        InfoCard() {
                            HStack {
                                Text("Weight").foregroundStyle(Color.gray)
                                Spacer()
                                Text(yarn.weight ?? "N/A").font(.headline).bold()
                            }
                        }
                        
                        if !yarn.compositionItems.isEmpty {
                            InfoCard() {
                                VStack {
                                    HStack {
                                        Text("Composition").font(.title3).bold()
                                        Spacer()
                                    }
                                    CompositionChart(composition: yarn.compositionItems, smallMode: true)
                                    CompositionText(composition: yarn.compositionItems).font(.title3)
                                }
                            }
                        }
                        
                        if yarn.isSockSet {
                            Divider().padding()
                            
                            HStack {
                                Text("Main Skein").font(.title3).bold()
                                Spacer()
                            }
                        }
                        
                        ViewWeightAndYardage(
                            weightAndYardage: WeightAndYardage(
                                weight            : yarn.weight != nil ? Weight(rawValue: yarn.weight!)! : Weight.none,
                                unitOfMeasure     : yarn.unitOfMeasure != nil ? UnitOfMeasure(rawValue: yarn.unitOfMeasure!)! : UnitOfMeasure.yards,
                                length            : yarn.length != 0 ? yarn.length : nil,
                                grams             : yarn.grams != 0 ? Int(yarn.grams) : nil,
                                hasBeenWeighed    : Int(yarn.hasBeenWeighed),
                                totalGrams        : yarn.totalGrams != 0 ? Int(yarn.totalGrams) : nil,
                                skeins            : yarn.skeins,
                                hasPartialSkein   : yarn.hasPartialSkein,
                                exactLength       : yarn.exactLength,
                                approximateLength : yarn.approximateLength
                            )
                        )
                        
                        if yarn.isSockSet {
                            VStack {
                                Divider().padding()
                                
                                HStack {
                                    Text(yarn.hasTwoMinis ? "Mini #1" : "Mini").font(.title3).bold()
                                    Spacer()
                                }
                            }
                            
                            ViewWeightAndYardage(
                                weightAndYardage: WeightAndYardage(
                                    unitOfMeasure     : yarn.mini1UnitOfMeasure != nil ? UnitOfMeasure(rawValue: yarn.mini1UnitOfMeasure!)! : UnitOfMeasure.yards,
                                    length            : yarn.mini1Length != 0 ? yarn.mini1Length : nil,
                                    grams             : yarn.mini1Grams != 0 ? Int(yarn.mini1Grams) : nil,
                                    hasBeenWeighed    : Int(yarn.mini1HasBeenWeighed),
                                    totalGrams        : yarn.mini1TotalGrams != 0 ? Int(yarn.mini1TotalGrams) : nil,
                                    skeins            : yarn.mini1Skeins,
                                    hasPartialSkein   : yarn.mini1HasPartialSkein,
                                    exactLength       : yarn.mini1ExactLength,
                                    approximateLength : yarn.mini1ApproximateLength
                                )
                            )
                            
                            if yarn.hasTwoMinis {
                                VStack {
                                    Divider().padding()
                                    
                                    HStack {
                                        Text("Mini #2").font(.title3).bold()
                                        Spacer()
                                    }
                                }
                                
                                ViewWeightAndYardage(
                                    weightAndYardage: WeightAndYardage(
                                        unitOfMeasure     : yarn.mini2UnitOfMeasure != nil ? UnitOfMeasure(rawValue: yarn.mini2UnitOfMeasure!)! : UnitOfMeasure.yards,
                                        length            : yarn.mini2Length != 0 ? yarn.mini2Length : nil,
                                        grams             : yarn.mini2Grams != 0 ? Int(yarn.mini2Grams) : nil,
                                        hasBeenWeighed    : Int(yarn.mini2HasBeenWeighed),
                                        totalGrams        : yarn.mini2TotalGrams != 0 ? Int(yarn.mini2TotalGrams) : nil,
                                        skeins            : yarn.mini2Skeins,
                                        hasPartialSkein   : yarn.mini2HasPartialSkein,
                                        exactLength       : yarn.mini2ExactLength,
                                        approximateLength : yarn.mini2ApproximateLength
                                    )
                                )
                            }
                            
                            Divider().padding()
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
                                        Text("Color").foregroundStyle(Color.gray)
                                        Spacer()
                                        Text(colorPickerItem.name).font(.headline).bold()
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
                    .background(Color(UIColor.systemGray6))
                    
                }
                .foregroundStyle(Color.black)
                .padding()
            }
            .toastView(toast: $yarnInfoToast)
            // Disable bounce if the content fits (optional)
            .scrollBounceBehavior(.basedOnSize)
            //        .background(Color.black.opacity(isImageMaximized ? 0.5 : 0.0))
            //        .onTapGesture {
            //            // Allows tapping on the background to reset the focus state
            //            withAnimation {
            //                isImageMaximized = false
            //            }
            //        }
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
                            
                            dismiss()
                            
                            toast = Toast(style: .success, message: "Successfully \(yarn.isArchived ? "" : "un")archived yarn")
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
            .confirmationDialog(
                "Are you sure you want to delete this yarn?",
                isPresented: $showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    YarnUtils.shared.removeYarn(at: yarn, with: managedObjectContext)
                    
                    toast = Toast(style: .success, message: "Successfully deleted yarn!")
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showEditYarnForm) {
                AddOrEditYarnForm(toast : $toast, yarnToEdit : yarn)
                    .preferredColorScheme(.light) // Force light mode
            }
        }
        .background(Color(UIColor.systemGray6))
    }
    
    // Function to join color names with commas
    func joinedColorNames(colors : [StoredColor]) -> String {
        let colorNames = colors.map { $0.name ?? "Unknown" }
        return colorNames.joined(separator: ", ")
    }
}

struct YarnDataRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 5)
    }
}

struct InfoCard<Content: View>: View {
    var noPadding : Bool? = false
    let content: () -> Content
    
    var body: some View {
        content() // Content provided as a closure
        .padding(noPadding! ? 0 : 15) // Padding for the section
        .background(Color.white) // Background color for the section
        .cornerRadius(8) // Rounded corners for the section
        .shadow(radius: 0.5)
    }
}
