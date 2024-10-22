//
//  View.swift
//  WoolWallet
//
//  Created by Mac on 3/12/24.
//

import Foundation
import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
    
    func yarnDataRow() -> some View {
        modifier(YarnDataRow())
    }
    
    func scrollTracker(scrollOffset: Binding<CGPoint>, name : String) -> some View {
        modifier(ScrollTracker(scrollOffset : scrollOffset, name: name))
    }
    
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
    
    func infoCapsule(isSmall : Bool = false) -> some View {
        self
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(Color.primary)
            .font(isSmall ? .caption2 : .callout)
            .padding(.vertical, isSmall ? 5 : 8) // Padding for the section
            .padding(.horizontal, isSmall ? 8 : 12) // Padding for the section
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(25) // Rounded corners for the section
            .shadow(radius: 0.5)
    }
}
