//
//  StashCheck.swift
//  WoolWallet
//
//  Created by Mac on 10/14/26.
//

import SwiftUI
import CoreData

enum YarnMatching {
    /// Ignores case, accents, and spacing
    static func key(_ value: String?) -> String {
        (value ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    /// Close enough to be worth a look when a label was read imperfectly, e.g. "Rios" and "Rios Worsted", or "Sunset" and "Sunsct"
    static func namesAreSimilar(_ first: String?, _ second: String?) -> Bool {
        let a = key(first).filter { $0.isLetter || $0.isNumber }
        let b = key(second).filter { $0.isLetter || $0.isNumber }
        guard !a.isEmpty, !b.isEmpty else { return false }
        
        if a == b { return true }
        if min(a.count, b.count) >= 4 && (a.contains(b) || b.contains(a)) { return true }
        
        // One or two OCR mistakes across the whole name, e.g. "Popsicle Sunset" vs "Popsicle Sunsct"
        if almostEqual(a, b) { return true }
        
        let wordsA = words(first), wordsB = words(second)
        guard !wordsA.isEmpty, !wordsB.isEmpty else { return false }
        
        // Count words that match exactly or are a near misspelling of each other
        var remaining = wordsB
        var shared = 0
        for word in wordsA {
            if remaining.remove(word) != nil {
                shared += 1
                continue
            }
            
            if let close = remaining.first(where: { almostEqual(word, $0) }) {
                remaining.remove(close)
                shared += 1
            }
        }
        
        let union = wordsA.count + wordsB.count - shared
        return shared > 0 && Double(shared) / Double(union) >= 0.5
    }
    
    private static func words(_ value: String?) -> Set<String> {
        Set(key(value).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 })
    }
    
    /// True when two short strings differ by only a letter or two, the kind of slip OCR makes
    private static func almostEqual(_ first: String, _ second: String) -> Bool {
        let a = Array(first), b = Array(second)
        let longer = max(a.count, b.count)
        guard longer >= 4, abs(a.count - b.count) <= 2 else { return false }
        
        // Allow roughly one mistake per 8 letters, at least 1 and at most 2
        let allowed = min(2, max(1, longer / 8))
        return editDistance(a, b, limit: allowed) <= allowed
    }
    
    /// Levenshtein distance, bailing out once it can't beat `limit`
    private static func editDistance(_ a: [Character], _ b: [Character], limit: Int) -> Int {
        if abs(a.count - b.count) > limit { return limit + 1 }
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        
        for i in 1...a.count {
            current[0] = i
            var rowMin = current[0]
            
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
                rowMin = min(rowMin, current[j])
            }
            
            if rowMin > limit { return limit + 1 }
            swap(&previous, &current)
        }
        
        return previous[b.count]
    }
}

/// Stash yarn that could be the yarn on a label
struct StashMatches {
    /// Same name, and the same dyer when both are known
    var likely : [Yarn] = []
    /// A near name, the same name from another dyer, or the same dyer and colorway
    var similar : [Yarn] = []
    /// Colorways go into notes when a label fills the form, so a match there means the very same yarn
    var sameColorway : Set<NSManagedObjectID> = []
    
    var isEmpty : Bool { likely.isEmpty && similar.isEmpty }
    
