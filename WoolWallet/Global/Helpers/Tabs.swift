//
//  Tabs.swift
//  WoolWallet
//
//  Created by Mac on 10/29/24.
//

import Foundation
import SwiftUI

struct Tabs<T: CaseIterable & Identifiable & Hashable & CustomStringConvertible>: View where T.AllCases: RandomAccessCollection {
    @Binding var selectedTab: T
    var tabCounts : [TabCount<T>]
    /// Reports the segmented control's global frame, e.g. to animate items toward a segment
    var onFrameChange : ((CGRect) -> Void)? = nil
    
    var body: some View {
        Picker("Show", selection: $selectedTab.animation()) {
            ForEach(T.allCases) { tab in
                Text("\(tab.description) (\(count(for: tab)))").tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .background {
            GeometryReader { proxy in
                let frame = proxy.frame(in: .global)
                
                Color.clear
                    .onAppear { onFrameChange?(frame) }
                    .onChange(of: frame) { _, newFrame in onFrameChange?(newFrame) }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func count(for tab: T) -> Int {
        tabCounts.first { $0.tab == tab }?.count ?? 0
    }
    
    /// Center of a tab's segment in global coordinates, given the frame reported through `onFrameChange`
    static func segmentCenter(of tab: T, in frame: CGRect) -> CGPoint? {
        guard frame != .zero, let index = T.allCases.firstIndex(of: tab) else { return nil }
        
        let position = T.allCases.distance(from: T.allCases.startIndex, to: index)
        let segmentWidth = frame.width / CGFloat(T.allCases.count)
        
        return CGPoint(x: frame.minX + segmentWidth * (CGFloat(position) + 0.5), y: frame.midY)
    }
}
