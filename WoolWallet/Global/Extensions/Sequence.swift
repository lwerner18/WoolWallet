//
//  Sequence.swift
//  WoolWallet
//
//  Created by Mac on 9/22/24.
//

import Foundation

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