    init(name: String, dyer: String, colorway: String?, in yarns: [Yarn]) {
        let nameKey = YarnMatching.key(name)
        let dyerKey = YarnMatching.key(dyer)
        let colorwayKey = YarnMatching.key(colorway)
        var colorwayIDs : Set<NSManagedObjectID> = []
        
        for yarn in yarns where !yarn.isDeleted {
            let yarnNameKey = YarnMatching.key(yarn.name)
            let yarnDyerKey = YarnMatching.key(yarn.dyer)
            let dyerFits = dyerKey.isEmpty || yarnDyerKey.isEmpty || dyerKey == yarnDyerKey
            let sameDyer = !dyerKey.isEmpty && dyerKey == yarnDyerKey
            
            // Short colorways like "Red" would turn up in all sorts of notes
            let colorwayMatches = colorwayKey.count >= 3 && (
                YarnMatching.key(yarn.notes).contains(colorwayKey)
                || yarn.colorPickerItems.contains { YarnMatching.key($0.description) == colorwayKey }
            )
            
            if colorwayMatches {
                colorwayIDs.insert(yarn.objectID)
            }
            
            if !nameKey.isEmpty && yarnNameKey == nameKey && dyerFits {
                likely.append(yarn)
            } else if (dyerFits && YarnMatching.namesAreSimilar(name, yarn.name))
                        || (!nameKey.isEmpty && yarnNameKey == nameKey)
                        || (sameDyer && colorwayMatches) {
                similar.append(yarn)
            }
        }
        
        let colorwayFirst : (Yarn, Yarn) -> Bool = { colorwayIDs.contains($0.objectID) && !colorwayIDs.contains($1.objectID) }
        likely.sort(by: colorwayFirst)
        similar.sort(by: colorwayFirst)
        sameColorway = colorwayIDs
    }
}

/// Scan a label to see whether that yarn is already in the stash, e.g. while shopping
struct StashCheckSheet: View {
    @FetchRequest(entity: Yarn.entity(), sortDescriptors: [])
    private var yarns: FetchedResults<Yarn>
    
    var onAdd : (Yarn) -> Void
    
    var body: some View {
        LabelScannerSheet(title: "Check Your Stash", knownDyers: Array(Set(yarns.compactMap(\.dyer)))) { label, image, rescan in
            StashCheckResults(label: label, image: image, yarns: Array(yarns), onRescan: rescan, onAdd: onAdd)
        }
    }
}

private struct StashCheckResults: View {
    let label : ScannedYarnLabel
    let image : UIImage
    let yarns : [Yarn]
    var onRescan : () -> Void
    var onAdd : (Yarn) -> Void
    
    @State private var name : String
    @State private var dyer : String
    @State private var displayedYarn : Yarn? = nil
    @State private var showAddForm = false
    @State private var showAddSkeins = false
    @State private var skeinsAdded : SkeinsAdded? = nil
    
    private struct SkeinsAdded {
        let yarn : Yarn
        let count : Double
    }
    
    init(label: ScannedYarnLabel, image: UIImage, yarns: [Yarn], onRescan: @escaping () -> Void, onAdd: @escaping (Yarn) -> Void) {
        self.label = label
        self.image = image
        self.yarns = yarns
        self.onRescan = onRescan
        self.onAdd = onAdd
        _name = State(initialValue: label.name ?? "")
        _dyer = State(initialValue: label.dyer ?? "")
    }
    
    private var hasSearch : Bool {
        !YarnMatching.key(name).isEmpty || !YarnMatching.key(dyer).isEmpty
    }
    
    /// The label as corrected here, for filling in a new yarn
    private var editedLabel : ScannedYarnLabel {
        var edited = label
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDyer = dyer.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.name = trimmedName.isEmpty ? nil : trimmedName
        edited.dyer = trimmedDyer.isEmpty ? nil : trimmedDyer
        return edited
    }
    
    private var labelDetails : String {
        [LabelField.weight, .length, .colorway]
            .compactMap { field in field.value(in: label).map { "\(field.shortTitle): \($0)" } }
            .joined(separator: "\n")
    }
    
