//
//  DuplicateYarnSheet.swift
//  WoolWallet
//
//  Created by Mac on 10/14/26.
//

import SwiftUI
import CoreData

/// Shown before saving a yarn whose name and dyer match one already in the stash
struct DuplicateYarnSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let name : String
    let dyer : String
    let matches : [Yarn]
    let isEditing : Bool
    var onContinue : () -> Void
    
    @State private var displayedYarn : Yarn? = nil
    
    private var message : String {
        let yarn = dyer.isEmpty ? "“\(name)”" : "“\(name)” by \(dyer)"
        return matches.count == 1
            ? "\(yarn) is already in your stash. Take a look to make sure this isn't the same one."
            : "\(yarn) matches \(matches.count) yarns in your stash. Take a look to make sure this isn't one of them."
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.orange)
                            .accessibilityHidden(true)
                        
                        Text("You May Already Have This Yarn")
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    ForEach(matches) { yarn in
                        Button {
                            displayedYarn = yarn
                        } label: {
                            MatchingYarnRow(yarn: yarn)
                        }
                        .accessibilityHint("Shows the yarn's details")
                    }
                } header: {
                    Text(matches.count == 1 ? "Already in Your Stash" : "Already in Your Stash (\(matches.count))")
                } footer: {
                    Text("Tap a yarn to see its details.")
                }
                
                Section {
                    Button(isEditing ? "Save Anyway" : "Add Anyway") {
                        onContinue()
                        dismiss()
                    }
                    
                    Button("Go Back") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Possible Duplicate")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $displayedYarn) { yarn in
            YarnInfo(yarn: yarn, isPopover: true)
        }
    }
}

private struct MatchingYarnRow: View {
    @ObservedObject var yarn : Yarn
    
    @State private var thumbnail : UIImage? = nil
    
    private var details : String {
        var parts : [String] = []
        
        if let skein = yarn.weightAndYardageArray.first {
            let weight = Weight.fromStored(skein.weight)
            if weight != .none {
                parts.append(weight.getDisplay())
            }
            
            if skein.currentLength > 0 {
                parts.append("\(skein.currentLength.formatted) \(skein.unitOfMeasure?.lowercased() ?? "yards") left")
            }
        }
        
        return parts.joined(separator: " · ")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(UIColor.secondarySystemFill)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(yarn.name ?? "")
                    .bold()
                    .foregroundStyle(Color.primary)
                
                if let dyer = yarn.dyer, !dyer.isEmpty {
                    Text(dyer)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                
                // Same yarn in a different colorway is common, so the colors help tell them apart
                let colors = yarn.colorPickerItems
                if !colors.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(colors.prefix(6), id: \.id) { item in
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5))
                        }
                        
                        Text(colors.map { $0.description.isEmpty ? $0.name : $0.description }.joined(separator: ", "))
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                }
                
                if !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                
                if yarn.isArchived {
                    Label("Archived", systemImage: "tray.and.arrow.down")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
        .task {
            let objectIDs = StoredImage.objectIDs(from: yarn.images)
            if let cached = StoredImage.cachedThumbnails(for: objectIDs) {
                thumbnail = cached.first?.image
            } else {
                thumbnail = await StoredImage.loadThumbnails(for: objectIDs).first?.image
            }
        }
    }
}
