//
//  AddSkeinsView.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import CoreData

/// Adds more of a yarn already in the stash instead of entering it again
struct AddSkeinsView: View {
    let candidates : [Yarn]
    var onAdded : (_ yarn: Yarn, _ count: Double) -> Void
    
    @State private var selectedID : NSManagedObjectID?
    @State private var count : Double
    
    init(candidates: [Yarn], initialCount: Double = 1, onAdded: @escaping (_ yarn: Yarn, _ count: Double) -> Void) {
        self.candidates = candidates
        self.onAdded = onAdded
        _selectedID = State(initialValue: candidates.count == 1 ? candidates.first?.objectID : nil)
        _count = State(initialValue: min(max(initialCount.rounded(), 1), 50))
    }
    
    private var selectedYarn : Yarn? {
        candidates.first { $0.objectID == selectedID }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(candidates) { yarn in
                    if candidates.count == 1 {
                        MatchingYarnRow(yarn: yarn, showsChevron: false)
                    } else {
                        Button {
                            selectedID = yarn.objectID
                        } label: {
                            HStack {
                                MatchingYarnRow(yarn: yarn, showsChevron: false)
                                
                                Image(systemName: selectedID == yarn.objectID ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedID == yarn.objectID ? Color.accentColor : Color(UIColor.tertiaryLabel))
                            }
                        }
                        .accessibilityAddTraits(selectedID == yarn.objectID ? .isSelected : [])
                    }
                }
            } header: {
                Text(candidates.count == 1 ? "Adding To" : "Which Yarn?")
            }
            
            if let yarn = selectedYarn {
                Section {
                    Stepper(value: $count, in: 1...50) {
                        Text(AddSkeinsView.amountText(count, isSockSet: yarn.isSockSet))
                    }
                    
                    ForEach(changes(for: yarn), id: \.label) { change in
                        HStack {
                            Text(change.label)
                                .foregroundStyle(Color.secondary)
                            
                            Spacer()
                            
                            Text(change.before)
                                .foregroundStyle(Color.secondary)
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                                .accessibilityLabel("to")
                            
                            Text(change.after)
                                .bold()
                        }
                        .accessibilityElement(children: .combine)
                    }
                } header: {
                    Text(yarn.isSockSet ? "New Sets" : "New Skeins")
                } footer: {
                    if yarn.isArchived {
                        Text("This yarn is archived and will move back to your active stash.")
                    } else if yarn.isSockSet {
                        Text("Each set adds a main skein and its minis.")
                    }
                }
                
                Section {
                    Button {
                        yarn.addSkeins(count)
                        PersistenceController.shared.save()
                        onAdded(yarn, count)
                    } label: {
                        Text("Add \(AddSkeinsView.amountText(count, isSockSet: yarn.isSockSet).capitalized)")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(selectedYarn?.isSockSet == true ? "Add Sets" : "Add Skeins")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: count)
    }
    
    private struct Change {
        let label : String
        let before : String
        let after : String
    }
    
    /// What the main skein's amounts will become
    private func changes(for yarn: Yarn) -> [Change] {
        let item = yarn.weightAndYardageArray.first
        let skeins = item?.currentSkeins ?? 0
        
        var changes = [Change(
            label: yarn.isSockSet ? "Main Skeins" : "Skeins",
            before: skeins.formatted,
            after: (skeins + count).formatted
        )]
        
        if let item, item.yardage > 0 {
            let unit = item.unitOfMeasure?.lowercased() ?? "yards"
            changes.append(Change(
                label: "Length",
                before: "\(item.currentLength.formatted) \(unit)",
                after: "\((item.currentLength + item.yardage * count).formatted) \(unit)"
            ))
        }
        
        return changes
    }
    
    static func amountText(_ count: Double, isSockSet: Bool) -> String {
        let noun = isSockSet ? "set" : "skein"
        return "\(count.formatted) \(noun)\(count == 1 ? "" : "s")"
    }
}

