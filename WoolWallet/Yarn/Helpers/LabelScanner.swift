//
//  LabelScanner.swift
//  WoolWallet
//
//  Created by Mac on 10/14/26.
//

import SwiftUI
import PhotosUI
import VisionKit

enum LabelField: CaseIterable, Hashable {
    case name, dyer, sockSet, weight, length, grams, composition, colorway, dyeLot, otherInfo
    
    var title : String {
        switch self {
        case .name:        return "Name"
        case .dyer:        return "Dyer"
        case .sockSet:     return "Sock Set"
        case .weight:      return "Weight"
        case .length:      return "Length"
        case .grams:       return "Grams"
        case .composition: return "Composition"
        case .colorway:    return "Colorway (added to notes)"
        case .dyeLot:      return "Dye Lot (added to notes)"
        case .otherInfo:   return "Other Info (added to notes)"
        }
    }
    
    var shortTitle : String {
        switch self {
        case .colorway: return "Colorway"
        case .dyeLot:   return "Dye Lot"
        case .otherInfo: return "Other Info"
        default:        return title
        }
    }
    
    func value(in label: ScannedYarnLabel) -> String? {
        switch self {
        case .name:   return label.name
        case .dyer:   return label.dyer
        case .sockSet: return label.isSockSet ? "Yes" : nil
        case .weight: return label.weight?.rawValue
        case .length:
            guard let length = label.length else { return nil }
            return "\(length.formatted) \((label.unitOfMeasure ?? .yards).rawValue.lowercased())"
        case .grams:
            return label.grams.map { "\($0) g" }
        case .composition:
            guard !label.composition.isEmpty else { return nil }
            return label.composition
                .map { "\($0.percentage)% \(YarnUtils.shared.getMaterial(item: $0))" }
                .joined(separator: ", ")
        case .colorway: return label.colorway
        case .dyeLot:   return label.dyeLot
        case .otherInfo: return label.otherInfo
        }
    }
    
    static func found(in label: ScannedYarnLabel) -> [LabelField] {
        allCases.filter { $0.value(in: label) != nil }
    }
}

