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
    
    var body: some View {
        Picker("Show", selection: $selectedTab.animation()) {
            ForEach(T.allCases) { tab in
                Text("\(tab.description) (\(count(for: tab)))").tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func count(for tab: T) -> Int {
        tabCounts.first { $0.tab == tab }?.count ?? 0
    }
}
