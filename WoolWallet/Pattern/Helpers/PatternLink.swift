//
//  PatternLink.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import WebKit

enum PatternLink {
    enum LinkError: LocalizedError {
        case invalid
        case unreachable(Int)
        case signInRequired
        case notShared
        case unsupported
        case emptyPage
        
        var errorDescription: String? {
            switch self {
            case .invalid:                return "That doesn't look like a link."
            case .unreachable(let code):  return "That link couldn't be opened (error \(code))."
            case .signInRequired:         return "That link needs you to sign in. Download the pattern in Safari, then import it from Files."
            case .notShared:              return "That Google Drive file isn't shared publicly. Change it to \"Anyone with the link\", or download it and import it from Files."
            case .unsupported:            return "That link isn't a PDF, image, or web page."
            case .emptyPage:              return "Nothing could be saved from that page."
            }
        }
    }
    
    /// Accepts what people usually paste: a missing "https://", and share links from cloud storage,
    /// which open a preview page unless they're changed to download the file itself
    static func downloadURL(for text: String) -> URL? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else { return nil }
        
        if trimmed.range(of: #"^https?://"#, options: [.regularExpression, .caseInsensitive]) == nil {
            trimmed = "https://" + trimmed
        }
        
        guard var components = URLComponents(string: trimmed),
              let host = components.host?.lowercased(),
              host.contains(".") || host == "localhost"
        else { return nil }
        
        if host == "dropbox.com" || host.hasSuffix(".dropbox.com") {
            var items = (components.queryItems ?? []).filter { $0.name != "dl" && $0.name != "raw" }
            items.append(URLQueryItem(name: "dl", value: "1"))
            components.queryItems = items
        } else if host == "drive.google.com", let id = googleDriveID(in: components) {
            return URL(string: "https://drive.google.com/uc?export=download&id=\(id)")
        }
        
        return components.url
    }
    
    struct File {
        let data : Data
        let name : String
        /// A web page's own text, which keeps labels with their values better than its printed PDF
        var text : PatternText? = nil
        /// The picture a web page shares as its preview, usually the finished piece
        var photo : UIImage? = nil
    }
    
    static func load(from url: URL) async throws -> File {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let finalURL = response.url ?? url
        
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw [401, 403].contains(http.statusCode) ? LinkError.signInRequired : LinkError.unreachable(http.statusCode)
        }
        
        let mimeType = response.mimeType?.lowercased() ?? ""
        
        if data.starts(with: Array("%PDF".utf8)) {
            try PatternFile.validate(data)
            return File(data: data, name: response.suggestedFilename ?? finalURL.lastPathComponent)
        }
        
        if mimeType.contains("html") {
            if finalURL.host?.lowercased().hasSuffix("google.com") == true && url.host == "drive.google.com" {
                throw LinkError.notShared
            }
            
            return try await WebPagePDF.render(finalURL)
        }
        
        if let image = UIImage(data: data) {
            let name = ((response.suggestedFilename ?? finalURL.lastPathComponent) as NSString).deletingPathExtension
            return File(data: await PatternFile.pdfData(from: [image]), name: name.isEmpty ? "Pattern Image" : name)
        }
        
        throw LinkError.unsupported
    }
    
    fileprivate static func image(at url: URL) async -> UIImage? {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true
        else { return nil }
        
        return UIImage(data: data)
    }
    
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    
    private static func googleDriveID(in components: URLComponents) -> String? {
        let path = components.path.split(separator: "/")
        
        if let index = path.firstIndex(of: "d"), index + 1 < path.count {
            return String(path[index + 1])
        }
        
        return components.queryItems?.first { $0.name == "id" }?.value
    }
}

/// Saves a pattern web page as letter-sized PDF pages, keeping the text so it can still fill in the form
@MainActor
private final class WebPagePDF: NSObject, WKNavigationDelegate {
    private let webView : WKWebView
    private var continuation : CheckedContinuation<Void, Error>?
    
    private static let maxPages = 60
    
