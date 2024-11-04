//
//  RowCounterForm.swift
//  WoolWallet
//
//  Created by Mac on 10/31/24.
//

import Foundation
import SwiftUI

struct RowCounterForm: View {
    // @Environment variables
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var rowCounter : RowCounter
    @State private var bounce: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var showMinus: Bool = false
    @State private var showConfirmationDialog = false
    
    @State private var displayedCount: Int // Temporary count variable
    
    init(rowCounter: RowCounter) {
        self.rowCounter = rowCounter
        self._displayedCount = State(initialValue: Int(rowCounter.count)) // Initialize the temporary count
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .overlay(
                        Text("\(displayedCount)")
                            .font(.system(size: 100))
                            .bold()
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1) // Draw a visible border
                                    .frame(width: 180, height: 180)
                            )
                            .scaleEffect(bounce)
                            .rotationEffect(.degrees(rotation))
                    )
                    .onTapGesture {
                        displayedCount += 1
                        rowCounter.count += 1 // Increment count on tap
                        
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                            bounce = 1.2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                bounce = 1.0
                            }
                        }
                    }
                    .onChange(of: displayedCount) {
                        if displayedCount > 0 && !showMinus {
                            withAnimation {
                                showMinus = true
                            }
                        } else if displayedCount < 1 {
                            withAnimation {
                                showMinus = false
                            }
                        }
                    }
                    .sensoryFeedback(.increase, trigger: displayedCount)
                    .edgesIgnoringSafeArea(.all) // Extend tappable area to edges
                
                HStack {
                    if showMinus {
                        Button {
                            displayedCount -= 1 // Reset displayed count
                            rowCounter.count -= 1
                            
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                                bounce = 0.8
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    bounce = 1.0
                                }
                            }
                        } label: {
                            Label("", systemImage : "minus")
                                .font(.system(size: 40))
                        }
                        .transition(.scale)
                    }
                    
                    Spacer()
                    
                    Button {
                        showConfirmationDialog = true
                    } label: {
                        Label("", systemImage : "trash")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.red)
                    }
                    
                }
                .padding(20)
           
          
            }
            .navigationTitle(Binding(
                get: { rowCounter.name ?? "" }, // Provide a default value
                set: { rowCounter.name = $0.isEmpty ? nil : $0 } // Set to nil if the string is empty
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Dismiss")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        displayedCount = 0 // Reset displayed count
                        rowCounter.count = 0
                        
                        withAnimation {
                            rotation += 360 // Complete rotation
                        }
                    } label: {
                        Text("Reset")
                    }
                }
               
            }
            .alert("Are you sure you want to delete this counter?", isPresented: $showConfirmationDialog) {
                Button("Delete", role: .destructive) {
                    managedObjectContext.delete(rowCounter)
                    
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {}
            }
        }

    }
}

struct QuarterCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY)) // Start at bottom left
        path.addArc(center: CGPoint(x: rect.minX, y: rect.maxY),
                    radius: rect.width,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false) // Draw the arc
        path.closeSubpath() // Close the path to form the shape
        return path
    }
}
