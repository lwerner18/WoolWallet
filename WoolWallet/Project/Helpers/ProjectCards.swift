//
//  ProjectCards.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import CoreData

enum ProjectStatus {
    case inProgress
    case completed
    case notStarted
    
    init(project: Project) {
        if project.complete {
            self = .completed
        } else if project.inProgress {
            self = .inProgress
        } else {
            self = .notStarted
        }
    }
    
    var title: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .notStarted: return "Not Started"
        }
    }
    
    /// Only finished projects get an icon; play and pause read like media controls
    var systemImage: String? {
        self == .completed ? "checkmark.circle.fill" : nil
    }
    
    /// Always available symbol for compact project rows
    var compactSymbol: String {
        switch self {
        case .inProgress: return "hammer.fill"
        case .completed:  return "checkmark.circle.fill"
        case .notStarted: return "bookmark.fill"
        }
    }
    
    /// Matches the pattern badges
    var color: Color {
        switch self {
        case .inProgress: return Color.green
        case .completed:  return Color.accentColor
        case .notStarted: return Color.orange
        }
    }
    
    var sortRank: Int {
        switch self {
        case .inProgress: return 0
        case .notStarted: return 1
        case .completed:  return 2
        }
    }
}

extension Array where Element == Project {
    /// In progress first, then the queue, then finished (newest finish date first)
    var sortedForDisplay: [Project] {
        sorted { left, right in
            let leftRank = ProjectStatus(project: left).sortRank
            let rightRank = ProjectStatus(project: right).sortRank
            
            if leftRank != rightRank {
                return leftRank < rightRank
            }
            
            if left.complete, right.complete {
                return (left.endDate ?? .distantPast) > (right.endDate ?? .distantPast)
            }
            
            return (left.startDate ?? left.dateAdded ?? .distantPast) > (right.startDate ?? right.dateAdded ?? .distantPast)
        }
    }
}

extension Project {
    var daysSinceStart: Int? {
        guard inProgress, let startDate else { return nil }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: Date.now)).day ?? 0
        return max(days, 0)
    }
    
    var daysTaken: Int? {
        guard complete, let startDate, let endDate else { return nil }
        return max(Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0, 0)
    }
    
    /// "Started 12 days ago", "Took 3 days"
    var progressText: String? {
        if let daysSinceStart {
            switch daysSinceStart {
            case 0:  return "Started today"
            case 1:  return "Started yesterday"
            default: return "Started \(daysSinceStart) days ago"
            }
        }
        
        if let daysTaken {
            return daysTaken == 0 ? "Finished in a day" : "Took \(daysTaken) day\(daysTaken == 1 ? "" : "s")"
        }
        
        return nil
    }
    
    /// "Today", "Yesterday", "12 days ago"
    var timeSinceStartText: String? {
        guard let daysSinceStart else { return nil }
        
        switch daysSinceStart {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        default: return "\(daysSinceStart) days ago"
        }
    }
    
    /// The colors of every paired yarn, in color A, B, C order
    var yarnColors: [Color] {
        var seen = Set<NSManagedObjectID>()
        var colors : [Color] = []
        
        for pairing in projectPairingItems {
            guard let yarn = pairing.yarnWeightAndYardage.yarn, !seen.contains(yarn.objectID) else { continue }
            seen.insert(yarn.objectID)
            
            // Stored colors are unordered, so they're sorted to keep the header from reshuffling
            colors += yarn.colorPickerItems.sorted { $0.name < $1.name }.map(\.color)
        }
        
        return colors
    }
    
    var sortedRowCounters: [RowCounter] {
        rowCounterItems.sorted { $0.order < $1.order }
    }
}

/// The first of a set of stored photos, decoded off the main thread
struct FirstStoredPhoto<Placeholder: View>: View {
    let images : NSSet?
    var maxPixelSize : CGFloat = StoredImage.thumbnailMaxPixelSize
    @ViewBuilder var placeholder : () -> Placeholder
    
    @State private var image : UIImage? = nil
    
