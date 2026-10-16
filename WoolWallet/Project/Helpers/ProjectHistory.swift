//
//  ProjectHistory.swift
//  WoolWallet
//
//  Created by Mac on 10/15/26.
//

import SwiftUI
import Charts
import CoreData

/// Daily row-counting history for a project: chart plus a day-by-day breakdown
struct ProjectRowHistory: View {
    @ObservedObject var project : Project
    @FetchRequest private var entries : FetchedResults<RowCounterEntry>
    
    @State private var selectedCounterID : NSManagedObjectID? = nil
    @State private var selectedDay : Date? = nil
    
    init(project: Project) {
        self.project = project
        _entries = FetchRequest(
            entity: RowCounterEntry.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \RowCounterEntry.date, ascending: true)],
            predicate: NSPredicate(format: "counter.project == %@", project)
        )
    }
    
    private var counters: [RowCounter] {
        project.sortedRowCounters
    }
    
    private var filteredEntries: [RowCounterEntry] {
        let all = Array(entries)
        
        guard let selectedCounterID else { return all }
        return all.filter { $0.counter?.objectID == selectedCounterID }
    }
    
    private var days: [DayRowActivity] {
        RowCounterHistory.dailyActivity(from: filteredEntries)
    }
    
    private var activeDays: [DayRowActivity] {
        days.filter(\.hasActivity).reversed()
    }
    
    private var totalAdded: Int {
        filteredEntries.reduce(0) { $0 + max(Int($1.delta), 0) }
    }
    
    private var bestDay: DayRowActivity? {
        days.max { $0.added < $1.added }.flatMap { $0.added > 0 ? $0 : nil }
    }
    
    private var selectedActivity: DayRowActivity? {
        guard let selectedDay else { return nil }
        return days.first { Calendar.current.isDate($0.day, inSameDayAs: selectedDay) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if counters.isEmpty {
                emptyState(
                    title: "No Row Counters Yet",
                    message: "Add a counter on the Details tab, then every + and − is saved here by day."
                )
            } else if filteredEntries.isEmpty {
                emptyState(
                    title: "No History Yet",
                    message: "History starts the next time you count. Tap + on a counter to begin."
                )
            } else {
                if counters.count > 1 {
                    counterFilter
                }
                
                summaryCards
                
                chartCard
                
                if !activeDays.isEmpty {
                    dayList
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Filter
    
    private var counterFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", selected: selectedCounterID == nil) {
                    selectedCounterID = nil
                    selectedDay = nil
                }
                
                ForEach(counters, id: \.objectID) { counter in
                    filterChip(title: counter.name ?? "Counter", selected: selectedCounterID == counter.objectID) {
                        selectedCounterID = counter.objectID
                        selectedDay = nil
                    }
                }
            }
        }
    }
    
    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(selected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Summary
    
    private var summaryCards: some View {
        HStack(spacing: 10) {
            summaryTile(
                value: "\(totalAdded)",
                label: "Rows Logged",
                systemImage: "number",
                color: .accentColor
            )
            
            summaryTile(
                value: "\(activeDays.count)",
                label: activeDays.count == 1 ? "Day Counted" : "Days Counted",
                systemImage: "calendar",
                color: .green
            )
            
            if let bestDay {
                summaryTile(
                    value: "+\(bestDay.added)",
                    label: bestDay.day.formatted(.dateTime.month(.abbreviated).day()),
                    systemImage: "flame.fill",
                    color: .orange
                )
            }
        }
    }
    
    private func summaryTile(value: String, label: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Chart
    
    private var chartCard: some View {
        let chartDays = Array(days.suffix(28))
        let maxAdded = max(chartDays.map(\.added).max() ?? 1, 1)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rows Added")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                if let selectedActivity, selectedActivity.added > 0 || selectedActivity.removed > 0 {
                    Text(selectedActivityLabel(selectedActivity))
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text(chartDays.count > 14 ? "Last 28 days" : "Since you started counting")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                }
            }
            
            Chart {
                ForEach(chartDays) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Rows", day.added)
                    )
                    .foregroundStyle(Calendar.current.isDate(day.day, inSameDayAs: selectedDay ?? .distantPast) ? Color.accentColor : Color.accentColor.opacity(0.7))
                    .cornerRadius(3)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: chartDays.count > 14 ? 7 : 3)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: 0...maxAdded)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let origin = geometry[plotFrame].origin
                                    let x = drag.location.x - origin.x
                                    if let day: Date = proxy.value(atX: x) {
                                        selectedDay = Calendar.current.startOfDay(for: day)
                                    }
                                }
                        )
                }
            }
            .frame(height: 180)
            
            if let selectedActivity, selectedActivity.removed > 0 {
                Text("Includes \(selectedActivity.removed) undone on that day")
                    .font(.caption2)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func selectedActivityLabel(_ day: DayRowActivity) -> String {
        let date = day.day.formatted(.dateTime.month(.abbreviated).day())
        if day.added == 0 {
            return "\(date) · no adds"
        }
        return "\(date) · +\(day.added)"
    }
    
    // MARK: - Day list
    
    private var dayList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Day")
                .font(.headline)
                .foregroundStyle(Color.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(activeDays.enumerated()), id: \.element.id) { index, day in
                    Button {
                        selectedDay = day.day
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.primary)
                                
                                if day.removed > 0 {
                                    Text("\(day.removed) undone")
                                        .font(.caption2)
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                }
                            }
                            
                            Spacer()
                            
                            Text("+\(day.added)")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if index < activeDays.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Empty
    
    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor.opacity(0.8))
                .padding(.top, 24)
            
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
