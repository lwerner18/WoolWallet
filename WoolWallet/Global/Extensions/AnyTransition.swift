//
//  AnyTransition.swift
//  WoolWallet
//
//  Created by Mac on 9/23/24.
//

import Foundation
import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}
