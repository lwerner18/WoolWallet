//
//  SummaryExport.swift
//  WoolWallet
//
//  Shareable summary images for projects and yarns.
//

import SwiftUI
import UIKit
import CoreData

enum SummaryExport {
    static let cardSize = CGSize(width: 1080, height: 1350)
    
    @MainActor
    static func projectImage(for project: Project) -> UIImage? {
        render(ProjectSummaryCard(data: ProjectSummaryData(project: project)))
    }
    
    @MainActor
    static func yarnImage(for yarn: Yarn) -> UIImage? {
        render(YarnSummaryCard(data: YarnSummaryData(yarn: yarn)))
    }
    
    /// JPEG on disk so ShareLink can open without encoding on tap
    static func writeShareFile(from image: UIImage, name: String) async -> URL? {
        await Task.detached(priority: .userInitiated) {
            guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
            
            let safe = name
                .replacingOccurrences(of: "/", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fileName = "WoolWallet-\(safe.isEmpty ? "Summary" : safe).jpg"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                try data.write(to: url, options: .atomic)
                return url
            } catch {
                return nil
            }
        }.value
    }
    
    @MainActor
    private static func render<Content: View>(_ content: Content) -> UIImage? {
        let sized = content
            .frame(width: cardSize.width, height: cardSize.height)
            .environment(\.colorScheme, .light)
        
        let renderer = ImageRenderer(content: sized)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(cardSize)
        return renderer.uiImage
    }
    
    static func firstPhoto(from images: NSSet?, maxPixelSize: CGFloat = 1400) -> UIImage? {
        let stored = (images?.allObjects as? [StoredImage] ?? [])
            .sorted { $0.order < $1.order }
        guard let first = stored.first else { return nil }
        let image = first.displayImage(maxPixelSize: maxPixelSize)
        return image.size.width > 0 ? image : nil
    }
}

/// Loads a summary image with a spinner, then shows a preview and Share
struct SummaryExportPreview: View {
    enum Subject {
        case project(Project)
        case yarn(Yarn)
        
        var shareName: String {
            switch self {
            case .project(let project):
                return project.pattern?.name ?? "Project"
            case .yarn(let yarn):
                return yarn.name ?? "Yarn"
            }
        }
    }
    
    let subject : Subject
    
    @Environment(\.dismiss) private var dismiss
    @State private var image : UIImage? = nil
    @State private var shareURL : URL? = nil
    @State private var failed = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    ScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                            .padding()
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                } else if failed {
                    ContentUnavailableView(
                        "Couldn't Create Summary",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Try again in a moment.")
                    )
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Preparing summary…")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationTitle("Export Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if let shareURL, let image {
                        ShareLink(
                            item: shareURL,
                            preview: SharePreview(subject.shareName, image: Image(uiImage: image))
                        ) {
                            Text("Share")
                        }
                    } else {
                        Text("Share")
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .task {
                // Yield so the sheet and spinner paint before ImageRenderer work
                await Task.yield()
                
                let rendered: UIImage?
                switch subject {
                case .project(let project):
                    rendered = SummaryExport.projectImage(for: project)
                case .yarn(let yarn):
                    rendered = SummaryExport.yarnImage(for: yarn)
                }
                
                guard let rendered else {
                    failed = true
                    return
                }
                
                image = rendered
                shareURL = await SummaryExport.writeShareFile(from: rendered, name: subject.shareName)
            }
            .onDisappear {
                if let shareURL {
                    try? FileManager.default.removeItem(at: shareURL)
                }
            }
        }
    }
}

// MARK: - Project data

private struct ProjectYarnLine: Identifiable {
    let id = UUID()
    var title : String
    var colors : [Color]
}

private struct ProjectSummaryData {
    var title : String
    var designer : String?
    var patternMeta : String?
    var statusTitle : String
    var statusColor : Color
    var progressText : String?
    var dateLine : String?
    var yarns : [ProjectYarnLine]
    var photo : UIImage?
    var washColors : [Color]
    
    init(project: Project) {
        let pattern = project.pattern
        title = pattern?.name ?? "Project"
        
        if let designer = pattern?.designer, !designer.isEmpty {
            self.designer = designer
        } else {
            self.designer = nil
        }
        
        let meta = pattern?.typeAndItems.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        patternMeta = meta.isEmpty ? nil : meta
        
        let status = ProjectStatus(project: project)
        statusTitle = status.title
        statusColor = status.color
        progressText = project.progressText
        
        switch status {
        case .completed:
            dateLine = DateUtils.shared.formatDate(project.endDate).map { "Finished \($0)" }
        case .inProgress:
            dateLine = DateUtils.shared.formatDate(project.startDate).map { "Started \($0)" }
        case .notStarted:
            dateLine = DateUtils.shared.formatDate(project.dateAdded).map { "Added \($0)" }
        }
        
        var seen = Set<NSManagedObjectID>()
        var yarns : [ProjectYarnLine] = []
        for pairing in project.projectPairingItems {
            guard let yarn = pairing.yarnWeightAndYardage.yarn, !seen.contains(yarn.objectID) else { continue }
            seen.insert(yarn.objectID)
            
            let name = yarn.name ?? "Yarn"
            let title = (yarn.dyer?.isEmpty == false) ? "\(name) · \(yarn.dyer!)" : name
            yarns.append(ProjectYarnLine(title: title, colors: Array(yarn.sortedYarnColors.prefix(4))))
        }
        self.yarns = yarns
        
        photo = SummaryExport.firstPhoto(from: project.images)
            ?? SummaryExport.firstPhoto(from: pattern?.images)
        washColors = Array(project.yarnColors.prefix(5))
    }
}