    private override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }
    
    static func render(_ url: URL) async throws -> PatternLink.File {
        let page = WebPagePDF()
        try await page.load(url)
        try await page.prepareForPrinting()
        
        let details = await page.details()
        let title = details?.title.flatMap(withoutSiteName)
        let data = page.pdfData(title: title)
        
        guard PatternFile.pageCount(of: data) > 0 else { throw PatternLink.LinkError.emptyPage }
        
        var photo : UIImage? = nil
        if let imageURL = details?.imageURL {
            photo = await PatternLink.image(at: imageURL)
        }
        
        return PatternLink.File(
            data: data,
            name: title ?? url.host ?? "Web Pattern",
            text: details.map { patternText(from: $0, title: title) },
            photo: photo
        )
    }
    
    private func load(_ url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.load(URLRequest(url: url, timeoutInterval: 30))
            
            // Pages that keep loading ads or trackers may never finish, but the pattern is there by now
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(20))
                self?.finishLoading(nil)
            }
        }
    }
    
    private func finishLoading(_ error: Error?) {
        // A page that redirects itself cancels the first load and starts another
        if let error, (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCancelled { return }
        
        guard let continuation else { return }
        self.continuation = nil
        
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
    
    /// Images that only load when scrolled to would print blank, and banners pinned to the screen would cover the pattern
    private func prepareForPrinting() async throws {
        _ = try? await webView.callAsyncJavaScript("""
            document.querySelectorAll('img').forEach(function (img) {
                img.loading = 'eager';
                var src = img.dataset.src || img.dataset.lazySrc || img.dataset.original;
                if (src && (!img.getAttribute('src') || img.src.startsWith('data:'))) { img.src = src; }
                var srcset = img.dataset.srcset || img.dataset.lazySrcset;
                if (srcset) { img.srcset = srcset; }
            });
            document.querySelectorAll('body *').forEach(function (element) {
                if (getComputedStyle(element).position === 'fixed') { element.remove(); }
            });
            """, contentWorld: .page)
        
        try await Task.sleep(for: .seconds(1.5))
    }
    
    private struct PageDetails {
        var title : String?
        var imageURL : URL?
        var text : String
        /// Headings by their text, so the parser can tell titles from body text as it does in a PDF
        var headingSizes : [String: Double]
        var bodySize : Double
    }
    
    private func details() async -> PageDetails? {
        let result = try? await webView.callAsyncJavaScript("""
            var meta = function (name) {
                var element = document.querySelector('meta[property="' + name + '"], meta[name="' + name + '"]');
                return element ? element.content : null;
            };
            var headingSizes = {};
            document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach(function (heading) {
                var text = heading.innerText.trim();
                if (text && text.length < 150) {
                    headingSizes[text] = Math.max(headingSizes[text] || 0, parseFloat(getComputedStyle(heading).fontSize) || 0);
                }
            });
            var image = meta('og:image') || meta('twitter:image');
            return {
                title: meta('og:title') || document.title,
                image: image ? new URL(image, document.baseURI).href : null,
                text: document.body.innerText,
                headingSizes: headingSizes,
                bodySize: parseFloat(getComputedStyle(document.body).fontSize) || 16
            };
            """, contentWorld: .page) as? [String: Any]
        
        guard let result, let text = result["text"] as? String else { return nil }
        
        return PageDetails(
            title: result["title"] as? String,
            imageURL: (result["image"] as? String).flatMap(URL.init(string:)),
            text: text,
            headingSizes: (result["headingSizes"] as? [String: Any])?.compactMapValues { ($0 as? NSNumber)?.doubleValue } ?? [:],
            bodySize: (result["bodySize"] as? NSNumber)?.doubleValue ?? 16
        )
    }
    
    /// Table rows come through as tab-separated cells, "Hook⇥5 mm", so the first cell becomes a label
    private static func patternText(from details: PageDetails, title: String?) -> PatternText {
        let linesPerPage = 50
        
        let lines = details.text
            .components(separatedBy: .newlines)
            .map { row -> String in
                let cells = row.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                guard let first = cells.first else { return "" }
                return cells.count > 1 ? first + ": " + cells.dropFirst().joined(separator: " ") : first
            }
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .filter { !$0.isEmpty }
            .prefix(linesPerPage * 12)
        
        var text = PatternText()
        text.documentTitle = title
        text.lines = lines.enumerated().map { index, line in
            PatternLine(text: line, size: details.headingSizes[line] ?? details.bodySize, page: index / linesPerPage)
        }
        text.pageCount = (text.lines.count + linesPerPage - 1) / linesPerPage
        return text
    }
    
    /// "Cozy Hat | Jane's Crochet Blog" → "Cozy Hat"
    private static func withoutSiteName(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: " | ").flatMap { $0.components(separatedBy: " – ") }.flatMap { $0.components(separatedBy: " — ") }
        
        if parts.count > 1, let first = parts.first, first.filter(\.isLetter).count >= 3 {
            return first.trimmingCharacters(in: .whitespaces)
        }
        
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func pdfData(title: String?) -> Data {
        let renderer = LetterPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
        
        let pageCount = min(renderer.numberOfPages, Self.maxPages)
        guard pageCount > 0 else { return Data() }
        
        let format = UIGraphicsPDFRendererFormat()
        if let title {
            format.documentInfo = [kCGPDFContextTitle as String: title]
        }
        
        return UIGraphicsPDFRenderer(bounds: renderer.paperRect, format: format).pdfData { context in
            renderer.prepare(forDrawingPages: NSRange(location: 0, length: pageCount))
            
            for page in 0..<pageCount {
                context.beginPage()
                renderer.drawPage(at: page, in: context.pdfContextBounds)
            }
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in finishLoading(nil) }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in finishLoading(error) }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in finishLoading(error) }
    }
}

