//
//  ProjectDateDisplay.swift
//  WoolWallet
//
//  Created by Mac on 11/6/24.
//

import Foundation
import SwiftUI
import UIKit

struct ProjectDateDisplay : View {
    @ObservedObject var project : Project
    
    var body : some View {
        VStack(spacing: 3) {
            if project.inProgress, let startDate = project.startDate {
                if let started = DateUtils.shared.formatDate(startDate) {
                    Text("Started \(started)")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.footnote)
                }
                
                Spacer()
                
                let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date.now).day ?? 0
                
                if daysPassed > 0 {
                    HStack {
                        Image(systemName : "timer")
                        
                        Text("\(daysPassed) day\(daysPassed > 1 ? "s" : "") passed")
                    }
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .font(.caption2)
                }
            } else if project.complete, let startDate = project.startDate {
                if let started = DateUtils.shared.formatDate(startDate) {
                    Text("Started \(started)")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.footnote)
                }
                
                if let endDate = project.endDate, let completed = DateUtils.shared.formatDate(endDate) {
                    Text("Completed \(completed)")
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.footnote)
                    
                    Spacer()
                    
                    let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                    
                    if daysPassed > 0 {
                        HStack {
                            Image(systemName : "calendar")
                            
                            Text("Took \(daysPassed) day\(daysPassed > 1 ? "s" : "")")
                        }
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .font(.caption2)
                    }
                }
            }
        }
    }
}

/// SwiftUI's compact DatePicker flips between short and medium formats whenever
/// its parent re-renders (e.g. a row-counter FetchRequest update). UIDatePicker
/// keeps one format across those refreshes.
struct StableCompactDatePicker: UIViewRepresentable {
    @Binding var date: Date
    var minimumDate: Date? = nil
    var maximumDate: Date? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> DatePickerHost {
        let host = DatePickerHost()
        host.picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return host
    }
    
    func updateUIView(_ host: DatePickerHost, context: Context) {
        context.coordinator.parent = self
        
        let picker = host.picker
        if !Calendar.current.isDate(picker.date, inSameDayAs: date) {
            picker.date = date
        }
        
        picker.minimumDate = minimumDate
        picker.maximumDate = maximumDate
        host.invalidateIntrinsicContentSize()
    }
    
    final class Coordinator: NSObject {
        var parent: StableCompactDatePicker
        
        init(_ parent: StableCompactDatePicker) {
            self.parent = parent
        }
        
        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
    }
}

/// Reports the compact picker's real size so SwiftUI HStacks don't squash it.
final class DatePickerHost: UIView {
    let picker = UIDatePicker()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(picker)
        
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.topAnchor.constraint(equalTo: topAnchor),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        let size = picker.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        // Compact controls are ~34pt; never let SwiftUI collapse below that
        return CGSize(width: max(size.width, 1), height: max(size.height, 34))
    }
}