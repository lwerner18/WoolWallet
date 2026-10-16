//
//  PatternParser.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import Foundation
import PDFKit
import UIKit
import Vision

/// A line of pattern text and how big it was printed, so the title can be told apart from the body
struct PatternLine {
    var text : String
    var size : CGFloat
    var page : Int
}

struct PatternText {
    var lines : [PatternLine] = []
    /// The title saved in the PDF's properties, which can be better than guessing from the first page
    var documentTitle : String? = nil
    var pageCount : Int = 0
    
    var fullText : String {
        lines.map(\.text).joined(separator: "\n")
    }
}

/// Whatever could be read out of a pattern; every field is optional because patterns are laid out every which way
struct ScannedPattern: Equatable {
    var name : String? = nil
    var designer : String? = nil
    var type : PatternType? = nil
    var items : [Item] = []
    var hooks : [CrochetHookSize] = []
    var needles : [KnitNeedleSize] = []
    var weight : Weight? = nil
    var unitOfMeasure : UnitOfMeasure? = nil
    var yardagePerSkein : Double? = nil
    var gramsPerSkein : Int? = nil
    var totalLength : Double? = nil
    var skeins : Double? = nil
    var oneSize : Bool = false
    var intendedSize : String? = nil
    var techniques : [PatternTechnique] = []
    var notions : [PatternNotion] = []
    /// Supplies with no matching notion, like safety eyes, added as "Other"
    var otherNotions : [String] = []
    var gauge : String? = nil
    
    var isEmpty : Bool {
        self == ScannedPattern()
    }
    
    var hasYarnDetails : Bool {
        weight != nil || yardagePerSkein != nil || gramsPerSkein != nil || totalLength != nil || skeins != nil
    }
}

enum PatternTextExtractor {
    /// Materials and abbreviations come early, so pages past the first few aren't read
    static func extract(from data: Data, maxPages: Int = 8) async -> PatternText {
        await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(data: data) else { return PatternText() }
            
            var result = PatternText(pageCount: document.pageCount)
            result.documentTitle = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
            
            for index in 0..<min(document.pageCount, maxPages) {
                guard let page = document.page(at: index) else { continue }
                
                var lines = textLines(of: page, index: index)
                
                // Scanned pages and photos have no text to read, only pictures of it
                if lines.map(\.text).joined().filter(\.isLetter).count < 20 {
                    lines = recognizedLines(of: page, index: index)
                }
                
                result.lines += lines
            }
            
            return result
        }.value
    }
    
    /// Line by line as printed; the page's plain text joins closely spaced lines into paragraphs
    private static func textLines(of page: PDFPage, index: Int) -> [PatternLine] {
        guard let selection = page.selection(for: page.bounds(for: .mediaBox)) else { return [] }
        
        return selection.selectionsByLine().compactMap { line in
            guard let text = line.string.map(clean), !text.isEmpty else { return nil }
            
            var size : CGFloat = 0
            if let attributed = line.attributedString {
                attributed.enumerateAttribute(.font, in: NSRange(location: 0, length: attributed.length)) { value, _, _ in
                    if let font = value as? UIFont {
                        size = max(size, font.pointSize)
                    }
                }
            }
            
            return PatternLine(text: text, size: size, page: index)
        }
    }
    
    private static func recognizedLines(of page: PDFPage, index: Int) -> [PatternLine] {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return [] }
        
        // Small print on a full page needs a good-sized render to be readable
        let scale = 2400 / max(bounds.width, bounds.height)
        let image = page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
        guard let cgImage = image.cgImage else { return [] }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        
        try? VNImageRequestHandler(cgImage: cgImage).perform([request])
        
        // Vision's origin is the bottom left, so the top of the page has the highest y
        let observations = (request.results ?? []).sorted { first, second in
            abs(first.boundingBox.midY - second.boundingBox.midY) < 0.005
                ? first.boundingBox.minX < second.boundingBox.minX
                : first.boundingBox.midY > second.boundingBox.midY
        }
        
        return observations.compactMap { observation in
            guard let text = observation.topCandidates(1).first.map({ clean($0.string) }), !text.isEmpty else { return nil }
            return PatternLine(text: text, size: observation.boundingBox.height * 1000, page: index)
        }
    }
    
    private static func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

