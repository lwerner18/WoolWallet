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
        self.cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 4)
    }
    
    func xsImageCarousel() -> some View {
        self.frame(width: 100, height: 125)
    }
    
    func simpleScrollItem(count : Int) -> some View {
        self.frame(width: UIScreen.main.bounds.width * (count > 1 ? 0.85 : 0.92))
    }
    
    func infoCardHeader() -> some View {
        self.padding(.top, 15) // Add some padding below the header
            .foregroundStyle(Color(UIColor.secondaryLabel))
            .font(.footnote)
            .textCase(.uppercase)
    }
    
    func yarnDataRow() -> some View {
        modifier(YarnDataRow())
    }
    
    func scrollTracker(scrollOffset: Binding<CGPoint>, name : String) -> some View {
        modifier(ScrollTracker(scrollOffset : scrollOffset, name: name))
    }
    
    func customFormSection(background : Color = Color(UIColor.systemGroupedBackground)) -> some View {
        modifier(CustomFormSection(background: background))
    }
    
    func filterCapsule(background : Color = Color.clear, border : Color = Color(UIColor.secondaryLabel)) -> some View {
        self.frame(minWidth: 0, maxWidth: .infinity)
            .padding(8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8)) // Apply rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: 8) // Apply corner radius to the border
                    .stroke(border, lineWidth: 0.3)
            )
    }
    
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
    
    func infoCapsule(
        isSmall : Bool = false,
        thickBorder : Bool = false,
        background : Color = Color(UIColor.secondarySystemGroupedBackground),
        border : Color = Color(UIColor.secondaryLabel)
    ) -> some View {
        self.foregroundStyle(Color.primary)
            .font(isSmall ? .caption2 : .callout)
            .padding(.vertical, isSmall ? 5 : 8) // Padding for the section
            .padding(.horizontal, isSmall ? 8 : 12) // Padding for the section
            .background(background)
            .cornerRadius(25) // Rounded corners for the section
            .shadow(radius: 0.5)
            .overlay(
                thickBorder
                ? AnyView(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(border, lineWidth: 0.3)
                )
                : AnyView(EmptyView())
            )
    }
    
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct CustomFormSection: ViewModifier {
    var background : Color
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .background(background)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
