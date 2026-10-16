//
//  PatternCover.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import CoreData

enum PatternSort: String, CaseIterable, Identifiable {
    case name          = "Name"
    case recentlyAdded = "Recently Added"
    case designer      = "Designer"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .name:          return "textformat"
        case .recentlyAdded: return "clock"
        case .designer:      return "person"
        }
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        let byName = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        
        switch self {
        case .name:
            return [byName]
        case .recentlyAdded:
            // Patterns from before dates were tracked have none and go last
            return [NSSortDescriptor(key: "dateAdded", ascending: false), byName]
        case .designer:
            return [NSSortDescriptor(key: "designer", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))), byName]
        }
    }
}

enum PatternLayout: String, CaseIterable, Identifiable {
    case grid = "Grid"
    case list = "List"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

/// Where a pattern stands across the projects made from it
enum PatternStatus {
    case inProgress
    case made(Int)
    case planned
    
    init?(pattern: Pattern) {
        let projects = pattern.projectsArray
        let completed = projects.filter(\.complete).count
        
        if projects.contains(where: \.inProgress) {
            self = .inProgress
        } else if completed > 0 {
            self = .made(completed)
        } else if !projects.isEmpty {
            self = .planned
        } else {
            return nil
        }
    }
    
    var title: String {
        switch self {
        case .inProgress:      return "In Progress"
        case .made(let count): return count == 1 ? "Made" : "Made \(count)×"
        case .planned:         return "Planned"
        }
    }
    
    var systemImage: String {
        switch self {
        case .inProgress: return "hammer.fill"
        case .made:       return "checkmark.circle.fill"
        case .planned:    return "bookmark.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .inProgress: return Color.green
        case .made:       return Color.accentColor
        case .planned:    return Color.orange
        }
    }
}

extension Pattern {
    /// "Beanie, Scarf", using the description for "Other" items
    var itemNames: String? {
        let names = patternItems.compactMap { item -> String? in
            switch item.item {
            case .none:  return nil
            case .other: return item.description.isEmpty ? nil : item.description
            default:     return item.item.rawValue
            }
        }
        
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
    
    /// "Crochet · Beanie"
    var typeAndItems: String {
        [type, itemNames].compactMap { $0 }.joined(separator: " · ")
    }
}

extension View {
    /// Status in the top left and the file's page count in the top right, as on the pattern list
    func patternCoverBadges(for pattern: Pattern, status: PatternStatus?, padding: CGFloat = 6) -> some View {
        self
            .overlay(alignment: .topLeading) {
                if let status {
                    PatternCoverBadge(text: status.title, systemImage: status.systemImage, iconColor: status.color)
                        .padding(padding)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let document = pattern.document {
                    PatternCoverBadge(text: pageCountText(document) ?? "PDF", systemImage: "doc.text")
                        .padding(padding)
                }
            }
    }
}

/// Cover art for cards and details: real photos first, otherwise the pattern file's first page.
/// The file page is display-only — it is not stored as a pattern photo.
enum PatternCoverLoader {
    static let maxPixelSize : CGFloat = 600
    
    private static let cache : NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 60 * 1024 * 1024
        return cache
    }()
    
    /// Changes when the photos or the file change, so an edited pattern gets a new cover
    @MainActor
    static func key(for pattern: Pattern) -> String {
        let photos = StoredImage.objectIDs(from: pattern.images).map { $0.uriRepresentation().absoluteString }.joined(separator: ",")
        return "\(photos)|\(pattern.document?.id?.uuidString ?? "")"
    }
    
    @MainActor
    static func cached(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    @MainActor
    static func load(for pattern: Pattern, key: String) async -> UIImage? {
        if let cached = cached(for: key) {
            return cached
        }
        
        var image : UIImage? = nil
        let photoIDs = StoredImage.objectIDs(from: pattern.images)
        
        if !photoIDs.isEmpty {
            image = await StoredImage.loadThumbnails(for: photoIDs).first?.image
        } else if let document = pattern.document {
            if let thumbnail = document.thumbnail {
                image = await Task.detached(priority: .userInitiated) {
                    UIImage.downsampled(from: thumbnail, maxPixelSize: maxPixelSize)
                }.value
            } else if let data = document.data {
                image = await PatternFile.firstPageImage(of: data, maxPixels: maxPixelSize)
            }
        }
        
        if let image {
            let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
            cache.setObject(image, forKey: key as NSString, cost: cost)
        }
        
        return image
    }
}

struct PatternCover: View {
    @ObservedObject var pattern : Pattern
    var cornerRadius : CGFloat = 10
    var iconSize : Size = Size.large
    
