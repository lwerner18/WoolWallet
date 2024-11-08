//
//  CenteredLoader.swift
//  WoolWallet
//
//  Created by Mac on 11/8/24.
//

import Foundation
import SwiftUI

struct CenteredLoader : View {
    var body : some View {
        HStack {
            Spacer()
            
            ProgressView("")
                .progressViewStyle(CircularProgressViewStyle())
            
            Spacer()
        }
    }
}
