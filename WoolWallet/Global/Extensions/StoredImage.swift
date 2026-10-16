//
//  StoredImage.swift
//  WoolWallet
//
//  Created by Mac on 9/25/24.
//

import Foundation
import SwiftUI
import CoreData

extension StoredImage {
    /// Longest edge, in pixels, for photos shown full width (detail screens, edit forms).
    static let displayMaxPixelSize: CGFloat = 1600
    /// Longest edge, in pixels, for photos shown in grids and preview cards.
    static let thumbnailMaxPixelSize: CGFloat = 500
    /// Longest edge, in pixels, kept when saving a new photo.
    private static let storedMaxPixelSize: CGFloat = 2048
    
    private static let decodedImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 150 * 1024 * 1024 // decoded bitmap bytes
        return cache
    }()
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: StoredImage.entity(), insertInto: context)
        self.id = UUID() // Set a unique ID
    }
    
    /// `encodedPhotos` comes from `encodeNewPhotos`; anything missing is encoded here on the calling thread
    static func from(data: ImageData, order: Int, context: NSManagedObjectContext, encodedPhotos: [UUID: Data] = [:]) -> StoredImage {
        // Existing photos never change content in the editors, so only their position needs updating
        if let existingItem = data.existingItem {
            existingItem.order = Int16(order)
            return existingItem
        }
        
        let storedImage = StoredImage(context: context)
        storedImage.image = encodedPhotos[data.id] ?? encodeForStorage(data.image)
        storedImage.order = Int16(order)
        
        return storedImage
    }
    
    /// Resizes and compresses new photos in parallel off the main thread, since doing it while saving freezes the form
    static func encodeNewPhotos(_ images: [ImageData]) async -> [UUID: Data] {
        await withTaskGroup(of: (UUID, Data?).self) { group in
            for item in images where item.existingItem == nil {
                let id = item.id
                let image = item.image
                group.addTask { (id, encodeForStorage(image)) }
            }
            
            var encoded : [UUID: Data] = [:]
            for await (id, data) in group {
                encoded[id] = data
            }
            return encoded
        }
    }
    
    private static func encodeForStorage(_ image: UIImage) -> Data? {
        image
            .scaledDown(toMaxPixelSize: storedMaxPixelSize)
            .jpegData(compressionQuality: 0.8)
    }
    
    /// Decoded, downsampled, cached image for display.
    func displayImage(maxPixelSize: CGFloat = StoredImage.displayMaxPixelSize) -> UIImage {
        let key = "\(objectID.uriRepresentation().absoluteString)|\(Int(maxPixelSize))" as NSString
        if let cached = Self.decodedImageCache.object(forKey: key) {
            return cached
        }
        
        guard let data = image, let decoded = UIImage.downsampled(from: data, maxPixelSize: maxPixelSize) else {
            return UIImage()
        }
        
        let cost = decoded.cgImage.map { $0.bytesPerRow * $0.height } ?? data.count
        Self.decodedImageCache.setObject(decoded, forKey: key, cost: cost)
        return decoded
    }
    
    // MARK: - Background thumbnails for lists
    
    private final class ImageDataBox {
        let items: [ImageData]
        init(_ items: [ImageData]) { self.items = items }
    }
    
    private static let thumbnailSetCache: NSCache<NSString, ImageDataBox> = {
        let cache = NSCache<NSString, ImageDataBox>()
        cache.totalCostLimit = 100 * 1024 * 1024 // decoded bitmap bytes
        return cache
    }()
    
    private static let thumbnailDirectory: URL? = {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let directory = caches.appendingPathComponent("StoredImageThumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()
    
    /// Object IDs of a to-many `images` relationship, in display order, without loading any photo data.
    static func objectIDs(from images: NSSet?) -> [NSManagedObjectID] {
        let objects = images?.allObjects as? [StoredImage] ?? []
        return objects
            .sorted { $0.order < $1.order }
            .map(\.objectID)
            .filter { !$0.isTemporaryID }
    }
    
    private static func thumbnailSetKey(for objectIDs: [NSManagedObjectID], maxPixelSize: CGFloat) -> NSString {
        let ids = objectIDs.map { $0.uriRepresentation().absoluteString }.joined(separator: ",")
        return "\(ids)|\(Int(maxPixelSize))" as NSString
    }
    
    /// Thumbnails already loaded this session, or nil if they still need `loadThumbnails`.
    @MainActor
    static func cachedThumbnails(for objectIDs: [NSManagedObjectID], maxPixelSize: CGFloat = thumbnailMaxPixelSize) -> [ImageData]? {
        if objectIDs.isEmpty { return [] }
        return thumbnailSetCache.object(forKey: thumbnailSetKey(for: objectIDs, maxPixelSize: maxPixelSize))?.items
    }
    
    /// Loads ordered thumbnails off the main thread, using an on-disk cache so full-size photos are read only once.
    @MainActor
    static func loadThumbnails(for objectIDs: [NSManagedObjectID], maxPixelSize: CGFloat = thumbnailMaxPixelSize) async -> [ImageData] {
        if objectIDs.isEmpty { return [] }
        
        if let cached = cachedThumbnails(for: objectIDs, maxPixelSize: maxPixelSize) {
            return cached
        }
        
        let container = PersistenceController.shared.container
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        let loaded: [(objectID: NSManagedObjectID, id: UUID, image: UIImage)] = await backgroundContext.perform {
            let objectIDDescription = NSExpressionDescription()
            objectIDDescription.name = "objectID"
            objectIDDescription.expression = NSExpression.expressionForEvaluatedObject()
            objectIDDescription.expressionResultType = .objectIDAttributeType
            
            // Dictionary results read only the order and id columns, not the photo data
            let request = NSFetchRequest<NSDictionary>(entityName: "StoredImage")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [objectIDDescription, "id"]
            request.predicate = NSPredicate(format: "self IN %@", objectIDs)
            request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            let rows = (try? backgroundContext.fetch(request)) ?? []
            return rows.compactMap { row in
                guard let objectID = row["objectID"] as? NSManagedObjectID else { return nil }
                let id = row["id"] as? UUID
                guard let image = thumbnail(id: id, objectID: objectID, context: backgroundContext, maxPixelSize: maxPixelSize) else {
                    return nil
                }
                return (objectID, id ?? UUID(), image)
            }
        }
        
        let items = loaded.map { item in
            ImageData(
                id: item.id,
                image: item.image,
                existingItem: container.viewContext.object(with: item.objectID) as? StoredImage
            )
        }
        
        // Empty or partial results are usually a post-save race; caching them poisons covers until relaunch
        guard items.count == objectIDs.count else { return items }
        
        let cost = items.reduce(0) { total, item in
            total + (item.image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0)
        }
        thumbnailSetCache.setObject(ImageDataBox(items), forKey: thumbnailSetKey(for: objectIDs, maxPixelSize: maxPixelSize), cost: cost)
        return items
    }
    
    /// Drops in-memory thumbnails so list cards reload after photos are added or replaced
    static func invalidateThumbnailCache() {
        thumbnailSetCache.removeAllObjects()
    }
    
    /// Must be called on `context`'s queue.
    private static func thumbnail(id: UUID?, objectID: NSManagedObjectID, context: NSManagedObjectContext, maxPixelSize: CGFloat) -> UIImage? {
        let fileURL = id.flatMap { thumbnailDirectory?.appendingPathComponent("\($0.uuidString)-\(Int(maxPixelSize)).jpg") }
        
        if let fileURL, let image = UIImage(contentsOfFile: fileURL.path) {
            return image.preparingForDisplay() ?? image
        }
        
        guard let storedImage = try? context.existingObject(with: objectID) as? StoredImage,
              let data = storedImage.image,
              let image = UIImage.downsampled(from: data, maxPixelSize: maxPixelSize) else {
            return nil
        }
        context.refresh(storedImage, mergeChanges: false) // release the full-size photo data
        
        if let fileURL {
            try? image.jpegData(compressionQuality: 0.85)?.write(to: fileURL, options: .atomic)
        }
        return image
    }
    
    /// Ordered form/display data for a to-many `images` relationship.
    static func imageData(from images: NSSet?, maxPixelSize: CGFloat) -> [ImageData] {
        let storedImages = images?.allObjects as? [StoredImage] ?? []
        
        return storedImages
            .sorted { $0.order < $1.order }
            .map { storedImage in
                ImageData(
                    id: storedImage.id!,
                    image: storedImage.displayImage(maxPixelSize: maxPixelSize),
                    existingItem: storedImage
                )
            }
    }
}
