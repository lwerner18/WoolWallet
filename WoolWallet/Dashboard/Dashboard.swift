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

enum PatternTypeChart : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case all = "All"
    case crochet = "Crochet"
    case knit = "Knit"
    case tunisian = "Tunisian"
}

struct Dashboard : View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    
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
        fetchRequest: PatternItem.fetchItems()
    ) private var patternItems: FetchedResults<PatternItem>
    
    @FetchRequest(
        fetchRequest: WeightAndYardage.fetchWeightsAndSkeins()
    ) private var weightsAndSkeins: FetchedResults<WeightAndYardage>
    
    @State var exporting : Bool = false
    @State var animateItemCounts : [Bool] = Item.allCases.filter{$0 != Item.none}.map{_ in return false}
    @State var animateWeightCounts : [Bool] = Weight.allCases.filter{$0 != Weight.none}.map{_ in return false}
    @State var patternTypeChart : PatternTypeChart = PatternTypeChart.all
    @State private var selectedAngle: Double? = nil
    
    @Binding var mainTab : MainTab
    
    var selectedYarnWeight: YarnWeightCount? {
        var sum = 0.0
        
        if selectedAngle == nil {
            return nil
        }
        
        var selected : YarnWeightCount? = nil
        
        for yarnWeightCount in yarnWeightCounts {
            sum += yarnWeightCount.count
            
            if sum > selectedAngle! {
                selected = yarnWeightCount
                break
            }
        }
        
        return selected
    }
    
    var averageTimeToComplete: Double {
        var totalDays = 0
        
        if completedProjects.isEmpty {
            return Double(totalDays)
        }
        
        completedProjects.forEach { project in
            totalDays += Calendar.current.dateComponents([.day], from: project.startDate!, to: project.endDate!).day ?? 0
        }
        
        return Double(totalDays) / Double(completedProjects.count)
    }
    
    var unusedSkeins: Double {
        var count = 0.0
        
        Array(weightsAndSkeins).forEach { weightAndYardage in
            if weightAndYardage.yarn!.isSockSet {
                count += 1;
            } else {
                count += weightAndYardage.currentSkeins
            }
        
        }
        
        return count
    }
    
    var itemCounts: [ItemCount] {
        var itemCounts : [ItemCount] = []
        
        Item.allCases.forEach { item in
            if item != Item.none {
                let filteredCount = Array(patternItems).filter { patternItem in
                    if patternItem.item != nil && patternItem.item == item.rawValue {
                        switch patternTypeChart {
                        case .all:
                            return true
                        case .crochet:
                            return patternItem.pattern!.type == PatternType.crochet.rawValue
                        case .knit:
                            return patternItem.pattern!.type == PatternType.knit.rawValue
                        case .tunisian:
                            return patternItem.pattern!.type == PatternType.tunisian.rawValue
                        }
                    }
                    
                    return false
                }.count
                
                itemCounts.append(ItemCount(item: item, count: filteredCount))
            }
        }
        
        return itemCounts.sorted(by: { $0.item.rawValue < $1.item.rawValue })
    }
    
    var maxItemCount: Int {
        var max : Int = 0
        
        itemCounts.forEach { itemCount in
            if itemCount.count > max {
                max = itemCount.count
            }
        }
        
        return max
    }
    
    var yarnWeightCounts : [YarnWeightCount] {
        var weightCounts : [YarnWeightCount] = []
        
        Weight.allCases.forEach { weight in
            if weight != Weight.none {
                var count = 0.0
                
                Array(weightsAndSkeins).filter { weightAndYardage in
                    weightAndYardage.weight != nil && weightAndYardage.weight == weight.rawValue && weightAndYardage.currentSkeins > 0
                }.forEach { weightAndYardage in
                    count += weightAndYardage.currentSkeins
                }
                
                weightCounts.append(YarnWeightCount(weight: weight, count: count))
            }
        }
        
        return weightCounts.sorted(by: { $0.weight.rawValue < $1.weight.rawValue })
    }
    
    var totalYarnWeights : Double {
        return yarnWeightCounts.map { $0.count }.reduce(0, +)
    }
    
    var body : some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    if currentProjects.count > 0 {
                        Text("Current Project\(currentProjects.count > 1 ? "s (\(currentProjects.count))" : "")")
                            .infoCardHeader()
                        
                        SimpleHorizontalScroll(count: currentProjects.count) {
                            ForEach(currentProjects, id : \.id) { project in
                                ProjectPreview(
                                    project: project,
                                    displayedProject: .constant(nil),
                                    navigateOnTap : true
                                )
                            }
                        }
                    }
                    
                    Text("Stats")
                        .infoCardHeader()
                    
                    InfoCard(backgroundColor: Color(UIColor.secondarySystemBackground)) {
                        VStack(spacing: 25) {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(currentProjects.count)")
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Current Projects")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text("\(completedProjects.count)")
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Finished Projects")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption2)
                                    
                                }
                                .bold()
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text(unusedSkeins.formatted)
                                        .foregroundStyle(Color.primary)
                                        .font(.title2)
                                    
                                    Text("Unused Skeins")
                                        .foregroundStyle(Color(UIColor.secondaryLabel))
                                        .font(.caption)
                                    
                                }
                                .bold()
                                
                                Spacer()
                            }
                        }
                    }
                    
                    InfoCard(backgroundColor: Color(UIColor.secondarySystemBackground)) {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("\(averageTimeToComplete.formatted) days")
                                    .foregroundStyle(Color.primary)
                                    .font(.title)
                                
                                Text("Average Project Duration")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.caption2)
                                
                            }
                            .bold()
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    Text("Yarn Weights")
                        .infoCardHeader()
                        .padding(.bottom, 15)
                    
                    Chart {
                        ForEach(yarnWeightCounts.indices, id: \.self) { index in
                            let yarnWeightCount = yarnWeightCounts[index]
                            
                            if yarnWeightCount.count > 0 {
                                SectorMark(
                                    angle: .value("Percentage", animateWeightCounts[index] ? yarnWeightCount.count : 0),
                                    innerRadius: .ratio(0.65),
                                    outerRadius: .ratio(0.9),
                                    angularInset: 2
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("Weight", yarnWeightCount.weight.getDisplay()))
                                .opacity(0.8)
                                .annotation(position: .overlay) {
                                    Text(yarnWeightCount.count.formatted)
                                        .foregroundStyle(Color.primary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartAngleSelection(value: $selectedAngle)
                    .chartGesture { chart in
                        SpatialTapGesture()
                            .onEnded { event in
                                let angle = chart.angle(at: event.location)
                                chart.selectAngleValue(at: angle)
                            }
                    }
                    .chartOverlay { chartProxy in
                        GeometryReader { geometry in
                            if let anchor = chartProxy.plotFrame {
                                let frame = geometry[anchor]
                                let radius = min(geometry.size.width, geometry.size.height) / 2
                                let center = CGPoint(x: frame.midX, y: frame.midY)
                                
                                ForEach(yarnWeightCounts.indices, id: \.self) { index in
                                    let item = yarnWeightCounts[index]
                                    
                                    if item.count > 0 {
                                        let startAngle = angle(for: index, in: yarnWeightCounts)
                                        let endAngle = angle(for: index + 1, in: yarnWeightCounts)
                                        let midAngle : Angle = (startAngle + endAngle) / 2
                                        let midAngleRadian = CGFloat(midAngle.radians - .pi*1.5)
                                        
                                        let multiplier = abs(cos(midAngle.radians)) + abs(sin(midAngle.radians))
                                        
                                        let distance = multiplier - 1
                                        
                                        let labelPositionAngle = multiplier < 1.3
                                        ? midAngleRadian < .pi*1.5 ? .radians(midAngle.radians - (.pi/10)*distance) : .radians(midAngle.radians + (.pi/10)*distance)
                                        : midAngle
                                        
//                                        let labelDistance = radius + (midAngleRadian > .pi*0.5 && midAngleRadian < .pi*1.5 ? 80/denom : 60/denom)
                                        let labelDistance = radius + 25*multiplier
                                        let labelPosition = point(from: center, radius: labelDistance, angle: labelPositionAngle)
                                        
                                        let startLine = point(from: center, radius: labelDistance * 0.8, angle: midAngle)
                                        let endLine = point(from: center, radius: radius*0.91, angle: midAngle)
                                        
                                        VStack {
                                            Text("\(item.weight.getDisplay())")
                                            Text("\(((item.count/totalYarnWeights)*100).formatted)%")
                                        }
                                        .padding()
                                        .font(.caption2)
                                        .foregroundStyle(Color.primary)
                                        .position(labelPosition)
                                     
                                           
                                        
                                        Path() { path in
                                            path.move(to: startLine)
                                            path.addLine(to: endLine)
                                        }
                                        .stroke(
                                            Color.primary,
                                            style: StrokeStyle(
                                                lineWidth: 1,
                                                lineCap: .round
                                            )
                                        )
                                    }
                                }
                            }
                            
                          
                        }
                    }
                    .chartBackground { chartProxy in
                        GeometryReader { geometry in
                            if let anchor = chartProxy.plotFrame {
                                let frame = geometry[anchor]
                                
                                HStack {
                                    if selectedYarnWeight != nil {
                                        VStack {
                                            Text("\(selectedYarnWeight!.weight.getDisplay())")
                                            Text(selectedYarnWeight!.count.formatted)
                                            Text("\(((selectedYarnWeight!.count/totalYarnWeights)*100).formatted)%")
                                        }
                                    }
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    .onAppear {
                        selectedAngle = nil
                        animateYarnWeightCounts()
                    }
                    .padding(.vertical, 40)
                    .frame(height: 300)
                    
                    Text("Number of items by pattern")
                        .infoCardHeader()
                        .padding(.top, 30)
                    
                    Picker("Type", selection: $patternTypeChart) {
                        ForEach(PatternTypeChart.allCases, id: \.id) { patternTypeChart in
                            Text(patternTypeChart.rawValue).tag(patternTypeChart)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                  
                    
                    Chart {
                        ForEach(itemCounts.indices, id: \.self) { index in
                            let itemCount = itemCounts[index]
                            
                            BarMark(
                                x: .value("Count", animateItemCounts[index] ? itemCount.count : 0),
                                y: .value("Item", itemCount.item.rawValue)
                            )
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 10,
                                    topTrailingRadius: 10
                                )
                            )
                            .foregroundStyle(PatternUtils.shared.getItemDisplay(for: itemCount.item).color)
                            .annotation(position: .trailing) {
                                Text(String(itemCount.count))
                                    .foregroundStyle(Color(UIColor.secondaryLabel))
                                    .font(.caption2)
                            }
                            
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0...maxItemCount)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel(centered: true)
                                .foregroundStyle(Color.primary)
                                .offset(x: -65)
                        }
                    }
                    .frame(height: 350)
                    .padding(.vertical, 10)
                    .padding(.leading, 60)
                    .padding(.trailing, 10)
                    .onAppear {
                        animateItems()
                    }
                    .onChange(of: patternTypeChart) {
                        animateItems()
                    }
         
                }
                .padding()
            }
            .navigationTitle("Dashboard")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    if exporting {
//                        ProgressView("")
//                            .progressViewStyle(CircularProgressViewStyle())
//                    } else {
//                        ShareLink(item:generateCSV()) {
//                            Label("Export CSV", systemImage: "square.and.arrow.up")
//                        }
//                    }
//                }
//            }
        }
    }
    
    // Function to calculate the angle for a given index
    func angle(for index: Int, in segments: [YarnWeightCount]) -> Angle {
        let ratio = segments.prefix(index).map { $0.count }.reduce(0, +) / totalYarnWeights
        return .radians((.pi*2 * ratio) + .pi*1.5)
    }
    
    // Function to calculate a point on the circle
    func point(from center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let radian = CGFloat(angle.radians)
        return CGPoint(
            x: center.x + cos(radian) * radius,
            y: center.y + sin(radian) * radius
        )
    }
    
    func animateItems() {
        animateItemCounts = Item.allCases.filter{$0 != Item.none}.map{_ in return false}
        
        for (index,_) in itemCounts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateItemCounts[index] = true
                }
            }
        }
    }
    
    func animateYarnWeightCounts() {
        animateWeightCounts = Weight.allCases.filter{$0 != Weight.none}.map{_ in return false}
        
        for (index,_) in yarnWeightCounts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateWeightCounts[index] = true
                }
            }
        }
    }
    
    func getAllYarns() -> [Yarn] {
        let fetchRequest: NSFetchRequest<Yarn> = Yarn.fetchRequest()
        
        do {
            return try managedObjectContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch matching yarns: \(error)")
            return []
        }
    }
    
    func generateCSV() -> URL {
        exporting = true
        
        let allYarns = getAllYarns()
        
        var fileURL: URL!
        // heading of CSV file.
        let heading = "Name, Dyer, Caked?, Mini?, Archived?, Notes\n"
        
        // file rows
        let rows = allYarns.map { "\($0.name ?? ""),\($0.dyer ?? ""),\($0.isCaked ? "Y" : "N"),\($0.isMini ? "Y" : "N"),\($0.isArchived ? "Y" : "N"),\($0.notes ?? "")" }
        
        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")
        
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("Yarn-Data.csv")
            
            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }
        return fileURL
    }
}
