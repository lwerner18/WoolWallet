//
//  RowCounter.swift
//  WoolWallet
//
//  Created by Mac on 10/31/24.
//

import Foundation
import CoreData

extension RowCounter {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: RowCounter.entity(), insertInto: context)
        self.id = UUID()
    }
    
    var entryItems: [RowCounterEntry] {
        (entries?.allObjects as? [RowCounterEntry] ?? [])
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
    
    /// Bumps the count and records the change for the project history chart
    func adjust(by delta: Int16) {
        guard delta != 0 else { return }
        
        let next = Int(count) + Int(delta)
        guard next >= 0, next <= Int(Int16.max) else { return }
        
        count = Int16(next)
        record(delta: delta)
    }
    
    /// Clears the count and logs the drop so history stays honest
    func resetCount() {
        guard count != 0 else { return }
        
        let delta = -count
        count = 0
        record(delta: delta)
    }
    
    private func record(delta: Int16) {
        guard let context = managedObjectContext else { return }
        
        let entry = RowCounterEntry(context: context)
        entry.id = UUID()
        entry.date = Date()
        entry.delta = delta
        entry.counter = self
    }
}

extension RowCounterEntry {
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: RowCounterEntry.entity(), insertInto: context)
        self.id = UUID()
        self.date = Date()
    }
}

/// Rows added (and undone) on a calendar day, for the history chart
struct DayRowActivity: Identifiable, Equatable {
    let day : Date
    var added : Int
    var removed : Int
    
    var id : Date { day }
    var net : Int { added - removed }
    
    var hasActivity : Bool { added > 0 || removed > 0 }
}

enum RowCounterHistory {
    /// Groups entries by day; fills empty days between the first entry and today so the chart reads as a timeline
    static func dailyActivity(from entries: [RowCounterEntry], calendar: Calendar = .current) -> [DayRowActivity] {
        guard let earliest = entries.compactMap(\.date).min() else { return [] }
        
        let start = calendar.startOfDay(for: earliest)
        let end = calendar.startOfDay(for: Date.now)
        
        var addedByDay : [Date: Int] = [:]
        var removedByDay : [Date: Int] = [:]
        
        for entry in entries {
            guard let date = entry.date else { continue }
            let day = calendar.startOfDay(for: date)
            
            if entry.delta > 0 {
                addedByDay[day, default: 0] += Int(entry.delta)
            } else if entry.delta < 0 {
                removedByDay[day, default: 0] += Int(-entry.delta)
            }
        }
        
        var days : [DayRowActivity] = []
        var cursor = start
        while cursor <= end {
            days.append(DayRowActivity(
                day: cursor,
                added: addedByDay[cursor] ?? 0,
                removed: removedByDay[cursor] ?? 0
            ))
            
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        return days
    }
}