struct LabelScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var knownDyers : [String]
    var onApply : (ScannedYarnLabel, Set<LabelField>, UIImage?) -> Void
    
    private enum Phase {
        case capturing
        case processing
        case review(ScannedYarnLabel, UIImage)
        case failed(String)
    }
    
    @State private var phase : Phase = .capturing
    @State private var scanner = DataScannerHandle()
    @State private var photoItem : PhotosPickerItem? = nil
    @State private var showCamera = false
    @State private var cameraImage : UIImage? = nil
    
    @MainActor
    private var liveScanningAvailable : Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .capturing:
                    if liveScanningAvailable {
                        liveScanner
                    } else {
                        photoFallback
                    }
                case .processing:
                    ProgressView("Reading Label...")
                case .review(let label, let image):
                    LabelScanReview(label: label, image: image) { editedLabel, fields, includePhoto in
                        onApply(editedLabel, fields, includePhoto ? image : nil)
                        dismiss()
                    } onRescan: {
                        phase = .capturing
                    }
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn't Read Label", systemImage: "text.viewfinder")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") { phase = .capturing }
                    }
                }
            }
            .navigationTitle("Scan Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    process(image)
                }
                self.photoItem = nil
            }
        }
        .onChange(of: cameraImage) {
            if let cameraImage {
                process(cameraImage)
                self.cameraImage = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            accessCameraView(selectedImage: $cameraImage)
                .ignoresSafeArea()
        }
    }
    
    private var liveScanner: some View {
        ZStack(alignment: .bottom) {
            DataScannerView(handle: scanner)
                .ignoresSafeArea(edges: .bottom)
            
            VStack(spacing: 16) {
                Text("Fill the frame with the label, then tap the shutter")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                
                HStack {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Choose Photo")
                    
                    Spacer()
                    
                    Button {
                        Task {
                            if let image = try? await scanner.capturePhoto() {
                                process(image)
                            }
                        }
                    } label: {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 4)
                            .background(Circle().fill(Color.white.opacity(0.85)).padding(6))
                            .frame(width: 74, height: 74)
                    }
                    .accessibilityLabel("Capture Label")
                    
                    Spacer()
                    
                    Color.clear.frame(width: 56, height: 56)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
        }
    }
    
    private var photoFallback: some View {
        ContentUnavailableView {
            Label("Scan a Yarn Label", systemImage: "text.viewfinder")
        } description: {
            Text("Take a clear, well-lit photo of the label and WoolWallet will fill in what it can read.")
        } actions: {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCamera = true }
                    .buttonStyle(.borderedProminent)
            }
            
            PhotosPicker("Choose Photo", selection: $photoItem, matching: .images)
        }
    }
    
    private func process(_ image: UIImage) {
        phase = .processing
        
        Task {
            do {
                let label = try await YarnLabelReader.read(image, knownDyers: knownDyers)
                
                phase = label.isEmpty
                    ? .failed("No yarn details were found. Try filling the frame with the label in good light.")
                    : .review(label, image)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

struct LabelScanReview: View {
    let label : ScannedYarnLabel
    let image : UIImage
    var allowsAddingPhoto : Bool
    var onApply : (ScannedYarnLabel, Set<LabelField>, Bool) -> Void
    var onRescan : (() -> Void)?
    
    @State private var draft : LabelDraft
    @State private var selected : Set<LabelField>
    @State private var includePhoto = false
    
    init(
        label: ScannedYarnLabel,
        image: UIImage,
        allowsAddingPhoto: Bool = true,
        onApply: @escaping (ScannedYarnLabel, Set<LabelField>, Bool) -> Void,
        onRescan: (() -> Void)? = nil
    ) {
        self.label = label
        self.image = image
        self.allowsAddingPhoto = allowsAddingPhoto
        self.onApply = onApply
        self.onRescan = onRescan
        _draft = State(initialValue: LabelDraft(label))
        _selected = State(initialValue: Set(LabelField.found(in: label)))
    }
    
    /// Based on the original scan so a row doesn't vanish while its value is being retyped
    private var foundFields : [LabelField] {
        LabelField.found(in: label)
    }
    
    /// Cleared fields can't be applied even if they're still checked
    private var fieldsToApply : Set<LabelField> {
        let edited = draft.label
        return selected.filter { $0.value(in: edited) != nil }
    }
    
    private func apply() {
        onApply(draft.label, fieldsToApply, includePhoto)
    }
    
    var body: some View {
        Form {
            Section {
                ZoomableImageView(image: image)
                    .aspectRatio(image.size, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Label Photo")
            } footer: {
                Text("Pinch the photo to zoom in. Fix anything that was read incorrectly, or uncheck it to leave it off the form.")
            }
            
            Section("Found on the Label") {
                ForEach(foundFields, id: \.self) { field in
                    fieldRow(field)
                }
            }
            
            if allowsAddingPhoto {
                Section {
                    Toggle("Add Label Photo to Yarn", isOn: $includePhoto)
                }
            }
            
            Section {
                Button("Fill Form", action: apply)
                    .disabled(fieldsToApply.isEmpty)
                
                if let onRescan {
                    Button("Scan Again", action: onRescan)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: draft) { oldDraft, newDraft in
            let oldLabel = oldDraft.label
            let newLabel = newDraft.label
            
            for field in foundFields where field.value(in: oldLabel) != field.value(in: newLabel) {
                selected.insert(field)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fill", action: apply)
                    .disabled(fieldsToApply.isEmpty)
            }
        }
    }
    
    private func fieldRow(_ field: LabelField) -> some View {
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
            .accessibilityLabel(field.shortTitle)
            .accessibilityValue(isSelected ? "Will be filled in" : "Will be skipped")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            
            VStack(alignment: .leading, spacing: 4) {
                Text(field.title)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                
                editor(for: field)
            }
        }
    }
    
    @ViewBuilder
    private func editor(for field: LabelField) -> some View {
        switch field {
        case .name:
            TextField("Name", text: $draft.name)
        case .dyer:
            TextField("Dyer", text: $draft.dyer)
        case .colorway:
            TextField("Colorway", text: $draft.colorway)
        case .dyeLot:
            TextField("Dye Lot", text: $draft.dyeLot)
        case .otherInfo:
            TextField("Other Info", text: $draft.otherInfo, axis: .vertical)
        case .length:
            HStack {
                TextField("Length", text: $draft.length)
                    .keyboardType(.decimalPad)
                
                Text(draft.unitOfMeasure.rawValue.lowercased())
                    .foregroundStyle(Color.secondary)
            }
        case .grams:
            HStack {
                TextField("Grams", text: $draft.grams)
                    .keyboardType(.numberPad)
                
                Text("g")
                    .foregroundStyle(Color.secondary)
            }
        case .sockSet, .weight, .composition:
            Text(field.value(in: label) ?? "")
        }
    }
}

/// Text-backed copy of a scanned label's free text fields so numbers can be retyped freely before they're parsed
private struct LabelDraft: Equatable {
    var name : String
    var dyer : String
    var length : String
    let unitOfMeasure : UnitOfMeasure
    var grams : String
    var colorway : String
    var dyeLot : String
    var otherInfo : String
    /// Shown as read, not edited
    let scanned : ScannedYarnLabel
    
    init(_ label: ScannedYarnLabel) {
        name = label.name ?? ""
        dyer = label.dyer ?? ""
        length = label.length?.formatted ?? ""
        unitOfMeasure = label.unitOfMeasure ?? .yards
        grams = label.grams.map(String.init) ?? ""
        colorway = label.colorway ?? ""
        dyeLot = label.dyeLot ?? ""
        otherInfo = label.otherInfo ?? ""
        scanned = label
    }
    
    var label : ScannedYarnLabel {
        var label = scanned
        
        label.name = Self.text(name)
        label.dyer = Self.text(dyer)
        label.length = Self.number(length).flatMap { $0 > 0 ? $0 : nil }
        label.unitOfMeasure = label.length == nil ? nil : unitOfMeasure
        label.grams = Self.number(grams).map { Int($0.rounded()) }.flatMap { $0 > 0 ? $0 : nil }
        label.colorway = Self.text(colorway)
        label.dyeLot = Self.text(dyeLot)
        label.otherInfo = Self.text(otherInfo)
        
        return label
    }
    
    private static func text(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private static func number(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return GlobalSettings.shared.numberFormatter.number(from: trimmed)?.doubleValue ?? Double(trimmed)
    }
}

/// Lets SwiftUI buttons drive the scanner's photo capture
final class DataScannerHandle {
    weak var controller : DataScannerViewController?
    
    @MainActor
    func capturePhoto() async throws -> UIImage? {
        try await controller?.capturePhoto()
    }
}

struct DataScannerView: UIViewControllerRepresentable {
    let handle : DataScannerHandle
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        handle.controller = controller
        return controller
    }
    
    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if !controller.isScanning {
            try? controller.startScanning()
        }
    }
    
    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: ()) {
        controller.stopScanning()
    }
}
