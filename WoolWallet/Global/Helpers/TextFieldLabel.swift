//
//  TextFieldLabel.swift
//  WoolWallet
//
//  Created by Mac on 7/20/24.
//

import Foundation
import SwiftUI

struct TextFieldLabel:  View {
    let name: String
    let icon: String
    let inline : Bool?
    
    init(name: String, icon : String, inline : Bool? = false) {
        self.name = name
        self.icon = icon
        self.inline = inline
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 4)
            
            Text(name)
            
            Spacer()
            
        }
        .padding(.bottom, inline! ? 0 : 4)
    }
}
