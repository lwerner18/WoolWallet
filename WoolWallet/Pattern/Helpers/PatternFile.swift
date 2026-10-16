//
//  PatternFile.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import PDFKit
import VisionKit
import UniformTypeIdentifiers

enum PatternFile {
    enum ImportError: LocalizedError {
        case unreadable
        case locked
        
        var errorDescription: String? {
            switch self {
            case .unreadable: return "That file couldn't be opened as a pattern."
            case .locked:     return "That PDF is password protected. Unlock it in another app and try again."
            }
        }
    }
    
    /// A PDF, or photos and screenshots of a pattern made into one
    static func load(from urls: [URL]) async throws -> (data: Data, name: String) {
        guard let first = urls.first else { throw ImportError.unreadable }
        
        let accessing = urls.map { $0.startAccessingSecurityScopedResource() }
        defer {
            for (url, didAccess) in zip(urls, accessing) where didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if let pdfURL = urls.first(where: { UTType(filenameExtension: $0.pathExtension)?.conforms(to: .pdf) == true }) {
            let data = try Data(contentsOf: pdfURL)
            try validate(data)
            return (data, pdfURL.lastPathComponent)
        }
        
        let images = urls.compactMap { try? Data(contentsOf: $0) }.compactMap(UIImage.init(data:))
        guard !images.isEmpty else { throw ImportError.unreadable }
        
        return (await pdfData(from: images), first.deletingPathExtension().lastPathComponent)
    }
    
    static func validate(_ data: Data) throws {
        guard let document = PDFDocument(data: data), document.pageCount > 0 else { throw ImportError.unreadable }
        guard !document.isLocked else { throw ImportError.locked }
    }
    
    /// One page per photo, compressed so a long scanned pattern doesn't take up much room
    static func pdfData(from images: [UIImage]) async -> Data {
        await Task.detached(priority: .userInitiated) {
            let pageWidth : CGFloat = 612
            
            let pages : [UIImage] = images.map { image in
                let downsized = downsize(image, maxPixels: 2200)
                return downsized.jpegData(compressionQuality: 0.7).flatMap(UIImage.init(data:)) ?? downsized
            }
            
            let firstSize = pageSize(for: pages.first, width: pageWidth)
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: firstSize))
            
            return renderer.pdfData { context in
                for page in pages {
                    let bounds = CGRect(origin: .zero, size: pageSize(for: page, width: pageWidth))
                    context.beginPage(withBounds: bounds, pageInfo: [:])
                    page.draw(in: bounds)
                }
            }
        }.value
    }
    
    /// First page for cover cards and file previews — not stored as a pattern photo
    static func firstPageImage(of data: Data, maxPixels: CGFloat = 1200) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let page = PDFDocument(data: data)?.page(at: 0) else { return nil }
            
            let bounds = page.bounds(for: .mediaBox)
            let scale = maxPixels / max(bounds.width, bounds.height, 1)
            return page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
        }.value
    }
    
    /// Cached with the file so list covers don't reopen every PDF
    static func coverThumbnailData(of data: Data) async -> Data? {
        await firstPageImage(of: data, maxPixels: PatternCoverLoader.maxPixelSize)?.jpegData(compressionQuality: 0.8)
    }
    
    static func pageCount(of data: Data) -> Int {
        PDFDocument(data: data)?.pageCount ?? 0
    }
    
    private static func pageSize(for image: UIImage?, width: CGFloat) -> CGSize {
        guard let image, image.size.width > 0 else { return CGSize(width: width, height: 792) }
        return CGSize(width: width, height: width * image.size.height / image.size.width)
    }
    
    private static func downsize(_ image: UIImage, maxPixels: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let scale = min(1, maxPixels / max(pixelWidth, pixelHeight))
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let size = CGSize(width: (pixelWidth * scale).rounded(), height: (pixelHeight * scale).rounded())
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

/// The system document camera, which finds page edges and flattens each page
struct DocumentScanner: UIViewControllerRepresentable {
    var onScan : ([UIImage]) -> Void
    var onCancel : () -> Void
    
    static var isSupported : Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent : DocumentScanner
        
        init(parent: DocumentScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.onScan((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
        }
    }
}

/// Parts of the pattern form that can be filled in from a pattern file
enum PatternField: CaseIterable, Hashable {
    case name, designer, type, items, tools, yarn, size, techniques, notions, gauge
    
    func title(for pattern: ScannedPattern) -> String {
        switch self {
        case .name:       return "Name"
        case .designer:   return "Designer"
        case .type:       return "Type"
        case .items:      return "Makes"
        case .tools:      return pattern.type == .knit || (pattern.hooks.isEmpty && !pattern.needles.isEmpty) ? "Needles" : "Hooks"
        case .yarn:       return "Yarn"
        case .size:       return "Size"
        case .techniques: return "Techniques"
        case .notions:    return "Notions"
        case .gauge:      return "Gauge (added to notes)"
        }
    }
    
    func value(in pattern: ScannedPattern) -> String? {
        switch self {
        case .name:
            return pattern.name
        case .designer:
            return pattern.designer
        case .type:
            return pattern.type?.rawValue
        case .items:
            return list(pattern.items.map(\.rawValue))
        case .tools:
            return list(pattern.hooks.map(\.rawValue) + pattern.needles.map(\.rawValue))
        case .yarn:
            return yarnSummary(pattern)
        case .size:
            return pattern.oneSize ? "One Size" : pattern.intendedSize
        case .techniques:
            return list(pattern.techniques.map(\.rawValue))
        case .notions:
            return list(pattern.notions.map(\.rawValue) + pattern.otherNotions)
        case .gauge:
            return pattern.gauge
        }
    }
    
    static func found(in pattern: ScannedPattern) -> [PatternField] {
        allCases.filter { $0.value(in: pattern) != nil }
    }
    
    private func list(_ values: [String]) -> String? {
        values.isEmpty ? nil : values.joined(separator: ", ")
    }
    
    private func yarnSummary(_ pattern: ScannedPattern) -> String? {
        let unit = (pattern.unitOfMeasure ?? .yards).rawValue.lowercased()
        var parts : [String] = []
        
        if let weight = pattern.weight {
            parts.append(weight.rawValue)
        }
        
        if let yardage = pattern.yardagePerSkein, let grams = pattern.gramsPerSkein {
            parts.append("\(yardage.formatted) \(unit) / \(grams)g")
        }
        
        if let total = pattern.totalLength {
            parts.append("\(total.formatted) \(unit) needed")
        } else if let skeins = pattern.skeins {
            parts.append("\(skeins.formatted) skein\(skeins == 1 ? "" : "s")")
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// What was read from a pattern file, to check over before it goes into the form
struct PatternFillReview: View {
    @Environment(\.dismiss) private var dismiss
    
    let pattern : ScannedPattern
    let photo : UIImage?
    /// A web page's preview picture is shown instead of its first page
    let photoIsFirstPage : Bool
    var allowsAddingPhoto : Bool
    var onApply : (ScannedPattern, Set<PatternField>, Bool) -> Void
    
    @State private var name : String
    @State private var designer : String
    @State private var selected : Set<PatternField>
    @State private var includePhoto : Bool
    
    init(pattern: ScannedPattern, photo: UIImage?, photoIsFirstPage: Bool = true, allowsAddingPhoto: Bool, suggestsPhoto: Bool, onApply: @escaping (ScannedPattern, Set<PatternField>, Bool) -> Void) {
        self.pattern = pattern
        self.photo = photo
        self.photoIsFirstPage = photoIsFirstPage
        self.allowsAddingPhoto = allowsAddingPhoto
        self.onApply = onApply
        _name = State(initialValue: pattern.name ?? "")
        _designer = State(initialValue: pattern.designer ?? "")
        _selected = State(initialValue: Set(PatternField.found(in: pattern)))
        _includePhoto = State(initialValue: allowsAddingPhoto && suggestsPhoto)
    }
    
    private var foundFields : [PatternField] {
        PatternField.found(in: pattern)
    }
    
    private var editedPattern : ScannedPattern {
        var edited = pattern
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesigner = designer.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.name = trimmedName.isEmpty ? nil : trimmedName
        edited.designer = trimmedDesigner.isEmpty ? nil : trimmedDesigner
        return edited
    }
    
    /// Cleared fields can't be applied even if they're still checked
    private var fieldsToApply : Set<PatternField> {
        let edited = editedPattern
        return selected.filter { $0.value(in: edited) != nil }
    }
    
    private func apply() {
        onApply(editedPattern, fieldsToApply, includePhoto)
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let photo {
                    Section {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel(photoIsFirstPage ? "First Page of the Pattern" : "Pattern Photo")
                    } footer: {
                        Text("Fix anything that was read incorrectly, or uncheck it to leave it off the form.")
                    }
                }
                
                Section("Found in the Pattern") {
                    ForEach(foundFields, id: \.self) { field in
                        fieldRow(field)
                    }
                }
                
                if allowsAddingPhoto && photo != nil && !photoIsFirstPage {
                    Section {
                        Toggle("Add Pattern Photo", isOn: $includePhoto)
                    }
                }
                
                Section {
                    Button("Fill Form", action: apply)
                        .disabled(fieldsToApply.isEmpty && !includePhoto)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Fill from Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fill", action: apply)
                        .disabled(fieldsToApply.isEmpty && !includePhoto)
                }
            }
            .onChange(of: name) { selected.insert(.name) }
            .onChange(of: designer) { selected.insert(.designer) }
        }
    }
    
    private func fieldRow(_ field: PatternField) -> some View {
        let isSelected = selected.contains(field)
        
        return HStack(spacing: 12) {
            Button {
                if isSelected {
                    selected.remove(field)
                } else {
                    selected.insert(field)
                }
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(field.title(for: pattern))
            .accessibilityValue(isSelected ? "Will be filled in" : "Will be skipped")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            
            VStack(alignment: .leading, spacing: 4) {
                Text(field.title(for: pattern))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                
                switch field {
                case .name:
                    TextField("Name", text: $name)
                case .designer:
                    TextField("Designer", text: $designer)
                default:
                    Text(field.value(in: pattern) ?? "")
                }
            }
        }
    }
}