    var body: some View {
        let objectIDs = StoredImage.objectIDs(from: images)
        // Include count so a just-saved photo whose IDs were still temporary forces a reload
        let key = objectIDs.map { $0.uriRepresentation().absoluteString }.joined(separator: ",") + "|\(images?.count ?? 0)"
        
        Color.clear
            .overlay {
                if let photo = image ?? StoredImage.cachedThumbnails(for: objectIDs, maxPixelSize: maxPixelSize)?.first?.image {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder()
                }
            }
            .clipped()
            .task(id: key) {
                guard !objectIDs.isEmpty else {
                    image = nil
                    return
                }
                
                // Show a cached copy immediately, then refresh; retry once if the store was still catching up
                if image == nil {
                    image = StoredImage.cachedThumbnails(for: objectIDs, maxPixelSize: maxPixelSize)?.first?.image
                }
                
                var loaded = await StoredImage.loadThumbnails(for: objectIDs, maxPixelSize: maxPixelSize).first?.image
                if loaded == nil {
                    try? await Task.sleep(for: .milliseconds(150))
                    loaded = await StoredImage.loadThumbnails(for: objectIDs, maxPixelSize: maxPixelSize).first?.image
                }
                image = loaded
            }
            .accessibilityHidden(true)
    }
}

/// Every photo in a to-many set, swipeable; for stash cards and other fill layouts
struct StoredPhotoPager<Placeholder: View>: View {
    let images : NSSet?
    var maxPixelSize : CGFloat = StoredImage.thumbnailMaxPixelSize
    /// Fill crops to the frame; fit shows the whole photo (letterboxed)
    var scalesToFill : Bool = true
    @Binding var page : Int
    @ViewBuilder var placeholder : () -> Placeholder
    
    @State private var photos : [UIImage] = []
    
