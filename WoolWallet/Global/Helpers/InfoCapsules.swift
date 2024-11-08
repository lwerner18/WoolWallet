//
//  InfoCapsule.swift
//  WoolWallet
//
//  Created by Mac on 11/7/24.
//

import Foundation
import SwiftUI

struct InfoCapsules : View {
    var detailProps : [DetailProp]
    
    var body : some View {
        FlexView(data: detailProps, spacing: 6) { prop in
            HStack {
                if prop.useImage {
                    Image(prop.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                    
                    Text(prop.text)
                } else {
                    Label(prop.text, systemImage : prop.icon)
                }
            }
            .infoCapsule()

        }
    }
}
