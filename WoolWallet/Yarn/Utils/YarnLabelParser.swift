//
//  YarnLabelParser.swift
//  WoolWallet
//
//  Created by Mac on 10/14/26.
//

import Foundation
import UIKit
import Vision

/// A line of text read off a label, with its height relative to the photo so bigger print can be weighted higher
struct RecognizedLine {
    var text : String
    var height : CGFloat
}

/// Whatever could be read off a yarn label; every field is optional because labels vary wildly
struct ScannedYarnLabel: Equatable {
    var name : String? = nil
    var dyer : String? = nil
    var weight : Weight? = nil
    var length : Double? = nil
    var unitOfMeasure : UnitOfMeasure? = nil
    var grams : Int? = nil
    var composition : [CompositionItem] = []
    var colorway : String? = nil
    var dyeLot : String? = nil
    var isSockSet : Bool = false
    /// Label text that didn't go into any field, like care instructions or needle sizes, one line each
    var otherInfo : String? = nil
    
    /// Leftover text alone doesn't mean anything was read off a label
    var isEmpty : Bool {
        var details = self
        details.otherInfo = nil
        return details == ScannedYarnLabel()
    }
    
    /// How many details only a yarn label would have; a name alone can come from any stray text
    var labelDetailCount : Int {
        [dyer != nil, weight != nil, length != nil, grams != nil, !composition.isEmpty, isSockSet].filter { $0 }.count
    }
}

enum YarnLabelReader {
    /// Reads the whole photo, then smaller overlapping sections if the label is too small in the frame to read
    static func read(_ image: UIImage, knownDyers: [String]) async throws -> ScannedYarnLabel {
        var lines = try await LabelTextRecognizer.recognizeLines(in: image)
        var label = YarnLabelParser.parse(lines, knownDyers: knownDyers)
        
        // Each grid catches text the others cut through, so keep everything read so far
        for grid in [2, 3] where label.labelDetailCount < 2 {
            lines += try await LabelTextRecognizer.recognizeLines(in: image, grid: grid)
            label = YarnLabelParser.parse(lines, knownDyers: knownDyers)
        }
        
        return label
    }
}

