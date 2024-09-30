//
//  YarnList.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI

let tabs : [YarnTab] = [YarnTab.active, YarnTab.archived]

struct YarnList: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Internal state trackers
    @State var searchText: String = ""
    @State private var showAddYarnForm : Bool = false
    @State private var showFilterScreen : Bool = false
    @State private var toast: Toast? = nil
    @State private var selectedSortOption: SortOption = .nameAscending
    @State private var selectedColors: [NamedColor] = []
    @State private var selectedWeights: [Weight] = []
    @State private var selectedTab: Int = 0
    @State private var sockSet: Int = -1
    @State private var showConfirmationDialog : Bool = false
    @State private var yarnToEdit : Yarn? = nil
    @State private var yarnToDelete : Yarn? = nil
    
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "Name Ascending"
        case nameDescending = "Name Descending"
        
        var id: String { rawValue }
    }
    
    @FetchRequest(
        entity: Yarn.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Yarn.name, ascending: true)] // Optional: Sort by name
    ) private var allYarns: FetchedResults<Yarn>
    
    private var uniqueDyers: [String] {
        // Extract dyers and remove duplicates
        let dyers = Set(allYarns.compactMap { $0.dyer })
        return Array(dyers).sorted() // Optional: Sort the list of dyers
    }
    
    // Computed property for the count of filtered yarns
    private var filteredYarnCount: Int {
        filteredYarn.count
    }
    
    var filteredSuggestions: [String] {
        guard !searchText.isEmpty else { return [] }
        return uniqueDyers.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    private var filteredFetchRequest = FetchRequest<Yarn>(
        sortDescriptors: [SortDescriptor(\.name)],
        predicate: NSPredicate(value: true),
        animation: .default
    )
    
    // Computed property to get all the yarn with an optional searchText
    private var filteredYarn: FetchedResults<Yarn> {
        
        // Apply sorting based on the selected option
        switch selectedSortOption {
            case .nameAscending:
                filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Yarn.name, ascending: true)]
            case .nameDescending:
                filteredFetchRequest.wrappedValue.nsSortDescriptors = [NSSortDescriptor(keyPath: \Yarn.name, ascending: false)]
        }
        
        var predicates: [NSPredicate] = []
        if searchText != "" {
            var searchPredicate = [NSPredicate(format: "name CONTAINS[c] %@", searchText)]
            searchPredicate.append(NSPredicate(format: "dyer CONTAINS[c] %@", searchText))
            
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicate)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for color filter
        if !selectedColors.isEmpty {
            let colorPredicates = selectedColors.map { color in
                NSPredicate(format: "ANY colors.name = %@", color.name)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for weight filter
        if !selectedWeights.isEmpty {
            let weightPredicates = selectedWeights.map { weight in
                NSPredicate(format: "ANY weight = %@", weight.rawValue)
            }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: weightPredicates)
            predicates.append(compoundPredicate)
        }
        
        // Apply predicate for sock set
        if sockSet != -1 {
            // sock sets only
            if sockSet == 1 {
                predicates.append(NSPredicate(format: "isSockSet = %@", true as NSNumber))
            } else {
                // no sock sets
                let noSockSetsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "isSockSet == %@", NSNumber(value: false)),
                    NSPredicate(format: "isSockSet == nil")
                ])
                predicates.append(noSockSetsPredicate)
            }
        }
        
        switch(tabs[selectedTab]) {
        case .active:
            let activePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
                NSPredicate(format: "isArchived == nil")
            ])
            predicates.append(activePredicate)
        case .archived:
            predicates.append(NSPredicate(format: "isArchived = %@", true as NSNumber))
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return filteredFetchRequest.wrappedValue
    }
    
    var body: some View {
        NavigationStack {
            // Custom Tab Bar
            HStack {
                ForEach(0..<tabs.count) { index in
                    Button(action: {
                        withAnimation {
                            selectedTab = index
                        }
                    }) {
                        Spacer()
                        
                        Text(tabs[index].rawValue)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(selectedTab == index ? Color(hex: "#36727E") : .gray)
                            .frame(height: 30)
                        
                        Spacer()
                    }
                }
            }
            .overlay(
                // Sliding underline
                GeometryReader { geometry in
                    let buttonWidth = geometry.size.width / CGFloat(tabs.count)
                    
                    Rectangle()
                        .fill(Color(hex: "#36727E"))
                        .frame(width: buttonWidth, height: 2)
                        .offset(x: CGFloat(selectedTab) * buttonWidth, y: 33)
                        .animation(.easeInOut, value: selectedTab)
                }
            )
            .padding(.bottom, 5)
            
            
            HStack {
                if !selectedColors.isEmpty || searchText != "" || !selectedWeights.isEmpty || sockSet != -1 {
                    LazyVGrid(columns: [.init(.adaptive(minimum:120))], spacing: 10) {
                        ForEach(selectedWeights, id: \.self) { weight in
                            Button(action: {
                                if let index = selectedWeights.firstIndex(where: { $0 == weight }) {
                                    selectedWeights.remove(at: index)
                                }
                            }) {
                                HStack() {
                                    Spacer()
                                    
                                    Text(weight.rawValue)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(8)
                                .background(.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                        .stroke(Color.gray, lineWidth: 0.3)
                                )
                            }
                        }
                        
                        if sockSet != -1 {
                            Button(action: {
                                sockSet = -1
                            }) {
                                HStack() {
                                    Spacer()
                                    
                                    Text(sockSet == 1 ? "Sock Sets Only" : "No Sock Sets")
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(8)
                                .background(.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                        .stroke(Color.gray, lineWidth: 0.3)
                                )
                            }
                        }
                        
                        ForEach(selectedColors) { colorGroup in
                            Button(action: {
                                if let index = selectedColors.firstIndex(where: { $0.id == colorGroup.id }) {
                                    selectedColors.remove(at: index)
                                }
                            }) {
                                HStack() {
                                    Spacer()
                                    
                                    // Diamond-shaped color view
                                    Circle()
                                        .fill(Color(uiColor : colorGroup.colors[0]))
                                        .frame(width: 13, height: 13)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 0.5) // Black border with width
                                        )
                                    
                                    Text(colorGroup.name)
                                        .foregroundColor(.gray)
                                        .fixedSize()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding(8)
                                .background(.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                                        .stroke(Color.gray, lineWidth: 0.3)
                                )
                            }
                        }
                        
                        Button(action: {
                            showFilterScreen = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    .padding()
                }
                
            }
            
            ScrollView {
                if filteredYarn.isEmpty {
                    ZStack {
                        // Reserve space matching the scroll view's frame
                        Spacer().containerRelativeFrame([.horizontal, .vertical])
                        
                        VStack {
                            Image("momo") // Replace with your image's name
                                .resizable() // If you want to adjust the size
                                .scaledToFit() // Adjust the image's aspect ratio
                                .frame(width: 300, height: 125) // Set desired frame size
                            
                            Text("Looking for yarn is tough work! Time for a nap")
                                .font(.title)
                                .bold()
                                .multilineTextAlignment(.center)
                            
                            VStack {
                                Text("We couldn't find anything.")
                                    .font(.body)
                                
                                HStack(spacing: 0) {
                                    Text("Please")
                                    
                                    Button(action: {
                                        showAddYarnForm = true
                                    }) {
                                        Text(" add some yarn ")
                                            .foregroundColor(.blue) // Customize the color to look like a link
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                                    .padding(0)
                                    
                                    Text("or modify your search.")
                                        .font(.body)
                                }
                                
                            }
                            .padding(.top, 5)
                        }
                        .padding()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum:150))], spacing: 5) {
                            ForEach(filteredYarn) { yarn in
                                NavigationLink(
                                    destination: YarnInfo(yarn: yarn, toast : $toast, selectedTab : $selectedTab)
                                ) {
                                    VStack {
                                        ImageCarousel(images: .constant(yarn.uiImages), smallMode: true)
                                            .contextMenu {
                                                Button {
                                                    yarnToEdit = yarn
                                                } label: {
                                                    Label("Edit", systemImage : "pencil")
                                                }
                                                
                                                Button {
                                                    YarnUtils.shared.toggleYarnArchived(at: yarn)
                                                    
                                                    toast = Toast(style: .success, message: "Successfully \(yarn.isArchived ? "" : "un")archived yarn")
                                                } label: {
                                                    Label(yarn.isArchived ? "Unarchive" : "Archive", systemImage : yarn.isArchived ? "tray.and.arrow.up" : "tray.and.arrow.down")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    yarnToDelete = yarn
                                                    showConfirmationDialog = true
                                                } label: {
                                                    Label("Delete", systemImage : "trash")
                                                }
                                            }
                                            .cardBackground()
                                        
                                        
                                        Text(yarn.name ?? "No Name")
                                            .foregroundStyle(Color.black)
                                            .bold()
                                        
                                        Text(yarn.dyer ?? "N/A")
                                            .foregroundStyle(Color.gray)
                                            .font(.caption)
                                            .bold()
                                    }
                                    .padding(.horizontal, 7)
                                    
                                }
                            
                            }
                        }
                    }
                    .padding(.vertical, 13)
                    .padding(.horizontal, 5)
                }
                
            }
            .navigationTitle("My Stash")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterScreen = true
                    }) {
                        Image(systemName: "slider.horizontal.3") // Use a system icon
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddYarnForm = true
                    }) {
                        Image(systemName: "plus") // Use a system icon
                            .imageScale(.large)
                    }
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by Name or Dyer...",
            suggestions: {
                ForEach(filteredSuggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion).padding(.leading, 5)
                }
            }
        )
        .onChange(of: searchText) {
            if searchText.isEmpty {
                searchText = ""
            }
        }
        .popover(isPresented: $showFilterScreen) {
            FilterYarn(
                showSheet : $showFilterScreen,
                selectedColors: $selectedColors,
                selectedWeights: $selectedWeights,
                sockSet : $sockSet,
                filteredYarnCount: filteredYarnCount
            )
            .preferredColorScheme(.light) // Force light mode
        }
        .fullScreenCover(isPresented: $showAddYarnForm) {
            AddOrEditYarnForm(toast : $toast, yarnToEdit : yarnToEdit)
                .preferredColorScheme(.light) // Force light mode
        }
        .confirmationDialog(
            "Are you sure you want to delete this yarn?",
            isPresented: $showConfirmationDialog,
            titleVisibility: .visible
        ) {
            if let yarnToDelete = yarnToDelete {
                Button("Delete", role: .destructive) {
                    print("about to delete yarn", yarnToDelete.name)
                    YarnUtils.shared.removeYarn(at: yarnToDelete, with: managedObjectContext)
                    
                    toast = Toast(style: .success, message: "Successfully deleted \(yarnToDelete.name)!")
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .toastView(toast: $toast)
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 4)
    }
}
