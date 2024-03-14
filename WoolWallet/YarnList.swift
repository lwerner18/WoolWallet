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
                List {
                    ForEach(filteredYarn) { yarn in
                        VStack {
                            Image(uiImage: UIImage(data: yarn.image ?? Data()) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .cardBackground()
                         
                            Text(yarn.name ?? "No Name")
                            .font(.headline)
                        }
                        .listRowSeparator(.hidden, edges: .all)
//                        .listRowInsets(EdgeInsets())
                        .padding(.all, 16)
                        
                    }
                    .onDelete(perform: removeYarn)
                }
                .listStyle(.plain)
                .navigationTitle("My Yarn")
            }
            .searchable(text: $searchText)
            .onTapGesture() {
                hideKeyboard()
            }
        }
    }
    
    func removeYarn(at offsets: IndexSet) {
        for index in offsets {
            let yarn = filteredYarn[index]
            managedObjectContext.delete(yarn)
        }
        
        PersistenceController.shared.save()
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 8)
    }
}