enum LabelTextRecognizer {
    /// Splitting into a grid of overlapping tiles makes small print bigger relative to what Vision looks at;
    /// text under roughly half a percent of the photo's height isn't read at all otherwise
    static func recognizeLines(in image: UIImage, grid: Int = 1) async throws -> [RecognizedLine] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        return try await Task.detached(priority: .userInitiated) {
            try tiles(grid).flatMap { tile -> [RecognizedLine] in
                let pixelRect = CGRect(
                    x: tile.minX * CGFloat(cgImage.width),
                    y: tile.minY * CGFloat(cgImage.height),
                    width: tile.width * CGFloat(cgImage.width),
                    height: tile.height * CGFloat(cgImage.height)
                ).integral
                
                guard let tileImage = grid == 1 ? cgImage : cgImage.cropping(to: pixelRect) else { return [] }
                
                // Tiles are square fractions of the photo, so scaling by one side keeps heights comparable across passes
                return try recognizeLines(in: tileImage, orientation: orientation).map {
                    RecognizedLine(text: $0.text, height: $0.height * tile.height)
                }
            }
        }.value
    }
    
    private static func recognizeLines(in cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> [RecognizedLine] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        
        try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
        
        return (request.results ?? []).compactMap { observation -> RecognizedLine? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedLine(text: candidate.string, height: observation.boundingBox.height)
        }
    }
    
    /// Normalized tile rects covering the photo, overlapping so text on a seam is whole in at least one tile
    private static func tiles(_ grid: Int, overlap: CGFloat = 0.2) -> [CGRect] {
        guard grid > 1 else { return [CGRect(x: 0, y: 0, width: 1, height: 1)] }
        
        let side = 1 / (CGFloat(grid) - CGFloat(grid - 1) * overlap)
        let step = side * (1 - overlap)
        
        return (0..<grid).flatMap { row in
            (0..<grid).map { column in
                CGRect(x: CGFloat(column) * step, y: CGFloat(row) * step, width: side, height: side)
            }
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}

enum YarnLabelParser {
    static func parse(_ lines: [RecognizedLine], knownDyers: [String] = []) -> ScannedYarnLabel {
        let text = lines.map(\.text).joined(separator: "\n")
        var label = ScannedYarnLabel()
        
        if let yards = firstNumber(in: text, matching: yardsPattern) {
            label.length = yards
            label.unitOfMeasure = .yards
        } else if let meters = firstNumber(in: text, matching: metersPattern) {
            label.length = meters
            label.unitOfMeasure = .meters
        }
        
        if let grams = firstNumber(in: text, matching: gramsPattern) {
            label.grams = Int(grams.rounded())
        } else if let ounces = firstNumber(in: text, matching: ouncesPattern) {
            label.grams = Int((ounces * 28.3495).rounded())
        }
        
        label.weight = weight(in: text)
        label.isSockSet = sockSetPatterns.contains { matches(text, $0) }
        label.composition = composition(in: text)
        label.dyeLot = firstMatch(in: text, matching: dyeLotPattern)
        label.colorway = firstMatch(in: text, matching: colorwayPattern)
            // Colorway and dye lot often share a line
            .map { $0.replacingOccurrences(of: #"\s*\b(?:dye\s*lot|lot)\b.*$"#, with: "", options: [.regularExpression, .caseInsensitive]) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)) }
            .flatMap { $0.isEmpty ? nil : $0 }
        
        label.dyer = dyer(in: text, knownDyers: knownDyers)
        label.name = name(in: lines, excluding: [label.dyer, label.colorway].compactMap { $0 })
        label.otherInfo = otherInfo(in: lines, label: label)
        
        return label
    }
    
    private static let yardsPattern = #"(\d+(?:[.,]\d+)?)\s*(?:yds?|yards?)\b"#
    private static let metersPattern = #"(\d+(?:[.,]\d+)?)\s*(?:m|mts?|meters?|metres?)\b"#
    private static let gramsPattern = #"(\d+(?:[.,]\d+)?)\s*(?:g|gr|grams?|grammes?)\b"#
    private static let ouncesPattern = #"(\d+(?:[.,]\d+)?)\s*(?:oz|ounces?)\b"#
    private static let dyeLotPattern = #"\b(?:dye\s*lot|lot)\b\s*(?:no\.?|#|:)?\s*([A-Z0-9\-]*\d[A-Z0-9\-]*)"#
    private static let colorwayPattern = #"\b(?:colou?rway|colou?r|shade)\b\s*(?:name|no\.?|#|:)?\s*:?\s*([^\n]{2,40})"#
    private static let cycCategoryPattern = #"\(?\b([0-7])\b\)?\s*(?:lace|super\s*fine|fine|light|medium|bulky|super\s*bulky|jumbo)\b"#
    private static let compositionPattern = #"(\d{1,3})\s*%\s*([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ \-]*)"#
    
    // MARK: - Weight
    
    // Checked in order, so more specific phrases ("super bulky", "light worsted") come before the words they contain
    private static let weightKeywords : [(pattern: String, weight: Weight)] = [
        (#"\bsuper\s*(?:bulky|chunky)\b|\broving\b"#, .six),
        (#"\bjumbo\b"#, .seven),
        (#"\blight\s*worsted\b|\bdk\b|\bdouble\s*knit(?:ting)?\b|\b8\s*ply\b"#, .three),
        (#"\bworsted\b|\baran\b|\b10\s*ply\b"#, .four),
        (#"\bbulky\b|\bchunky\b|\b12\s*ply\b"#, .five),
        (#"\bsport\b|\b5\s*ply\b"#, .two),
        (#"\bfingering\b|\bsock\b|\b4\s*ply\b|\bsuper\s*fine\b"#, .one),
        (#"\blace\b|\bcobweb\b|\b[1-3]\s*ply\b"#, .zero)
    ]
    
    // Craft Yarn Council symbol text, e.g. "(4) MEDIUM"
    private static let cycCategories : [String: Weight] = [
        "0": .zero, "1": .one, "2": .two, "3": .three, "4": .four, "5": .five, "6": .six, "7": .seven
    ]
    
    private static func weight(in text: String) -> Weight? {
        for (pattern, weight) in weightKeywords where matches(text, pattern) {
            return weight
        }
        
        if let category = firstMatch(in: text, matching: cycCategoryPattern) {
            return cycCategories[category]
        }
        
        return nil
    }
    
    // MARK: - Sock set
    
    // "Sock Set", "sockset", "Sock-Set", "Socks Set", "Sock Yarn Set", "Sock Kit", "Sock & Mini", "Sock + Mini Set"
    private static let sockSetPatterns : [String] = [
        #"\bsocks?[\s\-]*(?:yarn[\s\-]*)?(?:sets?|kits?)\b"#,
        #"\bsocks?[\s\-]*(?:&|\+|and)[\s\-]*minis?\b"#
    ]
    
    // MARK: - Composition
    
    // Checked in order, so "suri alpaca" counts as suri rather than alpaca
    private static let materialKeywords : [(keywords: [String], material: MaterialCategory)] = [
        (["suri"], .suri),
        (["alpaca", "alpaga", "alpaka"], .alpaca),
        (["cashmere", "kaschmir", "cachemire", "cashmir"], .cashmere),
        (["mohair"], .mohair),
        (["silk", "soie", "seide", "seda", "seta"], .silk),
        (["cotton", "coton", "baumwolle", "algodón", "algodon", "cotone"], .cotton),
        (["linen", "flax", "leinen", "lino"], .linen),
        (["bamboo", "bambus", "bambou"], .bamboo),
        (["acrylic", "acrylique", "acryl", "acrílico", "acrilico"], .acrylic),
        (["nylon", "polyamide", "polyamid", "poliamida", "poliammide"], .nylon),
        (["rayon", "viscose", "viskose", "modal", "lyocell", "tencel"], .rayon),
        (["wool", "merino", "laine", "wolle", "lana", "bfl", "bluefaced", "corriedale", "rambouillet", "polwarth", "targhee", "shetland", "lambswool"], .wool)
    ]
    
    private static func composition(in text: String) -> [CompositionItem] {
        // "80% Merino Wool" and the less common "Merino Wool 80%"
        var pairs = allMatches(in: text, matching: compositionPattern)
            .compactMap { groups -> (Int, String)? in
                guard groups.count == 2, let percent = Int(groups[0]) else { return nil }
                return (percent, groups[1])
            }
        
        if pairs.isEmpty {
            pairs = allMatches(in: text, matching: #"([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ \-]*?)\s*(\d{1,3})\s*%"#)
                .compactMap { groups -> (Int, String)? in
                    guard groups.count == 2, let percent = Int(groups[1]) else { return nil }
                    return (percent, groups[0])
                }
        }
        
        var items : [CompositionItem] = []
        var total = 0
        
        // Labels often repeat the fibers in several languages, so stop once the first full 100% is accounted for
        for (percent, rawMaterial) in pairs where percent > 0 && total + percent <= 100 {
            let description = rawMaterial.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !description.isEmpty else { continue }
            
            let material = materialCategory(for: description)
            
            if let index = items.firstIndex(where: { $0.material == material.rawValue && material != .other }) {
                items[index].percentage += percent
            } else {
                items.append(
                    CompositionItem(
                        percentage: percent,
                        material: material.rawValue,
                        materialDescription: material == .other ? description.capitalized : ""
                    )
                )
            }
            
            total += percent
            if total == 100 { break }
        }
        
        return items
    }
    
    private static func materialCategory(for description: String) -> MaterialCategory {
        let lowercased = description.lowercased()
        
        for (keywords, material) in materialKeywords where keywords.contains(where: { lowercased.contains($0) }) {
            return material
        }
        
        return .other
    }
    
    // MARK: - Dyer & name
    
    private static let commonBrands : [String] = [
        "Malabrigo", "Madelinetosh", "Lion Brand", "Red Heart", "Bernat", "Caron", "Cascade", "Drops",
        "Rowan", "Knit Picks", "Patons", "Lana Grossa", "Sandnes Garn", "Hedgehog Fibres", "Paintbox",
        "Scheepjes", "Debbie Bliss", "Berroco", "Plymouth", "Noro", "Lang", "Katia", "Sirdar", "King Cole",
        "Stylecraft", "Wool and the Gang", "Brooklyn Tweed", "Woolfolk", "HiKoo", "Manos del Uruguay",
        "Universal Yarn", "Premier", "Loops & Threads", "Yarn Bee", "Hobbii", "Isager", "Lettlopi",
        "Istex", "Jamieson's", "Rauma", "Biches & Bûches", "La Bien Aimée", "Lamana", "Schachenmayr",
        "Juniper Moon", "Ella Rae", "Valley Yarns", "WeCrochet", "Fibra Natura", "Sweet Georgia",
        "Urth", "Neighborhood Fiber Co", "Miss Babs", "Dream in Color", "Spud & Chloë"
    ]
    
    private static func dyer(in text: String, knownDyers: [String]) -> String? {
        // Prefer dyers already in the stash so the name matches what the user typed before
        let candidates = knownDyers.sorted { $0.count > $1.count } + commonBrands
        
        // Whole words only, so a short brand like "Lang" doesn't match inside "language"
        return candidates.first { dyer in
            !dyer.isEmpty && matches(text, #"(?<![\p{L}\p{N}])"# + NSRegularExpression.escapedPattern(for: dyer) + #"(?![\p{L}\p{N}])"#)
        }
    }
    
    private static func name(in lines: [RecognizedLine], excluding excluded: [String]) -> String? {
        let excludedLowercased = excluded.map { $0.lowercased() }
        
        let candidates = lines.filter { line in
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = text.lowercased()
            let letterCount = text.filter(\.isLetter).count
            
            return text.count >= 2
                && text.count <= 40
                && letterCount >= text.count / 2
                && !lowercased.contains("%")
                && !matches(lowercased, #"\b(?:yds?|yards?|grams?|wash|dry|iron|bleach|needles?|hooks?|lot|made in|www\.|\.com)\b"#)
                && !excludedLowercased.contains(where: { lowercased == $0 || $0.contains(lowercased) })
                // A big "SOCK SET" banner isn't the yarn's name
                && !sockSetPatterns.contains(where: { matches(lowercased, "^\\W*" + $0 + "\\W*$") })
        }
        
        // The biggest print on a label is usually the yarn's name
        return candidates.max { $0.height < $1.height }?
            .text
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Other info
    
    // Field names left behind once their values are taken out, like "Net Wt:" or "Fiber Content:"
    private static let fieldLabelWords : Set<String> = [
        "weight", "wt", "net", "length", "yardage", "yards", "approx", "approximately", "ca", "fiber", "fibre",
        "fibers", "fibres", "content", "contents", "composition", "color", "colour", "colorway", "colourway",
        "shade", "dye", "lot", "no", "per", "skein", "ball", "hank", "each", "of", "and", "yarn"
    ]
    
    private static func otherInfo(in lines: [RecognizedLine], label: ScannedYarnLabel) -> String? {
        // Sock sets before weights, since "sock" alone is a weight
        var removals = [yardsPattern, metersPattern, gramsPattern, ouncesPattern, dyeLotPattern, compositionPattern, cycCategoryPattern]
            + sockSetPatterns
            + weightKeywords.map(\.pattern)
        
        if label.colorway != nil {
            removals.append(colorwayPattern)
        }
        
        for value in [label.dyer, label.name].compactMap({ $0 }) {
            removals.append(#"(?<![\p{L}\p{N}])"# + NSRegularExpression.escapedPattern(for: value) + #"(?![\p{L}\p{N}])"#)
        }
        
        var kept : [(text: String, key: String)] = []
        
        for line in lines {
            var text = line.text
            
            for pattern in removals {
                text = regex(pattern)?.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: " ") ?? text
            }
            
            // A percentage still here is fiber content written the other way round, like "Merino 80%"
            if matches(text, #"\d{1,3}\s*%"#) { continue }
            
            text = text
                .replacingOccurrences(of: #"\(\s*\)|\[\s*\]"#, with: " ", options: .regularExpression)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "/|-–—:;,•·*+&")))
            
            let words = text.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
            let visible = text.filter { !$0.isWhitespace }
            
            // Care symbols read as stray marks, so keep only lines that are mostly words and numbers
            guard text.filter(\.isLetter).count >= 3,
                  visible.filter({ $0.isLetter || $0.isNumber }).count * 2 >= visible.count,
                  !words.allSatisfy(fieldLabelWords.contains) else { continue }
            
            // The same line is often read more than once when small print is read in sections, sometimes cut short
            let key = text.lowercased().filter { $0.isLetter || $0.isNumber }
            
            if kept.contains(where: { $0.key.contains(key) }) { continue }
            
            if let index = kept.firstIndex(where: { key.contains($0.key) }) {
                kept[index] = (text, key)
                kept.removeAll { $0.key != key && key.contains($0.key) }
            } else {
                kept.append((text, key))
            }
        }
        
        return kept.isEmpty ? nil : kept.map(\.text).joined(separator: "\n")
    }
    
    // MARK: - Regex helpers
    
    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
    
    private static func matches(_ text: String, _ pattern: String) -> Bool {
        guard let regex = regex(pattern) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
    
    private static func firstMatch(in text: String, matching pattern: String) -> String? {
        allMatches(in: text, matching: pattern).first?.first
    }
    
    private static func firstNumber(in text: String, matching pattern: String) -> Double? {
        guard let match = firstMatch(in: text, matching: pattern) else { return nil }
        
        // "1,094" is a thousands separator; "3,5" is a European decimal
        let isThousands = matches(match, #"^\d{1,3},\d{3}$"#)
        return Double(match.replacingOccurrences(of: ",", with: isThousands ? "" : "."))
    }
    
    /// Capture groups for every match of the pattern
    private static func allMatches(in text: String, matching pattern: String) -> [[String]] {
        guard let regex = regex(pattern) else { return [] }
        
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
            (1..<match.numberOfRanges).compactMap { index in
                Range(match.range(at: index), in: text).map { String(text[$0]) }
            }
        }
    }
}
