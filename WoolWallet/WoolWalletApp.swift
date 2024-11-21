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

extension EnvironmentValues {
    var mainTab: Binding<MainTab> {
        get { self[MainTabKey.self] }
        set { self[MainTabKey.self] = newValue }
    }
    
    var projectToShowAutomatically: Binding<Project?> {
        get { self[ProjectToShowAutomaticallyKey.self] }
        set { self[ProjectToShowAutomaticallyKey.self] = newValue }
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
            .onAppear {
                print("Documents Directory: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "Not found")")

            }
//            .onChange(of: selectedTab) {
//                if projectToShowAutomatically != nil {
//                    projectToShowAutomatically = nil
//                }
//            }
        }
    
    }
}
