//
//  ConditionalStack.swift
//  WoolWallet
//
//  Created by Mac on 3/20/24.
//

import Foundation
import SwiftUI

struct ConditionalStack<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
//    var isPortraitMode: Bool {
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            return windowScene.interfaceOrientation.isPortrait
//        }
//        return false
//    }
    
    var body: some View {
        Group {
            if GlobalSettings.shared.isPortraitMode {
                VStack { content }
            } else {
                HStack { content }
            }
        }
    }
}
