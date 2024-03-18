//
//  YarnList.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI


struct YarnList: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State var searchText: String = ""
    @State private var showAddYarnForm : Bool = false
    @State private var toast: Toast? = nil
    
    private var filteredFetchRequest = FetchRequest<Yarn>(
        sortDescriptors: [SortDescriptor(\.name)],
        predicate: NSPredicate(value: true),
        animation: .default
    )
    
    private var filteredYarn: FetchedResults<Yarn> {
        if searchText == "" {
            return filteredFetchRequest.wrappedValue
        }
        
        filteredFetchRequest.wrappedValue.nsPredicate = NSPredicate(format: "name BEGINSWITH %@", searchText)
        return filteredFetchRequest.wrappedValue
    }
    
    var body: some View {
        if filteredYarn.isEmpty {
            Text("No yarn")
        } else {
            NavigationStack {
                ScrollView {
                    ForEach(0..<(filteredYarn.count + 1) / 2, id: \.self) { rowIndex in
                        HStack(alignment : .top) {
                            ForEach(0..<2, id: \.self) { columnIndex in
                                // Calculate the index of the current item
                                let itemIndex = rowIndex * 2 + columnIndex
                                
                                // Check if the itemIndex is within the bounds of the items array
                                if itemIndex < filteredYarn.count {
                                    let yarn = filteredYarn[itemIndex]
                                    
                                    NavigationLink(
                                        destination: YarnInfo(yarn: yarn, toast : $toast)
                                    ) {
                                        VStack {
                                            Image(uiImage: UIImage(data: yarn.image ?? Data()) ?? UIImage())
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 170, height: 275) // Specify the frame of the image
                                                .cardBackground()
                                            
                                            
                                            Text(yarn.name ?? "No Name")
                                                .foregroundStyle(Color.black)
                                        }
                                        .padding(.horizontal, 5)
                                    }
                                    
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 7)
                    }
                }
                .navigationTitle("My Yarn")
                .toolbar {
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
            .searchable(text: $searchText)
            .sheet(isPresented: $showAddYarnForm) {
                AddYarnForm(showSheet : $showAddYarnForm, toast : $toast)
                    .preferredColorScheme(.light) // Force light mode
            }
            .toastView(toast: $toast)
           
        }
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 8)
    }
}
