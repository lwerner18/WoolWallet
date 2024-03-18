//
//  YarnInfo.swift
//  WoolWallet
//
//  Created by Mac on 3/15/24.
//

import Foundation
import SwiftUI

struct YarnInfo: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var toast: Toast?
    
    @State private var showActionSheet : Bool = false
    let yarn : Yarn
    
    var actionSheet: ActionSheet {
        ActionSheet(
            title: Text("Actions"),
            buttons: [
                .default(Text("Edit")) {
                    // Handle Option 1
                    print("Option 1 selected")
                },
                .destructive(Text("Delete")) {
                    removeYarn(at: yarn)
                    toast = Toast(style: .success, message: "Successfully deleted yarn!")
                    dismiss()
                },
                .cancel()
            ]
        )
    }
    
    
    var body: some View {
        ScrollView {
            VStack {
                Image(uiImage: UIImage(data: yarn.image ?? Data()) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cardBackground()
                    .padding(10)
//                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 5)
                
                HStack {
                    Text("Name: ").font(.headline)
                    Text(yarn.name ?? "N/A")
                }
                .padding(.vertical, 10)
                
                Divider()
                
                HStack {
                    Text("Dyer: ").font(.headline)
                    Text(yarn.dyer ?? "N/A")
                }
                .padding(.vertical, 10)
                
                
            }
            .foregroundStyle(Color.black)
            .padding()
        }
        .background(Color.white)
        .navigationTitle(yarn.name ?? "N/A")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                }
                .actionSheet(isPresented: $showActionSheet) {actionSheet}
            }
        }
       
    }
    
    func removeYarn(at yarn: Yarn) {
        managedObjectContext.delete(yarn)
        
        PersistenceController.shared.save()
    }
    
    init(yarn: Yarn, toast : Binding<Toast?>) {
        self.yarn = yarn
        self._toast = toast
    }
}