// MARK: - Yarn data

private struct YarnStat {
    var label : String
    var value : String
}

private struct YarnFiber {
    var label : String
    var percentage : Int
    var color : Color
}

private struct YarnSummaryData {
    var name : String
    var dyer : String?
    var badges : [String]
    var stats : [YarnStat]
    var fibers : [YarnFiber]
    var colorNames : [(name: String, color: Color)]
    var photo : UIImage?
    var washColors : [Color]
    
    init(yarn: Yarn) {
        name = yarn.name ?? "Yarn"
        
        if let dyer = yarn.dyer, !dyer.isEmpty {
            self.dyer = dyer
        } else {
            self.dyer = nil
        }
        
        var badges : [String] = []
        if yarn.isSockSet { badges.append("Sock Set") }
        if yarn.isMini { badges.append("Mini") }
        if yarn.isCaked { badges.append("Caked") }
        if yarn.colorType == ColorType.variegated.rawValue {
            badges.append("Variegated")
        } else if yarn.colorType == ColorType.tonal.rawValue {
            badges.append("Tonal")
        }
        self.badges = badges
        
        var stats : [YarnStat] = []
        if let weight = yarn.primaryWeightLabel {
            stats.append(YarnStat(label: "Weight", value: weight))
        }
        
        let skeins = yarn.weightAndYardageArray
        if yarn.isSockSet, skeins.count > 1 {
            let main = skeins[0]
            if main.currentLength > 0 {
                let unit = main.unitOfMeasure?.lowercased() ?? "yd"
                stats.append(YarnStat(
                    label: "Main",
                    value: "\(main.isExact ? "" : "~")\(main.currentLength.formatted) \(unit)"
                ))
            }
            let miniCount = skeins.dropFirst().count
            stats.append(YarnStat(label: "Minis", value: "\(miniCount)"))
        } else if let first = skeins.first {
            if first.currentLength > 0 {
                let unit = first.unitOfMeasure?.lowercased() ?? "yd"
                stats.append(YarnStat(
                    label: "Length",
                    value: "\(first.isExact ? "" : "~")\(first.currentLength.formatted) \(unit)"
                ))
            }
            if first.grams > 0 {
                stats.append(YarnStat(label: "Grams", value: "\(Int(first.grams))"))
            }
            if first.currentSkeins > 0 {
                stats.append(YarnStat(label: "Skeins", value: first.currentSkeins.formatted))
            }
        }
        self.stats = Array(stats.prefix(4))
        
        let palette = yarn.sortedYarnColors
        let fiberItems = yarn.compositionItems
            .filter { $0.percentage != 0 && !YarnUtils.shared.getMaterial(item: $0).isEmpty }
            .sorted { $0.percentage > $1.percentage }
        
        fibers = fiberItems.enumerated().map { index, item in
            let color = palette.isEmpty
                ? chartColors[index % chartColors.count]
                : palette[index % palette.count]
            return YarnFiber(
                label: YarnUtils.shared.getMaterial(item: item),
                percentage: item.percentage,
                color: color
            )
        }
        
        colorNames = yarn.colorPickerItems
            .sorted { $0.name < $1.name }
            .map { item in
                let label = !item.description.isEmpty && item.description != item.name
                    ? item.description
                    : item.name
                return (label, item.color)
            }
        
        photo = SummaryExport.firstPhoto(from: yarn.images)
        washColors = Array(palette.prefix(5))
    }
}

// MARK: - Shared chrome

private func summaryWash(_ colors: [Color]) -> [Color] {
    if colors.isEmpty {
        return [Color(red: 0.93, green: 0.90, blue: 0.86), Color(red: 0.86, green: 0.82, blue: 0.76)]
    }
    if colors.count == 1 {
        return [colors[0], colors[0].opacity(0.55)]
    }
    return colors
}

private struct SummaryFooter: View {
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text("WoolWallet")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.35))
        }
    }
}

private struct SummaryBadge: View {
    let text : String
    var tint : Color = Color.primary
    
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct SummaryColorCapsule: View {
    let name : String
    let color : Color
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
            
            Text(name)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.08), in: Capsule())
    }
}

/// Wraps chips onto leading-aligned lines for the export canvas
private struct SummaryChipFlow: Layout {
    var spacing : CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }
    
    private struct Row {
        var indices : [Int] = []
        var width : CGFloat = 0
        var height : CGFloat = 0
    }
    
    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows : [Row] = []
        var current = Row()
        
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.indices.isEmpty && current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.indices.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

