//
//  PatternInfo.swift
//  WoolWallet
//
//  Created by Mac on 10/3/24.
//

import Foundation
import SwiftUI
import CoreData

struct PatternInfo: View {
    // @Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @ObservedObject var pattern : Pattern
    var isNewPattern : Bool?
    
    init(pattern: Pattern, isNewPattern : Bool? = false) {
        self.pattern = pattern
        self.isNewPattern = isNewPattern
    }
    
    // Internal state trackers
    @State private var showEditPatternForm : Bool = false
    @State private var showConfirmationDialog = false
    @State private var animateCheckmark = false
    
    
    // Computed property to calculate if device is most likely in portrait mode
    var isPortraitMode: Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    var body: some View {
        Text("here")
    }
}
