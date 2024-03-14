//
//  TextFieldStyle.swift
//  WoolWallet
//
//  Created by Mac on 3/11/24.
//

import Foundation
import SwiftUI

struct MyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 6))
            .cornerRadius(8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .font(.body)
    }
}
