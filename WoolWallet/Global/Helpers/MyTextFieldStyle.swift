//
//  TextFieldStyle.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI

struct MyTextFieldStyle: TextFieldStyle {
    let isNumber: Bool?
    
    init(isNumber: Bool? = false) {
        self.isNumber = isNumber
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(isNumber! ? EdgeInsets() : EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 6))
            .cornerRadius(8)
            .border(isNumber! ? Color.white : Color.gray, width: 0.3) // Border for each item
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                    .stroke(isNumber! ? Color.white : Color.gray, lineWidth: 0.3)
            )
            .font(.body)
    }
}
