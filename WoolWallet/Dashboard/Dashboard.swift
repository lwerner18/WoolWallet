//
//  Dashboard.swift
//  WoolWallet
//
//  Created by Mac on 11/10/24.
//

import Foundation
import SwiftUI
import CoreData
import Charts

struct ItemCount : Identifiable {
    var id : UUID = UUID()
    
    var item : Item
    var count : Int
}

struct YarnWeightCount : Identifiable, Equatable {
    var id : UUID = UUID()
    
    var weight : Weight
    var count : Double
}

struct CraftMixCount : Identifiable {
    var id : String { type.rawValue }
    var type : PatternType
    var count : Int
}

enum PatternTypeChart : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case all = "All"
    case crochet = "Crochet"
    case knit = "Knit"
    case tunisian = "Tunisian"
}

struct Dashboard : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.projectToShowAutomatically) var projectToShowAutomatically : Binding<Project?>
    @Environment(\.projectTabToShowAutomatically) var projectTabToShowAutomatically : Binding<ProjectTab?>
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.startDate, ascending: false)],
        predicate: NSPredicate(format: "inProgress = %@", true as NSNumber)
    ) private var currentProjects: FetchedResults<Project>
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.endDate, ascending: false)],
        predicate: NSPredicate(format: "complete = %@", true as NSNumber)
    ) private var completedProjects: FetchedResults<Project>
    
    @FetchRequest(
        entity: Project.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.dateAdded, ascending: true)],
        predicate: NSPredicate(format: "(inProgress == NO OR inProgress == nil) AND (complete == NO OR complete == nil)")
    ) private var queuedProjects: FetchedResults<Project>
    
    @FetchRequest(
        fetchRequest: PatternItem.fetchItems()
    ) private var patternItems: FetchedResults<PatternItem>
    
    @FetchRequest(
        fetchRequest: Pattern.fetchPartialRequest()
    ) private var patterns: FetchedResults<Pattern>
    
    @FetchRequest(
        fetchRequest: Yarn.fetchPartialRequest()
    ) private var yarns: FetchedResults<Yarn>
    
    @FetchRequest(
        fetchRequest: WeightAndYardage.fetchWeightsAndSkeins()
    ) private var weightsAndSkeins: FetchedResults<WeightAndYardage>
    
    @State private var animateItemCounts : [Bool] = []
    @State private var animateWeightCounts : [Bool] = []
    @State private var patternTypeChart : PatternTypeChart = .all
    @State private var selectedAngle: Double? = nil
    
    @Binding var mainTab : MainTab
    
    // MARK: - Stats
    
    private var activeYarns: [Yarn] {
        yarns.filter { !$0.isArchived && !$0.isDeleted }
    }
    
    private var unusedSkeins: Double {
        weightsAndSkeins.reduce(0.0) { count, weightAndYardage in
            guard weightAndYardage.yarn?.isArchived != true else { return count }
            // A sock set counts as one unit on the shelf even when it has several mini skeins
            return count + (weightAndYardage.yarn?.isSockSet == true ? 1 : weightAndYardage.currentSkeins)
        }
    }
    
    private var averageDaysToFinish: Double? {
        let days = completedProjects.compactMap { project -> Int? in
            guard let start = project.startDate, let end = project.endDate else { return nil }
            return max(Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0, 0)
        }
        
        guard !days.isEmpty else { return nil }
        return Double(days.reduce(0, +)) / Double(days.count)
    }
    
    private var finishedThisYear: Int {
        let year = Calendar.current.component(.year, from: Date.now)
        return completedProjects.filter {
            guard let end = $0.endDate else { return false }
            return Calendar.current.component(.year, from: end) == year
        }.count
    }
    
    private var finishedThisMonth: Int {
        let calendar = Calendar.current
        return completedProjects.filter {
            guard let end = $0.endDate else { return false }
            return calendar.isDate(end, equalTo: Date.now, toGranularity: .month)
        }.count
    }
    
    private var longestWIP: (project: Project, days: Int)? {
        let ranked = currentProjects.compactMap { project -> (Project, Int)? in
            guard let days = project.daysSinceStart else { return nil }
            return (project, days)
        }
        
        return ranked.max { $0.1 < $1.1 }
    }
    
    private var unusedPatterns: Int {
        patterns.filter { !$0.hasProjects }.count
    }
    
    private var yarnWeightCounts : [YarnWeightCount] {
        var skeinsByWeight : [String: Double] = [:]
        
        for weightAndYardage in weightsAndSkeins where weightAndYardage.currentSkeins > 0 {
            guard weightAndYardage.yarn?.isArchived != true else { continue }
            if let weight = weightAndYardage.weight {
                skeinsByWeight[weight, default: 0] += weightAndYardage.currentSkeins
            }
        }
        
        return Weight.allCases
            .filter { $0 != Weight.none }
            .map { YarnWeightCount(weight: $0, count: skeinsByWeight[$0.rawValue] ?? 0) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }
    
    private var topWeight: YarnWeightCount? {
        yarnWeightCounts.first
    }
    
    private var craftMix: [CraftMixCount] {
        var counts : [PatternType: Int] = [:]
        
        for pattern in patterns {
            guard let type = PatternType(rawValue: pattern.type ?? "") else { continue }
            counts[type, default: 0] += 1
        }
        
        return PatternType.allCases
            .compactMap { type in
                let count = counts[type] ?? 0
                return count > 0 ? CraftMixCount(type: type, count: count) : nil
            }
    }
    
    private var itemCounts: [ItemCount] {
        var countsByItem : [String: Int] = [:]
        
        for patternItem in patternItems {
            guard let item = patternItem.item else { continue }
            
            let matchesType: Bool
            switch patternTypeChart {
            case .all:      matchesType = true
            case .crochet:  matchesType = patternItem.pattern?.type == PatternType.crochet.rawValue
            case .knit:     matchesType = patternItem.pattern?.type == PatternType.knit.rawValue
            case .tunisian: matchesType = patternItem.pattern?.type == PatternType.tunisian.rawValue
            }
            
            if matchesType {
                countsByItem[item, default: 0] += 1
            }
        }
        
        return Item.allCases
            .filter { $0 != Item.none }
            .map { ItemCount(item: $0, count: countsByItem[$0.rawValue] ?? 0) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
    }
    
    private var headerColors: [Color] {
        let colors = activeYarns.prefix(8).flatMap { yarn in
            yarn.sortedYarnColors.prefix(2)
        }
        
        if colors.isEmpty {
            return [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.08)]
        }
        
        let unique = Array(colors.prefix(5))
        return unique.count == 1 ? [unique[0], unique[0].opacity(0.45)] : unique
    }
    
    private var recentlyFinished: [Project] {
        Array(completedProjects.prefix(8))
    }
    
    // MARK: - Body
    
    var body : some View {
        let yarnWeightCounts = self.yarnWeightCounts
        let totalYarnWeights = yarnWeightCounts.reduce(0) { $0 + $1.count }
        let selectedYarnWeight = selectedWeight(in: yarnWeightCounts)
        let itemCounts = self.itemCounts
        let maxItemCount = max(itemCounts.map(\.count).max() ?? 1, 1)
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    hero
                    
                    if !currentProjects.isEmpty {
                        inProgressSection
                    }
                    
                    atAGlance
                    
                    highlights
                    
                    if !yarnWeightCounts.isEmpty {
                        yarnWeightsSection(
                            counts: yarnWeightCounts,
                            total: totalYarnWeights,
                            selected: selectedYarnWeight
                        )
                    }
                    
                    if !craftMix.isEmpty {
                        craftMixSection
                    }
                    
                    if !patternItems.isEmpty {
                        patternItemsSection(itemCounts: itemCounts, maxCount: maxItemCount)
                    }
                    
                    if !recentlyFinished.isEmpty {
                        recentlyFinishedSection
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }
    
    // MARK: - Hero
    
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(heroGreeting)
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
            
            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            LinearGradient(colors: headerColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.55)
                .mask(
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0.55), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }
    
    private var heroGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Welcome back"
        }
    }
    
    private var heroSubtitle: String {
        if currentProjects.isEmpty && queuedProjects.isEmpty && completedProjects.isEmpty {
            return "Your stash, patterns, and projects will show up here as you add them."
        }
        
        if currentProjects.isEmpty {
            return queuedProjects.isEmpty
                ? "Nothing in the works — \(finishedThisYear) finished this year."
                : "\(queuedProjects.count) waiting in the queue. Pick one up whenever you're ready."
        }
        
        let inTheWorks = currentProjects.count == 1
            ? "1 project in the works"
            : "\(currentProjects.count) projects in the works"
        
        if finishedThisMonth > 0 {
            return "\(inTheWorks). \(finishedThisMonth) finished this month."
        }
        
        return "\(inTheWorks). Keep going."
    }
    
    // MARK: - In progress
    
    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("In the Works", actionTitle: "See All") {
                showProjects(.inProgress)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(currentProjects, id: \.objectID) { project in
                        DashboardWIPCard(project: project) {
                            openProject(project)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - At a glance
    
    private var atAGlance: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("At a Glance")
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                DashboardStatTile(
                    value: "\(currentProjects.count)",
                    label: "Projects in Progress",
                    systemImage: "hammer.fill",
                    color: .green
                ) {
                    showProjects(.inProgress)
                }
                
                DashboardStatTile(
                    value: "\(completedProjects.count)",
                    label: "Finished Projects",
                    systemImage: "checkmark.circle.fill",
                    color: .accentColor
                ) {
                    showProjects(.completed)
                }
                
                DashboardStatTile(
                    value: "\(queuedProjects.count)",
                    label: "Projects in Queue",
                    systemImage: "tray.full.fill",
                    color: .orange
                ) {
                    showProjects(.notStarted)
                }
                
                DashboardStatTile(
                    value: unusedSkeins.formatted,
                    label: "Skeins in Stash",
                    systemImage: "volleyball",
                    color: Color(red: 0.45, green: 0.55, blue: 0.75)
                ) {
                    mainTab = .stash
                }
                
                DashboardStatTile(
                    value: "\(patterns.count)",
                    label: "Patterns Saved",
                    systemImage: "book.pages.fill",
                    color: Color(red: 0.75, green: 0.45, blue: 0.55)
                ) {
                    mainTab = .patterns
                }
                
                DashboardStatTile(
                    value: averageDaysToFinish.map { "\($0.formatted)" } ?? "—",
                    label: "Avg. Days to Finish",
                    systemImage: "calendar",
                    color: Color(red: 0.4, green: 0.65, blue: 0.55)
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Highlights
    
    private var highlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Highlights")
            
            VStack(spacing: 10) {
                if finishedThisYear > 0 || finishedThisMonth > 0 {
                    DashboardHighlightRow(
                        systemImage: "sparkles",
                        color: .accentColor,
                        title: finishedThisMonth > 0
                            ? "\(finishedThisMonth) finished this month"
                            : "\(finishedThisYear) finished in \(Calendar.current.component(.year, from: Date.now))",
                        detail: finishedThisMonth > 0 && finishedThisYear != finishedThisMonth
                            ? "\(finishedThisYear) so far this year"
                            : nil
                    )
                }
                
                if let longestWIP {
                    let name = longestWIP.project.pattern?.name ?? "a project"
                    DashboardHighlightRow(
                        systemImage: "timer",
                        color: .green,
                        title: longestWIP.days == 0
                            ? "Started \(name) today"
                            : "Longest WIP: day \(longestWIP.days + 1)",
                        detail: longestWIP.days == 0 ? nil : name
                    ) {
                        openProject(longestWIP.project)
                    }
                }
                
                if unusedPatterns > 0 {
                    DashboardHighlightRow(
                        systemImage: "bookmark.fill",
                        color: .orange,
                        title: unusedPatterns == 1
                            ? "1 pattern waiting to be cast on"
                            : "\(unusedPatterns) patterns waiting to be cast on",
                        detail: "In your library with no projects yet"
                    ) {
                        mainTab = .patterns
                    }
                }
                
                if let topWeight {
                    DashboardHighlightRow(
                        systemImage: "chart.pie.fill",
                        color: Color(red: 0.45, green: 0.55, blue: 0.75),
                        title: "Most of your stash is \(topWeight.weight.getDisplay())",
                        detail: "\(topWeight.count.formatted) skeins"
                    )
                }
                
                if activeYarns.count > 0 {
                    DashboardHighlightRow(
                        systemImage: "archivebox",
                        color: Color(UIColor.secondaryLabel),
                        title: "\(activeYarns.count) active yarn\(activeYarns.count == 1 ? "" : "s")",
                        detail: yarns.filter(\.isArchived).isEmpty
                            ? nil
                            : "\(yarns.filter(\.isArchived).count) archived"
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Yarn weights
    
    private func yarnWeightsSection(counts: [YarnWeightCount], total: Double, selected: YarnWeightCount?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Stash by Weight")
            
            VStack(spacing: 16) {
                Chart {
                    ForEach(Array(counts.enumerated()), id: \.element.id) { index, item in
                        let animated = index < animateWeightCounts.count ? animateWeightCounts[index] : true
                        
                        SectorMark(
                            angle: .value("Skeins", animated ? item.count : 0),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(weightLegendColor(item.weight, in: counts))
                        .opacity(selected == nil || selected == item ? 1 : 0.35)
                    }
                }
                .chartLegend(.hidden)
                .chartAngleSelection(value: $selectedAngle)
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        if let anchor = proxy.plotFrame {
                            let frame = geometry[anchor]
                            VStack(spacing: 2) {
                                Text(selected?.count.formatted ?? total.formatted)
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(Color.primary)
                                
                                Text(selected?.weight.getDisplay() ?? "Skeins")
                                    .font(.caption)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
                .frame(height: 220)
                .onAppear { animateYarnWeightCounts(count: counts.count) }
                
                VStack(spacing: 8) {
                    ForEach(counts) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(weightLegendColor(item.weight, in: counts))
                                .frame(width: 10, height: 10)
                            
                            Text(item.weight.getDisplay())
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                            
                            Spacer()
                            
                            Text(item.count.formatted)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Color.primary)
                            
                            Text("\(Int(((item.count / max(total, 1)) * 100).rounded()))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Craft mix
    
    private var craftMixSection: some View {
        let total = max(craftMix.reduce(0) { $0 + $1.count }, 1)
        
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Patterns by Craft")
            
            VStack(alignment: .leading, spacing: 14) {
                GeometryReader { proxy in
                    HStack(spacing: 3) {
                        ForEach(craftMix) { item in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(craftColor(item.type))
                                .frame(width: max(proxy.size.width * CGFloat(item.count) / CGFloat(total), 8))
                        }
                    }
                }
                .frame(height: 14)
                
                ForEach(craftMix) { item in
                    HStack {
                        Circle()
                            .fill(craftColor(item.type))
                            .frame(width: 10, height: 10)
                        
                        Text(item.type.rawValue)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.subheadline.monospacedDigit().bold())
                        
                        Text("\(Int((Double(item.count) / Double(total) * 100).rounded()))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Pattern items
    
    private func patternItemsSection(itemCounts: [ItemCount], maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("What You Make")
            
            VStack(spacing: 12) {
                Picker("Type", selection: $patternTypeChart) {
                    ForEach(PatternTypeChart.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                
                if itemCounts.isEmpty {
                    Text(patternTypeChart == .all
                         ? "No pattern items yet."
                         : "No \(patternTypeChart.rawValue.lowercased()) patterns yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .multilineTextAlignment(.center)
                } else {
                    Chart {
                        ForEach(Array(itemCounts.enumerated()), id: \.element.id) { index, itemCount in
                            let animated = index < animateItemCounts.count ? animateItemCounts[index] : true
                            
                            BarMark(
                                x: .value("Count", animated ? itemCount.count : 0),
                                y: .value("Item", itemCount.item.rawValue)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(PatternUtils.shared.getItemDisplay(for: itemCount.item).color)
                            .annotation(position: .trailing) {
                                Text("\(itemCount.count)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0...maxCount)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .frame(height: CGFloat(max(itemCounts.count, 1)) * 36 + 8)
                    .onAppear { animateItems(count: itemCounts.count) }
                    .onChange(of: patternTypeChart) {
                        animateItems(count: itemCounts.count)
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recently finished
    
    private var recentlyFinishedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recently Finished", actionTitle: "See All") {
                showProjects(.completed)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentlyFinished, id: \.objectID) { project in
                        DashboardFinishedTile(project: project) {
                            openProject(project)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.primary)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.bold())
            }
        }
        .padding(.horizontal)
    }
    
    private func openProject(_ project: Project) {
        projectToShowAutomatically.wrappedValue = project
        mainTab = .projects
    }
    
    private func showProjects(_ tab: ProjectTab) {
        projectTabToShowAutomatically.wrappedValue = tab
        mainTab = .projects
    }
    
    private func selectedWeight(in weightCounts: [YarnWeightCount]) -> YarnWeightCount? {
        guard let selectedAngle else { return nil }
        
        var sum = 0.0
        for yarnWeightCount in weightCounts {
            sum += yarnWeightCount.count
            if sum > selectedAngle {
                return yarnWeightCount
            }
        }
        
        return nil
    }
    
    private func craftColor(_ type: PatternType) -> Color {
        switch type {
        case .crochet:  return Color(red: 0.85, green: 0.45, blue: 0.4)
        case .knit:     return Color(red: 0.4, green: 0.6, blue: 0.85)
        case .tunisian: return Color(red: 0.55, green: 0.7, blue: 0.45)
        }
    }
    
    private func weightLegendColor(_ weight: Weight, in counts: [YarnWeightCount]) -> Color {
        let palette: [Color] = [
            Color(red: 0.35, green: 0.55, blue: 0.85),
            Color(red: 0.9, green: 0.55, blue: 0.35),
            Color(red: 0.45, green: 0.7, blue: 0.55),
            Color(red: 0.75, green: 0.4, blue: 0.55),
            Color(red: 0.55, green: 0.45, blue: 0.75),
            Color(red: 0.3, green: 0.65, blue: 0.7),
            Color(red: 0.85, green: 0.7, blue: 0.3),
            Color(red: 0.6, green: 0.55, blue: 0.45)
        ]
        
        let index = counts.firstIndex(where: { $0.weight == weight }) ?? 0
        return palette[index % palette.count]
    }
    
    private func animateItems(count: Int) {
        animateItemCounts = Array(repeating: false, count: count)
        
        for index in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                guard index < animateItemCounts.count else { return }
                withAnimation(.easeOut(duration: 0.45)) {
                    animateItemCounts[index] = true
                }
            }
        }
    }
    
    private func animateYarnWeightCounts(count: Int) {
        animateWeightCounts = Array(repeating: false, count: count)
        selectedAngle = nil
        
        for index in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                guard index < animateWeightCounts.count else { return }
                withAnimation(.easeOut(duration: 0.45)) {
                    animateWeightCounts[index] = true
                }
            }
        }
    }
}

// MARK: - Cards

private struct DashboardWIPCard: View {
    @ObservedObject var project : Project
    var onOpen : () -> Void
    
    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(width: 240, height: 130)
                    .overlay {
                        if project.hasImages {
                            FirstStoredPhoto(images: project.images, maxPixelSize: 900) {
                                ProjectPatternCoverFallback(project: project)
                            }
                        } else {
                            ProjectPatternCoverFallback(project: project)
                        }
                    }
                    .clipped()
                
                HStack(alignment: .top, spacing: 10) {
                    // Cover already anchors the header when there's no project photo
                    if project.hasImages, let pattern = project.pattern {
                        PatternCover(pattern: pattern, cornerRadius: 6, iconSize: Size.small)
                            .frame(width: 40, height: 54)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.pattern?.name ?? "No Name")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let startDate = DateUtils.shared.formatDate(project.startDate) {
                            Text("Started \(startDate)")
                                .font(.caption)
                                .foregroundStyle(Color(UIColor.secondaryLabel))
                        }
                        
                        if let days = project.timeSinceStartText {
                            Text(days)
                                .font(.caption2)
                                .foregroundStyle(Color(UIColor.tertiaryLabel))
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
            .frame(width: 240)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this project")
    }
}

private struct DashboardFinishedTile: View {
    @ObservedObject var project : Project
    var onOpen : () -> Void
    
    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                Color.clear
                    .frame(width: 140, height: 140)
                    .overlay {
                        if project.hasImages {
                            FirstStoredPhoto(images: project.images, maxPixelSize: 900) {
                                ProjectPatternCoverFallback(
                                    project: project,
                                    coverSize: CGSize(width: 72, height: 96),
                                    iconSize: .medium
                                )
                            }
                        } else {
                            ProjectPatternCoverFallback(
                                project: project,
                                coverSize: CGSize(width: 72, height: 96),
                                iconSize: .medium
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(project.pattern?.name ?? "No Name")
                    .font(.caption.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                
                Text([DateUtils.shared.formatDate(project.endDate), project.progressText].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardStatTile: View {
    var value : String
    var label : String
    var systemImage : String
    var color : Color
    var action : (() -> Void)? = nil
    
    var body: some View {
        let content = VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        
        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

private struct DashboardHighlightRow: View {
    var systemImage : String
    var color : Color
    var title : String
    var detail : String? = nil
    var action : (() -> Void)? = nil
    
    var body: some View {
        let row = HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 0)
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        
        if let action {
            Button(action: action) {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }
}
