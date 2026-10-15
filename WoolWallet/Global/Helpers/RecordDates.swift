//
//  RecordDates.swift
//  WoolWallet
//
//  Created by Mac on 10/14/26.
//

import SwiftUI

/// Small print at the bottom of a details page for when it was added and last changed.
/// Items saved before dates were tracked may have neither.
struct RecordDates: View {
    let added : Date?
    let updated : Date?
    
    var body: some View {
        VStack(spacing: 2) {
            if let added {
                Text("Added \(added.formatted(date: .abbreviated, time: .shortened))")
            }
            
            // Saved together with the add, so it only says something once there's been a later change
            if let updated, added.map({ updated.timeIntervalSince($0) >= 1 }) ?? true {
                Text("Updated \(updated.formatted(date: .abbreviated, time: .shortened))")
            }
        }
        .font(.caption2)
        .foregroundStyle(Color(UIColor.tertiaryLabel))
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}