enum PatternParser {
    static func parse(_ text: PatternText, fileName: String? = nil) -> ScannedPattern {
        var text = text
        text.lines = joinLoneLabels(text.lines.flatMap(splitAtLabels))
        
        let lines = text.lines.map(\.text)
        let fullText = lines.joined(separator: "\n")
        let frontText = text.lines.filter { $0.page < 2 }.map(\.text).joined(separator: "\n")
        
        var pattern = ScannedPattern()
        
        let title = name(in: text, fileName: fileName)
        pattern.name = title?.name
        // A byline in the title beats one found in the text, which can be a photo credit
        pattern.designer = title?.designer ?? designer(in: frontText) ?? copyrightHolder(in: fullText)
        pattern.type = type(in: fullText)
        
        // Subtitles like "Amigurumi Pattern" are printed bigger than the body text
        let firstPage = text.lines.filter { $0.page == 0 }
        let sizes = firstPage.map(\.size).sorted()
        let bodySize = sizes.isEmpty ? 0 : sizes[sizes.count / 2]
        let headlines = firstPage.filter { bodySize > 0 && $0.size > bodySize * 1.2 }.map(\.text).joined(separator: "\n")
        pattern.items = items(title: [pattern.name ?? "", headlines].joined(separator: "\n"), firstPage: firstPage.map(\.text).joined(separator: "\n"))
        
        let tools = toolSizes(in: lines)
        if pattern.type == .knit {
            pattern.needles = tools.needles
        } else if pattern.type != nil {
            pattern.hooks = tools.hooks
        } else {
            pattern.hooks = tools.hooks
            pattern.needles = tools.needles
        }
        
        readYarn(into: &pattern, lines: lines)
        
        pattern.oneSize = matches(fullText, #"\bone[\s-]*size\b"#)
        if !pattern.oneSize {
            pattern.intendedSize = intendedSize(in: lines)
            
            // "Sizes available: one"
            if let size = pattern.intendedSize, matches(size, #"^one(?:\s+size)?$"#) {
                pattern.oneSize = true
                pattern.intendedSize = nil
            }
        }
        
        if let type = pattern.type {
            pattern.techniques = techniques(in: fullText, for: type)
        }
        
        pattern.notions = notionKeywords.filter { matches(fullText, $0.pattern) }.map(\.notion)
        pattern.otherNotions = otherNotionKeywords.filter { matches(fullText, $0.pattern) }.map(\.name)
        pattern.gauge = gauge(in: lines)
        
        return pattern
    }
    
    /// Columns side by side can be read as one line, "Sizes: S (M, L) Gauge: 18 sts", so each label starts its own
    private static func splitAtLabels(_ line: PatternLine) -> [PatternLine] {
        let marked = line.text.replacingOccurrences(
            of: #"\s+(?=(?:gauge|tension|sizes?|finished\s+(?:size|measurements?)|materials|yarn|hooks?|needles?|notions|abbreviations)\s*:)"#,
            with: "\n",
            options: [.regularExpression, .caseInsensitive]
        )
        
        return marked.split(separator: "\n").map { PatternLine(text: String($0), size: line.size, page: line.page) }
    }
    
    private static let loneLabel = #"^(?:yarn(?:\s+weight)?|weight|yardage|meterage|gauge|tension|(?:needle|hook)s?(?:\s+sizes?)?|sizes?(?:\s+available)?|finished\s+(?:size|measurements?|dimensions)|designer)\s*:?$"#
    
    /// Detail lists on web pages put each label above its value, "Yarn weight" then "Fingering", so they're read as one line
    private static func joinLoneLabels(_ lines: [PatternLine]) -> [PatternLine] {
        var joined : [PatternLine] = []
        var index = 0
        
        while index < lines.count {
            let line = lines[index]
            
            if index + 1 < lines.count, matches(line.text, loneLabel) {
                let next = lines[index + 1]
                
                if next.page == line.page, next.text.count <= 160, !matches(next.text, loneLabel) {
                    let label = line.text.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                    joined.append(PatternLine(text: "\(label): \(next.text)", size: next.size, page: next.page))
                    index += 2
                    continue
                }
            }
            
            joined.append(line)
            index += 1
        }
        
        return joined
    }
    
    // MARK: - Name
    
    private static func name(in text: PatternText, fileName: String?) -> (name: String, designer: String?)? {
        if let title = text.documentTitle.flatMap(cleanTitle), isPlausibleTitle(title) {
            return splitByline(title)
        }
        
        let firstPage = text.lines.enumerated().filter { $0.element.page == 0 && isPlausibleTitle($0.element.text) }
        
        if let biggest = firstPage.max(by: { $0.element.size < $1.element.size }) {
            // max(by:) returns the last of equal sizes, but the first one is the title when the sizes tie
            let first = firstPage.first { $0.element.size == biggest.element.size } ?? biggest
            var title = first.element.text
            
            // Titles printed over two lines at the same size
            let nextIndex = first.offset + 1
            if nextIndex < text.lines.count {
                let next = text.lines[nextIndex]
                if next.page == 0, first.element.size > 0, abs(next.size - first.element.size) < 0.5,
                   isPlausibleTitle(next.text), title.count + next.text.count < 60 {
                    title += " " + next.text
                }
            }
            
            if let cleaned = cleanTitle(title), isPlausibleTitle(cleaned) {
                return splitByline(cleaned)
            }
        }
        
        if let fileName {
            let base = (fileName as NSString).deletingPathExtension
                .replacingOccurrences(of: #"[_\-]+"#, with: " ", options: .regularExpression)
            
            if let cleaned = cleanTitle(base), isPlausibleTitle(cleaned) {
                return splitByline(cleaned)
            }
        }
        
        return nil
    }
    
    private static func cleanTitle(_ title: String) -> String? {
        var cleaned = title
            .replacingOccurrences(of: #"^microsoft\s+word\s*-\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\.(?:docx?|pdf|pages)$"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\s*[-–—:|]?\s*(?:an?\s+)?(?:free\s+)?(?:easy\s+)?(?:crochet|knit(?:ting)?|tunisian(?:\s+crochet)?)?\s*pattern\s*$"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "-–—:|•")))
        
        // All capitals reads as shouting in a list
        if cleaned.contains(where: \.isUppercase) && !cleaned.contains(where: \.isLowercase) {
            let minorWords : Set<String> = ["a", "an", "and", "as", "at", "by", "for", "in", "of", "on", "or", "the", "to", "with"]
            
            cleaned = cleaned.capitalized
                .split(separator: " ")
                .enumerated()
                .map { index, word in index > 0 && minorWords.contains(word.lowercased()) ? word.lowercased() : String(word) }
                .joined(separator: " ")
        }
        
        return cleaned.isEmpty ? nil : cleaned
    }
    
    private static func isPlausibleTitle(_ text: String) -> Bool {
        let letters = text.filter(\.isLetter).count
        
        return letters >= 3
            && text.count <= 70
            && letters * 2 >= text.filter { !$0.isWhitespace }.count
            && !matches(text, #"https?:|www\.|\.com\b|@|©|copyright|all rights|^page\s*\d|^\d+\s*$|\b(?:designed|written|pattern)\s+by\b|^by\s"#)
            && !matches(text, #"^(?:free\s+)?(?:crochet|knit(?:ting)?|tunisian)?\s*patterns?$"#)
    }
    
    /// "Cozy Hat by Jane Doe" has the designer in the title
    private static func splitByline(_ title: String) -> (name: String, designer: String?) {
        if let parts = allMatches(in: title, matching: #"^(.{3,}?)\s+by\s+(.+)$"#).first, parts.count == 2,
           let designer = cleanDesigner(parts[1]) {
            return (parts[0], designer)
        }
        
        return (title, nil)
    }
    
    // MARK: - Designer
    
    private static let designerPatterns = [
        #"\b(?:designed|written|created|pattern|design)\s+by\s*:?\s*([^\n]+)"#,
        #"\bdesigner\s*:\s*([^\n]+)"#,
        #"(?m)^\s*by\s+([^\n]+)$"#
    ]
    
    private static func designer(in text: String) -> String? {
        for pattern in designerPatterns {
            for match in allMatches(in: text, matching: pattern) {
                if let designer = match.first.flatMap(cleanDesigner) {
                    return designer
                }
            }
        }
        
        return nil
    }
    
    private static func copyrightHolder(in text: String) -> String? {
        allMatches(in: text, matching: #"(?:©|\(c\)|\bcopyright\b)\s*(?:\d{4}(?:\s*[-–]\s*\d{4})?)?\s*,?\s*(?:by\s+)?([^\n]+)"#)
            .lazy
            .compactMap { $0.first.flatMap(cleanDesigner) }
            .first
    }
    
    private static func cleanDesigner(_ text: String) -> String? {
        let cleaned = text
            .replacingOccurrences(of: #"\s*(?:[|•·,;(]|\s[-–—]\s|\bfor\b|\ball\s+rights\b|\bwww\.|https?:|\b\d{4}\b|\.\s).*$"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        
        let words = cleaned.split(separator: " ")
        
        guard cleaned.filter(\.isLetter).count >= 2,
              cleaned.count <= 40,
              words.count <= 5,
              !matches(cleaned, #"\bpattern\b|\bcrochet\b|\bknit"#)
        else { return nil }
        
        return cleaned
    }
    
    // MARK: - Type
    
    private static func type(in text: String) -> PatternType? {
        if count(text, #"\btunisian\b|\btss\b|\btks\b"#) >= 2 {
            return .tunisian
        }
        
        let crochet = count(text, #"\bcrochet(?:ed|ing)?\b"#) * 3
            + count(text, #"\bhooks?\b"#) * 2
            + min(count(text, #"\b(?:sc|hdc|dc|tr|sl\s*st)(?:\d+|2tog)?\b"#), 20)
        
        // "Double knitting" is a yarn weight, and tapestry needles turn up in every kind of pattern
        let knit = (count(text, #"\bknit(?:s|ted|ting|wise)?\b"#) - count(text, #"\bdouble\s+knit(?:ting)?\b"#)) * 3
            + (count(text, #"\bneedles?\b"#) - count(text, #"\b(?:tapestry|yarn|darning|sewing|wool|cable)\s+needles?\b"#)) * 2
            + min(count(text, #"\b(?:k2tog|ssk|p2tog|purl|kfb|m1[lr]?|k\d+|p\d+)\b"#), 20)
        
        guard max(crochet, knit) > 0 else { return nil }
        
        return crochet >= knit ? .crochet : .knit
    }
    
    // MARK: - Items
    
    // Checked in order, and each match is taken out of the text so "sweater vest" isn't also a sweater
    private static let itemKeywords : [(item: Item, pattern: String)] = [
        (.cardigan, #"\bcardigans?\b"#),
        (.tankTop, #"\btank\s*tops?\b|\bcamis?\b|\bcamisoles?\b"#),
        (.vest, #"\b(?:sweater\s*)?vests?\b|\bwaistcoats?\b|\bslipovers?\b"#),
        (.sweater, #"\bsweaters?\b|\bpullovers?\b|\bjumpers?\b"#),
        (.shirt, #"\bt-?shirts?\b|\btees?\b|\bshirts?\b|\bblouses?\b|\bcrop\s*tops?\b"#),
        (.shawl, #"\bshawl(?:ette)?s?\b|\bwraps?\b|\bponchos?\b|\bstoles?\b"#),
        (.beanie, #"\bbeanies?\b|\bhats?\b|\btoques?\b|\bberets?\b|\bbonnets?\b|\bbalaclavas?\b"#),
        (.socks, #"\bsocks\b|\bslippers?\b"#),
        (.blanket, #"\bblankets?\b|\bafghans?\b|\bthrows?\b"#),
        (.scarf, #"\bscar(?:f|ves)\b|\bcowls?\b|\bsnoods?\b"#),
        (.mittens, #"\bmittens?\b|\bmitts?\b|\bgloves?\b"#),
        (.bag, #"\bbags?\b|\btotes?\b|\bpurses?\b|\bpouch(?:es)?\b|\bbackpacks?\b"#),
        (.amigurumi, #"\bamigurumi\b|\bplush(?:ie)?s?\b|\bstuffed\s+(?:animal|toy)s?\b|\btoys?\b"#),
        (.household, #"\bcoasters?\b|\bpot\s*holders?\b|\b(?:dish|wash)\s*cloths?\b|\bplacemats?\b|\bpillows?\b|\bcushions?\b|\bbaskets?\b|\brugs?\b|\bornaments?\b"#)
    ]
    
    private static func items(title: String, firstPage: String) -> [Item] {
        var remaining = title
        var found : [Item] = []
        
        for (item, pattern) in itemKeywords where matches(remaining, pattern) {
            found.append(item)
            remaining = remaining.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        
        if !found.isEmpty {
            return Array(found.prefix(2))
        }
        
        // Otherwise whatever the first page talks about most
        let counted = itemKeywords
            .map { (item: $0.item, count: count(firstPage, $0.pattern)) }
            .filter { $0.count >= 2 }
            .max { $0.count < $1.count }
        
        return counted.map { [$0.item] } ?? []
    }
    
    // MARK: - Hooks and needles
    
    private static func toolSizes(in lines: [String]) -> (hooks: [CrochetHookSize], needles: [KnitNeedleSize]) {
        var hooks : [CrochetHookSize] = []
        var needles : [KnitNeedleSize] = []
        
        for (index, line) in lines.enumerated() {
            let isHookLine = matches(line, #"\bhooks?\b"#)
            let isNeedleLine = matches(line, #"\bneedles?\b"#) && !matches(line, #"\b(?:tapestry|yarn|darning|sewing|wool|cable)\s+needles?\b"#)
            guard isHookLine || isNeedleLine else { continue }
            
            // A heading like "Hook:" can have its size on the next line
            var text = line
            if !matches(line, #"\d"#), index + 1 < lines.count {
                text += " " + lines[index + 1]
            }
            
            let metricSizes = allMatches(in: text, matching: #"(\d{1,2}(?:[.,]\d{1,2})?)\s*mm\b"#).compactMap { $0.first.flatMap(number) }
            
            if isHookLine {
                for size in metricSizes {
                    if let hook = CrochetHookSize.allCases.first(where: { millimeters(of: $0.rawValue) == size }), !hooks.contains(hook) {
                        hooks.append(hook)
                    }
                }
            }
            
            if isNeedleLine {
                var sizes = metricSizes.compactMap { size in KnitNeedleSize.allCases.first { millimeters(of: $0.rawValue) == size } }
                
                if sizes.isEmpty {
                    sizes = allMatches(in: text, matching: #"\bus\s*(?:size\s*)?(\d{1,2}(?:\.5)?)\b"#)
                        .compactMap { $0.first.flatMap(number) }
                        .compactMap { us in KnitNeedleSize.allCases.first { usSize(of: $0.rawValue) == us } }
                }
                
                for needle in sizes where !needles.contains(needle) {
                    needles.append(needle)
                }
            }
        }
        
        return (hooks, needles)
    }
    
    /// "5mm (H-8)" is 5
    private static func millimeters(of rawValue: String) -> Double? {
        allMatches(in: rawValue, matching: #"^(\d+(?:\.\d+)?)mm"#).first?.first.flatMap(Double.init)
    }
    
    /// "4.5mm (7)" is US 7
    private static func usSize(of rawValue: String) -> Double? {
        allMatches(in: rawValue, matching: #"\((\d+(?:\.\d+)?)\)"#).first?.first.flatMap(Double.init)
    }
    
    // MARK: - Yarn
    
    private static let lengthUnit = #"(yds?|yards?|m|meters?|metres?)\b"#
    private static let amount = #"(\d{1,3}(?:,\d{3})+|\d+(?:[.,]\d+)?)"#
    
    private static func readYarn(into pattern: inout ScannedPattern, lines: [String]) {
        let yarnLines = lines.filter { matches($0, #"\byarns?\b|\bweight\b|\bwool\b|\bply\b|\bcyc\b|\bskeins?\b|\bballs?\b|\bhanks?\b|\byds?\b|\byards?\b"#) }
        let yarnText = yarnLines.joined(separator: "\n")
        
        pattern.weight = YarnLabelParser.weight(in: yarnText)
            ?? allMatches(in: yarnText, matching: #"(?:weight|category|cyc|#)\s*[:#]?\s*([0-7])\b"#).first?.first.flatMap(cycWeight)
        
        // "100g / 200 yds" or "200 yds / 100g" describes one skein
        if let match = allMatches(in: yarnText, matching: amount + #"\s*(?:g|grams?)\s*(?:[/=,(–-]|per|\s)\s*"# + amount + #"\s*"# + lengthUnit).first, match.count == 3 {
            pattern.gramsPerSkein = number(match[0]).map { Int($0.rounded()) }
            pattern.yardagePerSkein = number(match[1])
            pattern.unitOfMeasure = unit(match[2])
        } else if let match = allMatches(in: yarnText, matching: amount + #"\s*"# + lengthUnit + #"\s*(?:[/=,(–-]|per|\s)\s*"# + amount + #"\s*(?:g|grams?)\b"#).first, match.count == 3 {
            pattern.yardagePerSkein = number(match[0])
            pattern.unitOfMeasure = unit(match[1])
            pattern.gramsPerSkein = number(match[2]).map { Int($0.rounded()) }
        }
        
        // Sized patterns list every size, "800 (900, 1000) yds"; the first is the smallest
        // Ranges, "569 - 574 yards", also start with the smallest
        let totalPatterns = [
            #"\b(?:yardage|meterage)\s*:?\s*"# + amount + #"(?:\s*[-–]\s*\d[\d.,]*)?\s*(?:\([^)]*\)\s*)?"# + lengthUnit,
            #"(?:approx(?:imately|\.)?|about|total(?:\s+of)?|~|requires?|need(?:ed)?)\s*:?\s*"# + amount + #"\s*(?:\([^)]*\)\s*)?"# + lengthUnit,
            amount + #"\s*[-–]\s*\d[\d.,]*\s*(?:\([^)]*\)\s*)?"# + lengthUnit,
            amount + #"\s*(?:\([^)]*\)\s*)?(yds?|yards?|meters?|metres?)\b"#
        ]
        
        for totalPattern in totalPatterns where pattern.totalLength == nil {
            for match in allMatches(in: yarnText, matching: totalPattern) where match.count == 2 {
                guard let length = number(match[0]), length != pattern.yardagePerSkein else { continue }
                
                pattern.totalLength = length
                pattern.unitOfMeasure = pattern.unitOfMeasure ?? unit(match[1])
                break
            }
        }
        
        if let skeins = allMatches(in: yarnText, matching: #"(\d+(?:\.\d+)?)\s*(?:\([^)]*\)\s*)?(?:skeins?|balls?|hanks?|cakes?)\b"#).first?.first.flatMap(number), skeins > 0 {
            pattern.skeins = skeins
        }
    }
    
    private static func cycWeight(_ category: String) -> Weight? {
        switch category {
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        default: return nil
        }
    }
    
    private static func unit(_ text: String) -> UnitOfMeasure {
        text.lowercased().hasPrefix("y") ? .yards : .meters
    }
    
    // MARK: - Size
    
    private static func intendedSize(in lines: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            guard let match = allMatches(in: line, matching: #"^\s*(?:sizes?(?:\s+available)?|finished\s+(?:size|measurements?|dimensions)|dimensions)\s*:?\s*(.*)$"#).first?.first else { continue }
            
            var size = match.trimmingCharacters(in: .whitespacesAndNewlines)
            if size.count < 2, index + 1 < lines.count {
                size = lines[index + 1]
            }
            
            if size.filter({ $0.isLetter || $0.isNumber }).count >= 2 {
                return String(size.prefix(80))
            }
        }
        
        return nil
    }
    
    // MARK: - Gauge
    
    private static func gauge(in lines: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            guard let match = allMatches(in: line, matching: #"^\s*(?:gauge|tension)\b\s*:?\s*(.*)$"#).first?.first else { continue }
            
            var gauge = match.trimmingCharacters(in: .whitespacesAndNewlines)
            if gauge.count < 5, index + 1 < lines.count {
                gauge = lines[index + 1]
            }
            
            if matches(gauge, #"\d"#) {
                return String(gauge.prefix(160))
            }
        }
        
        return nil
    }
    
    // MARK: - Techniques
    
    private static let techniqueKeywords : [(technique: PatternTechnique, pattern: String)] = [
        // Crochet
        (.slipKnot, #"\bslip\s*knot\b"#),
        (.chainStitch, #"\bch(?:\d+|ain)?\b"#),
        (.singleCrochet, #"\bsc(?:\d+|2tog)?\b|\bsingle\s+crochet\b"#),
        (.halfDoubleCrochet, #"\bhdc(?:\d+|2tog)?\b|\bhalf\s+double\s+crochet\b"#),
        (.doubleCrochet, #"\bdc(?:\d+|2tog)?\b|(?<!half\s)(?<!post\s)\bdouble\s+crochet\b"#),
        (.tripleCrochet, #"\b(?:tr|trc|tc)\b|\btr(?:eb|ip)le\s+crochet\b"#),
        (.slipStitch, #"\bsl\s*st\b|\bslip\s+stitch\b"#),
        (.shellStitch, #"\bshells?\b"#),
        (.vStitch, #"\bv[\s-]*st(?:itch)?\b"#),
        (.grannySquare, #"\bgranny\b"#),
        (.bobbleStitch, #"\bbobbles?\b"#),
        (.clusterStitch, #"\bclusters?\b|\bcl\b"#),
        (.crossStitch, #"\bcross(?:ed)?[\s-]*st(?:itch)?(?:es)?\b"#),
        (.frontPostStitch, #"\bfront\s+post\b|\bfp(?:sc|hdc|dc|tr)\b"#),
        (.backPostStitch, #"\bback\s+post\b|\bbp(?:sc|hdc|dc|tr)\b"#),
        (.colorChanges, #"\bchange\s+(?:to\s+)?colou?rs?\b|\bcolou?r\s+changes?\b|\bcolou?r\s+[a-d]\b"#),
        (.joinAsYouGo, #"\bjoin[\s-]+as[\s-]+you[\s-]+go\b|\bjaygo?\b"#),
        (.foundationRowTechniques, #"\bfoundation\s+(?:single|half|double|chain|row)|\bf(?:sc|hdc|dc)\b"#),
        (.surfaceCrochet, #"\bsurface\s+(?:crochet|slip)"#),
        (.overlayCrochet, #"\boverlay\b"#),
        
        // Knitting
        (.castingOn, #"\bcast[\s-]*on\b|\bCO\b"#),
        (.bindingOff, #"\bbind[\s-]*off\b|\bcast[\s-]*off\b|\bBO\b"#),
        (.knitStitch, #"\bknit\b|\bk\d+\b|\bk2tog\b"#),
        (.purlStitch, #"\bpurl\b|\bp\d+\b|\bp2tog\b"#),
        (.garterStitch, #"\bgarter\b"#),
        (.stockinetteStitch, #"\bstockinette\b|\bstocking\s+stitch\b|\bst\s*st\b"#),
        (.ribbing, #"\brib(?:bing|bed)?\b"#),
        (.cableKnitting, #"\bcables?\b(?!\s*needle)|\bc\d+[bf]\b"#),
        (.laceKnitting, #"\blace\b(?![\s-]*weight)"#),
        (.colorwork, #"\bcolou?rwork\b|\bfair\s*isle\b|\bstranded\b|\bintarsia\b"#),
        (.shortRows, #"\bshort[\s-]*rows?\b|\bw&t\b|\bwrap\s+(?:and|&)\s+turn\b"#),
        (.mosaicKnitting, #"\bmosaic\b"#),
        (.twistedStitches, #"\btwisted\s+stitch(?:es)?\b|\btbl\b|\bthrough\s+the\s+back\s+loop"#),
        (.kitchenerStitch, #"\bkitchener\b|\bgraft(?:ing)?\b"#),
        (.entrelac, #"\bentrelac\b"#),
        (.feltedKnitting, #"\bfelt(?:ed|ing)\b"#),
        (.threeNeedleBindOff, #"\b(?:three|3)[\s-]*needle\s+bind[\s-]*off\b"#),
        (.seaming, #"\bseam(?:ing|ed|s)?\b|\bmattress\s+stitch\b"#),
        (.blocking, #"\bblock(?:ing|ed)?\b"#),
        (.beading, #"\bbead(?:s|ed|ing)?\b"#),
        (.iCord, #"\bi-?cord\b"#),
        
        // Tunisian
        (.tunisianSimpleStitch, #"\btss\b|\btunisian\s+simple\s+stitch\b"#),
        (.tunisianKnitStitch, #"\btks\b|\btunisian\s+knit\s+stitch\b"#),
        (.tunisianPurlStitch, #"\btps\b|\btunisian\s+purl\s+stitch\b"#),
        (.tunisianFullStitch, #"\btfs\b|\btunisian\s+full\s+stitch\b"#),
        (.tunisianReverseStitch, #"\btrs\b|\btunisian\s+reverse\s+stitch\b"#),
        (.tunisianLaceStitch, #"\blace\b(?![\s-]*weight)"#),
        (.tunisianShellStitch, #"\bshells?\b"#),
        (.tunisianHoneycombStitch, #"\bhoneycomb\b"#),
        (.tunisianColorwork, #"\bcolou?rwork\b|\bcolou?r\s+changes?\b"#),
        (.tunisianRibbing, #"\brib(?:bing|bed)?\b"#),
        (.tunisianDoubleCrochet, #"\btdc\b|\btunisian\s+double\s+crochet\b"#),
        (.tunisianEntrelac, #"\bentrelac\b"#),
        (.tunisianChevronStitch, #"\bchevrons?\b"#)
    ]
    
    private static func techniques(in text: String, for type: PatternType) -> [PatternTechnique] {
        let allowed : [PatternTechnique]
        switch type {
        case .crochet:  allowed = PatternUtils.shared.crochetTechniques()
        case .knit:     allowed = PatternUtils.shared.knitTechniques()
        case .tunisian: allowed = PatternUtils.shared.tunisianTechniques()
        }
        
        return techniqueKeywords
            .filter { allowed.contains($0.technique) && matches(text, $0.pattern) }
            .map(\.technique)
    }
    
    // MARK: - Notions
    
    private static let notionKeywords : [(notion: PatternNotion, pattern: String)] = [
        (.stitchMarkers, #"\b(?:stitch|locking|removable)?\s*markers?\b"#),
        (.tapestryNeedles, #"\b(?:tapestry|yarn|wool)\s*needles?\b"#),
        (.darningNeedle, #"\bdarning\s*needles?\b"#),
        (.cableNeedles, #"\bcable\s*needles?\b"#),
        (.scissors, #"\bscissors\b"#),
        (.yarnSnips, #"\bsnips\b"#),
        (.measuringTape, #"\bmeasuring\s*tape\b|\btape\s*measure\b"#),
        (.stitchHolders, #"\bstitch\s*holders?\b|\b(?:scrap|waste)\s*yarn\b"#),
        (.pomPomMaker, #"\bpom[\s-]?pom\s*makers?\b"#),
        (.rowCounters, #"\brow\s*counters?\b"#),
        (.blockingMats, #"\bblocking\s*(?:mats?|boards?|pins?|wires?)\b"#),
        (.needleGauge, #"\bneedle\s*gauge\b"#)
    ]
    
    private static let otherNotionKeywords : [(name: String, pattern: String)] = [
        ("Safety Eyes", #"\bsafety\s*eyes\b"#),
        ("Fiberfill", #"\bfib(?:er|re)\s*fill\b|\bpoly(?:ester)?[\s-]*fil(?:l|ling)?\b|\bstuffing\b"#),
        ("Buttons", #"\bbuttons?\b"#),
        ("Zipper", #"\bzipp?ers?\b"#),
        ("Elastic", #"\belastic\b"#)
    ]
    
    // MARK: - Helpers
    
    private static func number(_ text: String) -> Double? {
        // "1,200" is a thousands separator; "3,5" is a European decimal
        let isThousands = matches(text, #"^\d{1,3}(?:,\d{3})+$"#)
        return Double(text.replacingOccurrences(of: ",", with: isThousands ? "" : "."))
    }
    
    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
    
    private static func matches(_ text: String, _ pattern: String) -> Bool {
        guard let regex = regex(pattern) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
    
    private static func count(_ text: String, _ pattern: String) -> Int {
        guard let regex = regex(pattern) else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
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