private final class LetterPageRenderer: UIPrintPageRenderer {
    private let paper = CGRect(x: 0, y: 0, width: 612, height: 792)
    
    override var paperRect: CGRect { paper }
    override var printableRect: CGRect { paper.insetBy(dx: 36, dy: 36) }
}

/// Paste a link to a pattern PDF, web page, or a Dropbox or Google Drive share link
struct PatternLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onImport : (PatternLink.File) -> Void
    
    @State private var link : String = ""
    @State private var isLoading : Bool = false
    @State private var errorMessage : String? = nil
    @State private var loadTask : Task<Void, Never>? = nil
    @FocusState private var isFocused : Bool
    
    private var url : URL? {
        PatternLink.downloadURL(for: link)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if link.isEmpty, !isLoading {
                    Section {
                        PasteButton(payloadType: String.self) { strings in
                            applyPasted(strings.first)
                        }
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    } footer: {
                        Text("Paste a PDF, web page, Dropbox, or Google Drive link. Import starts automatically.")
                    }
                }
                
                Section {
                    HStack(spacing: 10) {
                        TextField("Pattern Link", text: $link, prompt: Text(link.isEmpty ? "or type a link…" : "https://"))
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.go)
                            .focused($isFocused)
                            .disabled(isLoading)
                            .onSubmit(importLink)
                        
                        if !link.isEmpty, !isLoading {
                            Button {
                                link = ""
                                errorMessage = nil
                                isFocused = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear Link")
                        }
                    }
                } header: {
                    if link.isEmpty, !isLoading {
                        Text("Or type it")
                    }
                } footer: {
                    if !link.isEmpty {
                        Text("Web pages are saved as a PDF you can read offline.")
                    }
                }
                
                if isLoading {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Downloading the pattern…")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                } else if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Import from Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        loadTask?.cancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import", action: importLink)
                        .disabled(url == nil || isLoading)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    PasteButton(payloadType: String.self) { strings in
                        applyPasted(strings.first)
                    }
                    
                    Spacer()
                }
            }
            .onChange(of: link) {
                errorMessage = nil
            }
            .onAppear {
                // Prefer paste; only focus the field if they need to type
                if link.isEmpty {
                    isFocused = false
                }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }
    
    private func applyPasted(_ raw: String?) {
        guard let pasted = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !pasted.isEmpty else { return }
        
        link = pasted
        errorMessage = nil
        
        // One tap from clipboard to download when the paste is already a link
        if PatternLink.downloadURL(for: pasted) != nil {
            importLink()
        }
    }
    
    private func importLink() {
        guard !isLoading else { return }
        
        guard let url else {
            errorMessage = PatternLink.LinkError.invalid.localizedDescription
            return
        }
        
        isFocused = false
        isLoading = true
        errorMessage = nil
        
        loadTask = Task {
            do {
                let file = try await PatternLink.load(from: url)
                guard !Task.isCancelled else { return }
                
                onImport(file)
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
