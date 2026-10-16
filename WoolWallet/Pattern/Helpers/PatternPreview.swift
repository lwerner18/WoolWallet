//
//  PatternPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/1/24.
//

import Foundation
import SwiftUI

/// Compact pattern row for project details and similar InfoCards
struct PatternPreview: View {
    @ObservedObject var pattern : Pattern
    
    var body: some View {
        HStack(spacing: 14) {
            PatternCover(pattern: pattern, cornerRadius: 8, iconSize: Size.medium)
                .frame(width: 64, height: 85)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name ?? "No Name")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let designer = pattern.designer, !designer.isEmpty {
                    Text(designer)
                        .font(.subheadline)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                Text(pattern.typeAndItems)
                    .font(.caption)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                
                if pattern.oneSize {
                    Text("One Size")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                } else if let size = pattern.intendedSize, !size.isEmpty {
                    Text("Size \(size)")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

/// Photo-forward pattern card for suggestion carousels
struct PatternMatchCard: View {
    @ObservedObject var pattern : Pattern
    @ObservedObject var weightAndYardage : WeightAndYardage
    var isFavorite : Bool
    var onToggleFavorite : () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay { cover }
                .overlay(alignment: .topTrailing) {
                    MatchFavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                        .padding(8)
                }
                .entityCardMedia()
            
            VStack(alignment: .leading, spacing: 3) {
                Text(pattern.name ?? "No Name")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let designer = pattern.designer, !designer.isEmpty {
                    Text(designer)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                Text(pattern.typeAndItems)
                    .font(.caption2)
                    .foregroundStyle(Color(UIColor.secondaryLabel))
                    .lineLimit(1)
                
                PatternWandYCaption(weightAndYardage: weightAndYardage)
            }
        }
        .entityCardChrome()
        .accessibilityElement(children: .combine)
    }
    
    private var cover: some View {
        let wash = PatternUtils.shared.getItemDisplay(for: pattern.patternItems.first?.item).color
        
        // Prefer the real cover image filling the card when one exists
        return PatternCover(pattern: pattern, cornerRadius: 0, iconSize: Size.large)
            .background(
                LinearGradient(
                    colors: [wash.opacity(0.22), wash.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

struct PatternWandYCaption: View {
    @ObservedObject var weightAndYardage : WeightAndYardage
    
    var body: some View {
        let unit = weightAndYardage.unitOfMeasure?.lowercased() ?? ""
        var parts : [String] = []
        
        if weightAndYardage.currentLength > 0 {
            parts.append("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.currentLength.formatted) \(unit) needed")
        }
        
        if let weight = weightAndYardage.weight, !weight.isEmpty {
            parts.append(weight)
        }
        
        return Text(parts.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(Color(UIColor.secondaryLabel))
            .lineLimit(2)
    }
}