    var body: some View {
        let matches = StashMatches(name: name, dyer: dyer, colorway: label.colorway, in: yarns)
        let candidates = hasSearch ? matches.likely + matches.similar : []
        
        List {
            Section {
                Group {
                    if let skeinsAdded {
                        addedConfirmation(skeinsAdded)
                    } else {
                        verdict(matches)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            Section {
                HStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityHidden(true)
                    
                    Text(labelDetails.isEmpty ? "Only a name or dyer could be read." : labelDetails)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                
                TextField("Name", text: $name)
                    .autocorrectionDisabled()
                
                TextField("Dyer", text: $dyer)
                    .autocorrectionDisabled()
            } header: {
                Text("From the Label")
            } footer: {
                Text("Fix anything that was read incorrectly and the results will update.")
            }
            
            if hasSearch {
                matchSection(matches.likely.count == 1 ? "Match" : "Matches", yarns: matches.likely, sameColorway: matches.sameColorway)
                matchSection("Similar", yarns: matches.similar, sameColorway: matches.sameColorway)
            }
            
            Section {
                if !candidates.isEmpty {
                    Button {
                        showAddSkeins = true
                    } label: {
                        Label("Add Skeins to Existing Yarn", systemImage: "plus.square.on.square")
                    }
                }
                
                Button {
                    showAddForm = true
                } label: {
                    Label(candidates.isEmpty ? "Add to Stash" : "Add as New Yarn", systemImage: "plus.circle")
                }
                
                Button(action: onRescan) {
                    Label("Scan Another Label", systemImage: "text.viewfinder")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(isPresented: $showAddSkeins) {
            AddSkeinsView(candidates: candidates) { yarn, count in
                withAnimation {
                    skeinsAdded = SkeinsAdded(yarn: yarn, count: count)
                }
                showAddSkeins = false
            }
        }
        .sheet(item: $displayedYarn) { yarn in
            YarnInfo(yarn: yarn, isPopover: true)
        }
        .fullScreenCover(isPresented: $showAddForm) {
            AddOrEditYarnForm(yarnToEdit: nil, scannedLabel: editedLabel, labelPhoto: image, onAddSkeins: { yarn, count in
                skeinsAdded = SkeinsAdded(yarn: yarn, count: count)
                showAddForm = false
            }, onAdd: onAdd)
        }
    }
    
    private func addedConfirmation(_ added: SkeinsAdded) -> some View {
        let isSockSet = added.yarn.isSockSet
        let total = added.yarn.weightAndYardageArray.first?.currentSkeins ?? added.count
        
        return VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.green)
                .accessibilityHidden(true)
            
            Text("Added \(AddSkeinsView.amountText(added.count, isSockSet: isSockSet).capitalized)")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            
            Text("\(added.yarn.name ?? "This yarn") now has \(AddSkeinsView.amountText(total, isSockSet: isSockSet)).")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func matchSection(_ title: String, yarns: [Yarn], sameColorway: Set<NSManagedObjectID>) -> some View {
        if !yarns.isEmpty {
            Section(title) {
                ForEach(yarns) { yarn in
                    Button {
                        displayedYarn = yarn
                    } label: {
                        MatchingYarnRow(yarn: yarn, badge: sameColorway.contains(yarn.objectID) ? "Same colorway" : nil)
                    }
                    .accessibilityHint("Shows the yarn's details")
                }
            }
        }
    }
    
    private func verdict(_ matches: StashMatches) -> some View {
        let icon : String, color : Color, title : String, message : String
        
        if !hasSearch {
            (icon, color, title, message) = ("text.magnifyingglass", .secondary, "Nothing to Search For", "Enter the yarn's name or dyer below.")
        } else if !matches.likely.isEmpty {
            let colorwayNote = matches.likely.contains { matches.sameColorway.contains($0.objectID) } ? " One is the same colorway." : ""
            let count = matches.likely.count == 1 ? "You have 1 yarn" : "You have \(matches.likely.count) yarns"
            (icon, color, title, message) = ("shippingbox.fill", .orange, "Already in Your Stash", "\(count) matching this label.\(colorwayNote)")
        } else if !matches.similar.isEmpty {
            (icon, color, title, message) = ("questionmark.circle.fill", .yellow, "Maybe in Your Stash", "Nothing matches exactly, but some yarn looks similar.")
        } else {
            (icon, color, title, message) = ("checkmark.circle.fill", .green, "Not in Your Stash", "You don't have this yarn yet.")
        }
        
        return VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            
            Text(title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}