    var body: some View {
        let objectIDs = StoredImage.objectIDs(from: images)
        let key = objectIDs.map { $0.uriRepresentation().absoluteString }.joined(separator: ",") + "|\(images?.count ?? 0)"
        let cached = StoredImage.cachedThumbnails(for: objectIDs, maxPixelSize: maxPixelSize)?.map(\.image) ?? []
        let shown = photos.isEmpty ? cached : photos
        
        Color.clear
            .overlay {
                if shown.count > 1 {
                    TabView(selection: $page) {
                        ForEach(Array(shown.enumerated()), id: \.offset) { index, photo in
                            photoView(photo)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else if let photo = shown.first {
                    photoView(photo)
                } else {
                    placeholder()
                }
            }
            .clipped()
            .task(id: key) {
                guard !objectIDs.isEmpty else {
                    photos = []
                    page = 0
                    return
                }
                
                if photos.isEmpty, let cached = StoredImage.cachedThumbnails(for: objectIDs, maxPixelSize: maxPixelSize) {
                    photos = cached.map(\.image)
                }
                
                var loaded = await StoredImage.loadThumbnails(for: objectIDs, maxPixelSize: maxPixelSize).map(\.image)
                if loaded.isEmpty {
                    try? await Task.sleep(for: .milliseconds(150))
                    loaded = await StoredImage.loadThumbnails(for: objectIDs, maxPixelSize: maxPixelSize).map(\.image)
                }
                
                photos = loaded
                if page >= loaded.count {
                    page = max(loaded.count - 1, 0)
                }
            }
            .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func photoView(_ photo: UIImage) -> some View {
        Image(uiImage: photo)
            .resizable()
            .aspectRatio(contentMode: scalesToFill ? .fill : .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }
}

/// "Started 12 days ago", "✓ Took 3 days"
struct ProjectStatusLine: View {
    @ObservedObject var project : Project
    
    var body: some View {
        let status = ProjectStatus(project: project)
        
        HStack(spacing: 4) {
            if let systemImage = status.systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(status.color)
            }
            
            Text(project.progressText ?? (status == .notStarted ? "Not started yet" : status.title))
        }
        .accessibilityElement(children: .combine)
    }
}

extension Project {
    @discardableResult
    func addRowCounter(in context: NSManagedObjectContext) -> RowCounter {
        let counter = RowCounter(context: context)
        counter.name = rowCounterItems.isEmpty ? "Rows" : "Row Counter \(rowCounterItems.count + 1)"
        counter.order = Int16(rowCounterItems.count)
        counter.project = self
        
        PersistenceController.shared.save()
        return counter
    }
}

/// An in-progress project, with the pattern a tap away
struct ProjectWorkCard: View {
    @ObservedObject var project : Project
    var onRead : () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if project.hasImages {
                FirstStoredPhoto(images: project.images, maxPixelSize: 1200) {
                    Color(UIColor.tertiarySystemFill)
                }
                .frame(height: 150)
            }
            
            HStack(alignment: .top, spacing: 12) {
                if let pattern = project.pattern {
                    PatternCover(pattern: pattern, cornerRadius: 6, iconSize: Size.small)
                        .frame(width: 54, height: 72)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.pattern?.name ?? "No Name")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    
                    if let startDate = DateUtils.shared.formatDate(project.startDate) {
                        Text("Started \(startDate)")
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                        
                        if let timeSinceStart = project.timeSinceStartText {
                            Text(timeSinceStart)
                                .font(.caption)
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                    } else {
                        ProjectStatusLine(project: project)
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
            
            if project.pattern?.document != nil {
                Button(action: onRead) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages")
                        Text("Read Pattern")
                    }
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding([.horizontal, .bottom], 12)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// A project waiting to be started
struct ProjectQueueRow: View {
    @ObservedObject var project : Project
    var onStart : () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let pattern = project.pattern {
                PatternCover(pattern: pattern, cornerRadius: 6, iconSize: Size.small)
                    .frame(width: 44, height: 58)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(project.pattern?.name ?? "No Name")
                    .bold()
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                
                if let added = DateUtils.shared.formatDate(project.dateAdded) {
                    Text("Added \(added)")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            
            Spacer(minLength: 0)
            
            // Label in a list row spreads its icon far from the text
            Button(action: onStart) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.caption.bold())
                    
                    Text("Start")
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.white)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(ProjectStatus.inProgress.color)
            .accessibilityLabel("Start \(project.pattern?.name ?? "Project")")
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

/// Shared project card for pattern details, yarn details, and similar carousels
struct ProjectCard: View {
    @ObservedObject var project : Project
    /// When set (yarn details), show the pattern name and yarn yardage used
    var yarnId : UUID? = nil
    /// Single project with no photos — row instead of a large empty cover
    var compact : Bool = false
    var isOpening : Bool = false
    var onOpen : () -> Void
    
    private var status : ProjectStatus {
        ProjectStatus(project: project)
    }
    
    private var showPatternName : Bool { yarnId != nil }
    
    private var progressHeadline: String {
        switch status {
        case .inProgress:
            return project.progressText
                ?? DateUtils.shared.formatDate(project.startDate).map { "Started \($0)" }
                ?? status.title
        case .completed:
            return project.progressText ?? status.title
        case .notStarted:
            return "In the queue"
        }
    }
    
    private var progressDetail: String? {
        switch status {
        case .inProgress:
            guard project.progressText != nil else { return nil }
            return DateUtils.shared.formatDate(project.startDate)
        case .completed:
            return DateUtils.shared.formatDate(project.endDate)
        case .notStarted:
            return DateUtils.shared.formatDate(project.dateAdded).map { "Added \($0)" }
        }
    }
    
    private var yarnUsageText: String? {
        guard let yarnId else { return nil }
        
        let pairings = project.projectPairingItems.filter { $0.yarnWeightAndYardage.yarn?.id == yarnId }
        let used = pairings.reduce(0.0) { $0 + ($1.lengthUsed ?? 0) }
        guard used > 0, project.complete else { return nil }
        
        let unit = pairings.first?.yarnWeightAndYardage.unitOfMeasure?.lowercased() ?? ""
        return "Used \(used.formatted) \(unit)"
    }
    
    private var headline: String {
        if showPatternName {
            return project.pattern?.name ?? "Project"
        }
        return progressHeadline
    }
    
    private var detail: String? {
        if showPatternName {
            return [status.title, progressHeadline == status.title ? nil : progressHeadline, yarnUsageText]
                .compactMap { $0 }
                .joined(separator: " · ")
                .nilIfEmpty
        }
        return progressDetail
    }
    
    var body: some View {
        Button(action: onOpen) {
            Group {
                if compact {
                    compactContent
                } else {
                    photoContent
                }
            }
            .entityCardChrome(padding: compact ? 14 : 12)
            .overlay {
                if isOpening {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.85))
                    
                    ProgressView()
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isOpening)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens this project")
    }
    
    private var compactContent: some View {
        HStack(spacing: 12) {
            Image(systemName: status.systemImage ?? status.compactSymbol)
                .font(.body.bold())
                .foregroundStyle(status.color)
                .frame(width: 36, height: 36)
                .background(status.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color(UIColor.tertiaryLabel))
        }
    }
    
    private var photoContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(showPatternName ? 1 : 4 / 3, contentMode: .fit)
                .overlay { cover }
                .overlay(alignment: .topLeading) {
                    EntityStatusBadge(
                        title: status.title,
                        systemImage: status.systemImage,
                        iconColor: status.color
                    )
                    .padding(8)
                }
                .entityCardMedia()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
            }
        }
    }
    
    @ViewBuilder
    private var cover: some View {
        if project.hasImages {
            FirstStoredPhoto(images: project.images, maxPixelSize: 900) {
                ProjectPatternCoverFallback(project: project)
            }
        } else {
            ProjectPatternCoverFallback(project: project)
        }
    }
}

typealias PatternProjectCard = ProjectCard

/// Pattern cover on a soft wash — used when a project has no photos of its own
struct ProjectPatternCoverFallback: View {
    @ObservedObject var project : Project
    var coverSize : CGSize = CGSize(width: 78, height: 104)
    var iconSize : Size = .medium
    
    var body: some View {
        if let pattern = project.pattern {
            let wash = PatternUtils.shared.getItemDisplay(for: pattern.patternItems.first?.item).color
            
            ZStack {
                LinearGradient(
                    colors: [wash.opacity(0.22), wash.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                PatternCover(pattern: pattern, cornerRadius: 8, iconSize: iconSize)
                    .frame(width: coverSize.width, height: coverSize.height)
                    .shadow(color: Color.black.opacity(0.14), radius: 5, y: 2)
            }
        } else {
            Color(UIColor.tertiarySystemFill)
        }
    }
}

/// Capsule badge shared by project / pattern / yarn carousel cards
struct EntityStatusBadge: View {
    var title : String
    var systemImage : String? = nil
    var iconColor : Color = Color.primary
    
    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(iconColor)
            }
            
            Text(title)
        }
        .font(.caption2.bold())
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

extension View {
    /// Padded rounded card chrome used by yarn, pattern, and project carousel cards
    func entityCardChrome(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    func entityCardMedia(cornerRadius: CGFloat = 12) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// A finished piece in the completed gallery
struct ProjectGalleryTile: View {
    @ObservedObject var project : Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if project.hasImages {
                        FirstStoredPhoto(images: project.images, maxPixelSize: 900) {
                            ProjectPatternCoverFallback(
                                project: project,
                                coverSize: CGSize(width: 72, height: 96)
                            )
                        }
                    } else {
                        ProjectPatternCoverFallback(
                            project: project,
                            coverSize: CGSize(width: 72, height: 96)
                        )
                    }
                }
                .entityCardMedia()
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(project.pattern?.name ?? "No Name")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                Text([DateUtils.shared.formatDate(project.endDate), project.progressText].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// A big counter that can be counted right on the project page; its name opens a menu to rename, open, reset, or delete it
struct InlineRowCounter: View {
    @ObservedObject var counter : RowCounter
    var onOpen : () -> Void
    var onDelete : () -> Void
    
    @State private var showRename = false
    @State private var draftName = ""
    
    var body: some View {
        VStack(spacing: 6) {
            Menu {
                menuItems
            } label: {
                HStack(spacing: 4) {
                    Text(counter.name ?? "Counter")
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                }
                .font(.subheadline)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .frame(minHeight: 28)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("\(counter.name ?? "Counter") Options")
            
            Text("\(counter.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText(value: Double(counter.count)))
                .accessibilityLabel("\(counter.name ?? "Count"), \(counter.count)")
            
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        counter.adjust(by: -1)
                    }
                    PersistenceController.shared.save()
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.bordered)
                .disabled(counter.count <= 0)
                .accessibilityLabel("Decrease \(counter.name ?? "Count")")
                
                Button {
                    withAnimation {
                        counter.adjust(by: 1)
                    }
                    PersistenceController.shared.save()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Increase \(counter.name ?? "Count")")
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            menuItems
        }
        .rowCounterRenameAlert(counter: counter, isPresented: $showRename, draftName: $draftName)
        .sensoryFeedback(.increase, trigger: counter.count)
    }
    
    @ViewBuilder
    private var menuItems: some View {
        Button {
            draftName = counter.name ?? ""
            showRename = true
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        
        Button(action: onOpen) {
            Label("Open Counter", systemImage: "arrow.up.left.and.arrow.down.right")
        }
        
        Button {
            withAnimation {
                counter.resetCount()
            }
            PersistenceController.shared.save()
        } label: {
            Label("Reset to 0", systemImage: "arrow.counterclockwise")
        }
        
        Divider()
        
        Button(role: .destructive, action: onDelete) {
            Label("Delete Counter", systemImage: "trash")
        }
    }
}

extension View {
    /// Shared rename alert for compact and inline row counters
    func rowCounterRenameAlert(counter: RowCounter, isPresented: Binding<Bool>, draftName: Binding<String>) -> some View {
        self.alert("Rename Counter", isPresented: isPresented) {
            TextField("Name", text: draftName)
            
            Button("Save") {
                let trimmed = draftName.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                
                counter.name = trimmed
                PersistenceController.shared.save()
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
}
