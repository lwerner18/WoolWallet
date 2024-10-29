//
//  ProjectList.swift
//  WoolWallet
//
//  Created by Mac on 9/3/24.
//

import Foundation
import SwiftUI

struct ProjectList: View {
    @State private var showAddProjectForm : Bool = false
    @State private var newProject         : Project? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Projects")
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddProjectForm = true
                    }) {
                        Image(systemName: "plus") // Use a system icon
                            .imageScale(.large)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAddProjectForm) {
                AddOrEditProjectForm(projectToEdit: nil, preSelectedPattern: nil) { addedProject in
                    // Capture the newly added project
                    newProject = addedProject
                    showAddProjectForm = false
                }
            }
    
        }
    }
}