private struct SummaryStatTile: View {
    let stat : YarnStat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stat.label.uppercased())
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.6)
            
            Text(stat.value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SummaryCompositionBar: View {
    let fibers : [YarnFiber]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Composition")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
            
            GeometryReader { proxy in
                HStack(spacing: 3) {
                    ForEach(Array(fibers.enumerated()), id: \.offset) { _, fiber in
                        Capsule()
                            .fill(fiber.color)
                            .frame(width: proxy.size.width * CGFloat(fiber.percentage) / 100)
                    }
                }
            }
            .frame(height: 18)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(fibers.enumerated()), id: \.offset) { _, fiber in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(fiber.color)
                            .frame(width: 18, height: 18)
                        
                        Text("\(fiber.percentage)% \(fiber.label)")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

private struct SummaryColorRibbon: View {
    let colors : [Color]
    
    var body: some View {
        let wash = summaryWash(colors)
        
        HStack(spacing: 0) {
            ForEach(Array(wash.enumerated()), id: \.offset) { _, color in
                color
            }
        }
        .frame(height: 28)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Project card

private struct ProjectSummaryCard: View {
    let data : ProjectSummaryData
    
    private var wash: [Color] { summaryWash(data.washColors) }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
                
                if let photo = data.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
            .frame(height: 640)
            
            if !data.washColors.isEmpty {
                SummaryColorRibbon(colors: data.washColors)
                    .padding(.horizontal, 56)
                    .padding(.top, 28)
            }
            
            VStack(alignment: .leading, spacing: 18) {
                Text(data.title)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                
                if let designer = data.designer {
                    Text("by \(designer)")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
                
                if let patternMeta = data.patternMeta {
                    Text(patternMeta)
                        .font(.system(size: 26))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    SummaryBadge(text: data.statusTitle, tint: data.statusColor)
                    
                    if let progress = data.progressText {
                        Text(progress)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let dateLine = data.dateLine {
                    Text(dateLine)
                        .font(.system(size: 26))
                        .foregroundStyle(Color.secondary)
                }
                
                if !data.yarns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(data.yarns.count == 1 ? "Yarn" : "Yarns")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .textCase(.uppercase)
                        
                        ForEach(Array(data.yarns.prefix(4))) { yarn in
                            HStack(spacing: 12) {
                                if !yarn.colors.isEmpty {
                                    HStack(spacing: -6) {
                                        ForEach(Array(yarn.colors.prefix(3).enumerated()), id: \.offset) { _, color in
                                            Circle()
                                                .fill(color)
                                                .frame(width: 22, height: 22)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        }
                                    }
                                }
                                
                                Text(yarn.title)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if data.yarns.count > 4 {
                            Text("+\(data.yarns.count - 4) more")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer(minLength: 0)
                
                SummaryFooter()
            }
            .padding(.horizontal, 56)
            .padding(.top, data.washColors.isEmpty ? 44 : 28)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.22)
                    .background(Color.white)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Yarn card

private struct YarnSummaryCard: View {
    let data : YarnSummaryData
    
    private var wash: [Color] { summaryWash(data.washColors) }
    
    var body: some View {
        VStack(spacing: 0) {
            hero
            
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(data.name)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                    
                    if let dyer = data.dyer {
                        Text(dyer)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                    
                    if !data.badges.isEmpty || !data.colorNames.isEmpty {
                        // Wrap badges + color capsules like yarn details
                        SummaryChipFlow {
                            ForEach(data.badges, id: \.self) { badge in
                                SummaryBadge(text: badge)
                            }
                            
                            ForEach(Array(data.colorNames.prefix(6).enumerated()), id: \.offset) { _, item in
                                SummaryColorCapsule(name: item.name, color: item.color)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                
                if !data.stats.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(Array(data.stats.enumerated()), id: \.offset) { _, stat in
                            SummaryStatTile(stat: stat)
                        }
                    }
                }
                
                if !data.fibers.isEmpty {
                    SummaryCompositionBar(fibers: data.fibers)
                }
                
                Spacer(minLength: 0)
                
                SummaryFooter()
            }
            .padding(.horizontal, 52)
            .padding(.top, 36)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.2)
                    .background(Color.white)
            }
        }
        .background(Color.white)
    }
    
    /// Photo as a floating card centered in the yarn colors — or a bold wash when there's no photo
    private var hero: some View {
        LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(maxWidth: .infinity)
            .frame(height: 860)
            .overlay {
                if data.photo == nil, data.washColors.count > 1 {
                    // Soft overlapping color orbs when there's no photo to show
                    ForEach(Array(data.washColors.prefix(4).enumerated()), id: \.offset) { index, color in
                        Circle()
                            .fill(color.opacity(0.55))
                            .frame(width: 280, height: 280)
                            .offset(
                                x: CGFloat([-160, 170, -40, 120][index]),
                                y: CGFloat([-40, 30, 120, -90][index])
                            )
                            .blur(radius: 8)
                    }
                }
            }
            .overlay {
                if let photo = data.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 700, height: 700)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36, style: .continuous)
                                .stroke(Color.white.opacity(0.85), lineWidth: 6)
                        )
                        .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
                }
            }
            .clipped()
    }
}
