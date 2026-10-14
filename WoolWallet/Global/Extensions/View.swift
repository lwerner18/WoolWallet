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
        self.clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.5), radius: 4)
    }
    
    func xsImageCarousel() -> some View {
        self.frame(width: 100, height: 125)
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Sizes a horizontally scrolling card relative to its scroll view, leaving the next card peeking when there are several.
    func simpleScrollItem(count : Int) -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            count > 1 ? length * 0.9 : length
        }
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
            .clipShape(RoundedRectangle(cornerRadius: 25))
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

/// Cancel button for add/edit forms that asks before throwing away unsaved changes.
struct DiscardChangesButton: View {
    var hasChanges: Bool
    var onDiscard: () -> Void
    
    @State private var showConfirmation = false
    
    var body: some View {
        Button("Cancel") {
            if hasChanges {
                showConfirmation = true
            } else {
                onDiscard()
            }
        }
        .confirmationDialog(
            "Are you sure you want to discard your changes?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive, action: onDiscard)
            Button("Keep Editing", role: .cancel) {}
        }
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
