//
//  WoolWalletApp.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import SwiftUI

private struct MainTabKey: EnvironmentKey {
    static let defaultValue: Binding<MainTab> = .constant(.dashboard) // Default value
}

private struct ProjectToShowAutomaticallyKey: EnvironmentKey {
    static let defaultValue: Binding<Project?> = .constant(nil) // Default value
}

private struct ProjectTabToShowAutomaticallyKey: EnvironmentKey {
    static let defaultValue: Binding<ProjectTab?> = .constant(nil)
}

extension EnvironmentValues {
    var mainTab: Binding<MainTab> {
        get { self[MainTabKey.self] }
        set { self[MainTabKey.self] = newValue }
    }
    
    var projectToShowAutomatically: Binding<Project?> {
        get { self[ProjectToShowAutomaticallyKey.self] }
        set { self[ProjectToShowAutomaticallyKey.self] = newValue }
    }
    
    /// Which Projects sub-tab to open when jumping from the dashboard (Finished, Queue, etc.)
    var projectTabToShowAutomatically: Binding<ProjectTab?> {
        get { self[ProjectTabToShowAutomaticallyKey.self] }
        set { self[ProjectTabToShowAutomaticallyKey.self] = newValue }
    }
}

enum MainTab {
    case dashboard
    case stash
    case patterns
    case projects
}

@main
struct WoolWalletApp: App {
    let persistenceController = PersistenceController.shared
    
    @State private var selectedTab = MainTab.dashboard
    @State private var projectToShowAutomatically: Project? = nil
    @State private var projectTabToShowAutomatically: ProjectTab? = nil
    
    init() {
        // SwiftUI has no clear button option; its text fields are UITextFields underneath
        UITextField.appearance().clearButtonMode = .whileEditing
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Dashboard(mainTab: $selectedTab)
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                    .tag(MainTab.dashboard)
                
                YarnList()
                    .tabItem {
                        Label("My Stash", systemImage: "volleyball")
                    }
                    .tag(MainTab.stash)
                
                PatternList()
                    .tabItem {
                        Label("Patterns", systemImage: "newspaper")
                    }
                    .tag(MainTab.patterns)
                
                ProjectList()
                    .tabItem {
                        Label("Projects", systemImage: "hammer")
                    }
                    .tag(MainTab.projects)
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environment(\.mainTab, $selectedTab)
            .environment(\.projectToShowAutomatically, $projectToShowAutomatically)
            .environment(\.projectTabToShowAutomatically, $projectTabToShowAutomatically)
        }
    }
}