    @State private var image : UIImage? = nil
    
    var body: some View {
        let key = PatternCoverLoader.key(for: pattern)
        
        Color.clear
            .overlay {
                if let cover = image ?? PatternCoverLoader.cached(for: key) {
                    Image(uiImage: cover)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .task(id: key) {
                image = await PatternCoverLoader.load(for: pattern, key: key)
            }
            .accessibilityHidden(true)
    }
    
    private var placeholder: some View {
        let display = PatternUtils.shared.getItemDisplay(for: pattern.patternItems.first?.item)
        
        return ZStack {
            LinearGradient(
                colors: [display.color.opacity(0.35), display.color.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            PatternItemDisplay(pattern: pattern, size: iconSize)
        }
    }
}

/// Small label laid over a cover
struct PatternCoverBadge: View {
    var text : String?
    var systemImage : String
    var iconColor : Color = Color.primary
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .foregroundStyle(iconColor)
            
            if let text {
                Text(text)
            }
        }
        .font(.caption2.bold())
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private func pageCountText(_ document: PatternDocument) -> String? {
    document.pageCount > 0 ? "\(document.pageCount)" : nil
}

private func accessibilitySummary(for pattern: Pattern, status: PatternStatus?) -> String {
    var parts = [pattern.name ?? "No Name"]
    
    if let designer = pattern.designer, !designer.isEmpty {
        parts.append("by \(designer)")
    }
    
    parts.append(pattern.type ?? "")
    
    if let items = pattern.itemNames {
        parts.append(items)
    }
    
    if let document = pattern.document {
        parts.append(document.pageCount > 0 ? "\(document.pageCount) page pattern file" : "Has a pattern file")
    }
    
    if let status {
        parts.append(status.title)
    }
    
    return parts.filter { !$0.isEmpty }.joined(separator: ", ")
}

/// A pattern in the grid, shown like a book cover
struct PatternCard: View {
    @ObservedObject var pattern : Pattern
    
    var body: some View {
        let status = PatternStatus(pattern: pattern)
        
        VStack(alignment: .leading, spacing: 8) {
            PatternCover(pattern: pattern)
                .aspectRatio(3 / 4, contentMode: .fit)
                .patternCoverBadges(for: pattern, status: status)
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.name ?? "No Name")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let designer = pattern.designer, !designer.isEmpty {
                    Text(designer)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                Text(pattern.typeAndItems)
                    .font(.caption2)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary(for: pattern, status: status))
    }
}

/// A pattern in the list, with a small cover in place of the item icon
struct PatternRow: View {
    @ObservedObject var pattern : Pattern
    
    var body: some View {
        let status = PatternStatus(pattern: pattern)
        
        HStack(spacing: 12) {
            PatternCover(pattern: pattern, cornerRadius: 6, iconSize: Size.small)
                .frame(width: 54, height: 72)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(pattern.name ?? "No Name")
                    .foregroundStyle(Color.primary)
                    .bold()
                    .lineLimit(2)
                
                if let designer = pattern.designer, !designer.isEmpty {
                    Text(designer)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.footnote)
                        .bold()
                        .lineLimit(1)
                }
                
                HStack(spacing: 10) {
                    Text(pattern.typeAndItems)
                        .lineLimit(1)
                    
                    // Labels would space their icons wide and pull the row divider over to their text
                    if let document = pattern.document {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text")
                            Text(pageCountText(document) ?? "PDF")
                        }
                    }
                    
                    if let status {
                        HStack(spacing: 3) {
                            Image(systemName: status.systemImage)
                                .foregroundStyle(status.color)
                            Text(status.title)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(Color(UIColor.secondaryLabel))
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary(for: pattern, status: status))
    }
}
