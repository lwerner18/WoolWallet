//
//  PatternReader.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import PDFKit
import CoreData


struct ReadPatternButton: View {
    var action : () -> Void
    
    var body: some View {
        Button(action: action) {
            // Info pages set a primary foreground on everything, which would make this black on blue
            Label("Read Pattern", systemImage: "book.pages")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 12))
    }
}

/// A saved pattern file, opened where it was last left off
struct SavedPatternReader: View {
    @ObservedObject var document : PatternDocument
    let title : String
    var project : Project? = nil
    
    var body: some View {
        if let data = document.data {
            PatternReader(data: data, title: title, startPage: Int(document.lastPage), project: project) { page in
                guard !document.isDeleted, document.lastPage != Int16(page) else { return }
                
                document.lastPage = Int16(page)
                PersistenceController.shared.save()
            }
        }
    }
}

struct PatternReader: View {
    @Environment(\.dismiss) private var dismiss
    
    let title : String
    var project : Project?
    var onClose : ((_ page: Int) -> Void)?
    
    @State private var document : PDFDocument?
    @State private var currentPage : Int
    @AppStorage("patternReaderShowsCounters") private var showsCounters = true
    
    private let startPage : Int
    
    init(data: Data, title: String, startPage: Int = 0, project: Project? = nil, onClose: ((_ page: Int) -> Void)? = nil) {
        self.title = title
        self.project = project
        self.onClose = onClose
        self.startPage = startPage
        _document = State(initialValue: PDFDocument(data: data))
        _currentPage = State(initialValue: startPage)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let document {
                    PDFKitView(document: document, startPage: startPage, currentPage: $currentPage)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .bottom) {
                            if document.pageCount > 1 {
                                Text("Page \(currentPage + 1) of \(document.pageCount)")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.regularMaterial, in: Capsule())
                                    .padding(.bottom, 8)
                                    .accessibilityAddTraits(.updatesFrequently)
                            }
                        }
                } else {
                    ContentUnavailableView("Can't Open Pattern", systemImage: "doc.questionmark", description: Text("This file couldn't be read."))
                }
                
                if let project, showsCounters {
                    ReaderRowCounters(project: project)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                
                if project != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                showsCounters.toggle()
                            }
                        } label: {
                            Label(showsCounters ? "Hide Row Counters" : "Show Row Counters", systemImage: showsCounters ? "number.circle.fill" : "number.circle")
                        }
                    }
                }
            }
        }
        // Keeps the screen on while both hands are busy crafting
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            onClose?(currentPage)
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let document : PDFDocument
    let startPage : Int
    @Binding var currentPage : Int
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.pageShadowsEnabled = true
        view.backgroundColor = .secondarySystemBackground
        
        context.coordinator.observe(view)
        
        // Pages can only be scrolled to once the view has been laid out
        if startPage > 0, let page = document.page(at: min(startPage, document.pageCount - 1)) {
            DispatchQueue.main.async {
                view.go(to: page)
            }
        }
        
        return view
    }
    
    func updateUIView(_ view: PDFView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }
    
    final class Coordinator {
        let currentPage : Binding<Int>
        private var observer : NSObjectProtocol?
        
        init(currentPage: Binding<Int>) {
            self.currentPage = currentPage
        }
        
        func observe(_ view: PDFView) {
            observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak self, weak view] _ in
                guard let view, let page = view.currentPage, let index = view.document?.index(for: page) else { return }
                self?.currentPage.wrappedValue = index
            }
        }
        
        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

/// The project's row counters, kept under the pattern so the count can go up without leaving it
private struct ReaderRowCounters: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    let project : Project
    @FetchRequest private var counters : FetchedResults<RowCounter>
    
    init(project: Project) {
        self.project = project
        _counters = FetchRequest(
            entity: RowCounter.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \RowCounter.order, ascending: true)],
            predicate: NSPredicate(format: "project == %@", project)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(counters) { counter in
                        CompactRowCounter(counter: counter)
                    }
                    
                    Button(action: addCounter) {
                        Label(counters.isEmpty ? "Add Row Counter" : "Add", systemImage: "plus")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .frame(minHeight: 56)
                            .background(Color(UIColor.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Add Row Counter")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .background(.bar)
    }
    
    private func addCounter() {
        project.addRowCounter(in: managedObjectContext)
    }
}

/// A small counter with minus and plus buttons, for counting under the pattern or on a project card
struct CompactRowCounter: View {
    @ObservedObject var counter : RowCounter
    var background : Color = Color(UIColor.secondarySystemBackground)
    
    @State private var showRename = false
    @State private var draftName = ""
    
    var body: some View {
        HStack(spacing: 4) {
            Button {
                counter.adjust(by: -1)
                PersistenceController.shared.save()
            } label: {
                Image(systemName: "minus")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }
            .disabled(counter.count <= 0)
            .accessibilityLabel("Decrease \(counter.name ?? "Count")")
            
            Menu {
                Button {
                    draftName = counter.name ?? ""
                    showRename = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Button {
                    withAnimation {
                        counter.resetCount()
                    }
                    PersistenceController.shared.save()
                } label: {
                    Label("Reset to 0", systemImage: "arrow.counterclockwise")
                }
            } label: {
                VStack(spacing: 0) {
                    Text(counter.name ?? "")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                    
                    Text("\(counter.count)")
                        .font(.title2.bold().monospacedDigit())
                        .contentTransition(.numericText(value: Double(counter.count)))
                }
                .frame(minWidth: 64)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("\(counter.name ?? "Count"), \(counter.count)")
            .accessibilityHint("Opens options to rename or reset")
            
            Button {
                withAnimation {
                    counter.adjust(by: 1)
                }
                PersistenceController.shared.save()
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Increase \(counter.name ?? "Count")")
        }
        .padding(.horizontal, 6)
        .frame(minHeight: 56)
        .background(background, in: RoundedRectangle(cornerRadius: 12))
        .rowCounterRenameAlert(counter: counter, isPresented: $showRename, draftName: $draftName)
        .sensoryFeedback(.increase, trigger: counter.count)
    }
}
