import Foundation
import CoreData
import Combine

@MainActor
final class YarnListViewModel: NSObject, ObservableObject {
    // Publicly observed yarns for the view
    @Published private(set) var yarns: [Yarn] = []
    @Published private(set) var activeCount: Int = 0
    @Published private(set) var archivedCount: Int = 0
    
    private var countCancellable: AnyCancellable?

    
    // Internal
    private var fetchedResultsController: NSFetchedResultsController<Yarn>?
    private var context: NSManagedObjectContext?
    private var isStarted = false
    private var hasFetched = false
    private var currentSort: YarnSort = .name
    
    // MARK: - Start / Setup
    
    /// Call once (e.g. onAppear) with the managed object context, then call `updateFilters` to load yarns
    func start(context: NSManagedObjectContext) {
        guard !isStarted else { return }
        self.context = context
        setupFetchedResultsController(predicate: nil, sort: currentSort)
        refreshTabCounts()
        isStarted = true
    }
    
    private func setupFetchedResultsController(predicate: NSPredicate?, sort: YarnSort) {
        guard let context = context else { return }
        
        let request: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        // Keep a stable sort descriptor (required by NSFetchedResultsController)
        request.sortDescriptors = sort.sortDescriptors
        request.predicate = predicate
        
        // No cacheName for simplicity (avoids stale cache issues)
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: context,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        self.fetchedResultsController = frc
        self.currentSort = sort
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
            self.yarns = fetchedResultsController?.fetchedObjects ?? []
        } catch {
            print("YarnListViewModel: performFetch() failed:", error)
            self.yarns = []
        }
    }
    
    deinit {
        fetchedResultsController?.delegate = nil
    }
    
    // MARK: - Public: update filters
    
    /// Update the fetch predicate and sort based on filter inputs (call only when filters change)
    func updateFilters(
        searchText: String,
        selectedColors: [NamedColor],
        selectedWeights: [Weight],
        sockSet: Int,
        colorType: ColorType?,
        selectedTab: YarnTab,
        sort: YarnSort = .name
    ) {
        let predicate = buildPredicate(
            searchText: searchText,
            selectedColors: selectedColors,
            selectedWeights: selectedWeights,
            sockSet: sockSet,
            colorType: colorType,
            selectedTab: selectedTab
        )
        
        guard let fetchedResultsController else { return }
        
        let sortChanged = currentSort != sort
        
        // The controller already tracks inserts, edits and deletes, so an unchanged query needs no refetch
        if hasFetched && !sortChanged && fetchedResultsController.fetchRequest.predicate == predicate {
            return
        }
        
        if sortChanged {
            fetchedResultsController.fetchRequest.sortDescriptors = sort.sortDescriptors
            currentSort = sort
        }
        
        fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
        hasFetched = true
    }
    
    // MARK: - Predicate builder (mirrors your earlier logic)
    private func buildPredicate(
        searchText: String,
        selectedColors: [NamedColor],
        selectedWeights: [Weight],
        sockSet: Int,
        colorType: ColorType?,
        selectedTab: YarnTab
    ) -> NSPredicate {
        var predicates: [NSPredicate] = []
        
        if !searchText.isEmpty {
            let nameP = NSPredicate(format: "name CONTAINS[c] %@", searchText)
            let dyerP = NSPredicate(format: "dyer CONTAINS[c] %@", searchText)
            let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [nameP, dyerP])
            predicates.append(compound)
        }
        
        if !selectedColors.isEmpty {
            let colorPredicates = selectedColors.map { color in
                NSPredicate(format: "ANY colors.name = %@", color.name)
            }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates))
        }
        
        if !selectedWeights.isEmpty {
            let weightPredicates = selectedWeights.map { weight in
                // Adjust weight.rawValue type if your Weight enum is Int vs String
                NSPredicate(format: "ANY weightAndYardages.weight = %@", weight.rawValue as CVarArg)
            }
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: weightPredicates))
        }
        
        if sockSet != -1 {
            if sockSet == 1 {
                predicates.append(NSPredicate(format: "isSockSet = %@", NSNumber(value: true)))
            } else {
                // no sock sets
                let noSockSetsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "isSockSet == %@", NSNumber(value: false)),
                    NSPredicate(format: "isSockSet == nil")
                ])
                predicates.append(noSockSetsPredicate)
            }
        }
        
        if let ct = colorType {
            predicates.append(NSPredicate(format: "colorType = %@", ct.rawValue))
        }
        
        switch selectedTab {
        case .active:
            let activePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
                NSPredicate(format: "isArchived == nil")
            ])
            predicates.append(activePredicate)
        case .archived:
            predicates.append(NSPredicate(format: "isArchived = %@", NSNumber(value: true)))
        }
        
        if predicates.isEmpty {
            return NSPredicate(value: true)
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
    
    func refreshTabCounts() {
        guard context != nil else { return }
        
        let container = PersistenceController.shared.container
        let bgContext = container.newBackgroundContext()
        
        bgContext.perform { [weak self] in
            let activeRequest: NSFetchRequest<NSNumber> = NSFetchRequest(entityName: "Yarn")
            activeRequest.resultType = .countResultType
            activeRequest.predicate = NSPredicate(format: "isArchived == NO OR isArchived == nil")
            
            let archivedRequest: NSFetchRequest<NSNumber> = NSFetchRequest(entityName: "Yarn")
            archivedRequest.resultType = .countResultType
            archivedRequest.predicate = NSPredicate(format: "isArchived == YES")
            
            do {
                let activeCount = try bgContext.count(for: activeRequest)
                let archivedCount = try bgContext.count(for: archivedRequest)
                
                DispatchQueue.main.async {
                    self?.activeCount = activeCount
                    self?.archivedCount = archivedCount
                }
            } catch {
                print("Failed to fetch tab counts: \(error)")
            }
        }
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension YarnListViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let fetched = controller.fetchedObjects as? [Yarn] else { return }
        
        if Thread.isMainThread {
            // Publish synchronously so saves made inside withAnimation animate the grid
            MainActor.assumeIsolated {
                self.publish(fetched)
            }
        } else {
            Task { @MainActor in
                self.publish(fetched)
            }
        }
    }
    
    private func publish(_ fetched: [Yarn]) {
        yarns = fetched
        
        // This can run mid-save, before the store is written; count once the save has finished
        DispatchQueue.main.async { [weak self] in
            self?.refreshTabCounts()
        }
    }

}
