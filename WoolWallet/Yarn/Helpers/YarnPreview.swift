//
//  YarnPreview.swift
//  WoolWallet
//
//  Created by Mac on 11/8/24.
//

import Foundation
import SwiftUI
import CoreData

/// Photo or color wash thumb for yarn cards and rows
struct YarnThumb: View {
    @ObservedObject var yarn : Yarn
    var cornerRadius : CGFloat = 12
    
    private var colors : [Color] { yarn.sortedYarnColors }
    
    var body: some View {
        Color.clear
            .overlay {
                if yarn.hasImages {
                    FirstStoredPhoto(images: yarn.images, maxPixelSize: 700) {
                        colorWash
                    }
                } else {
                    colorWash
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var colorWash: some View {
        let wash = colors.isEmpty
            ? [Color(UIColor.tertiarySystemFill), Color(UIColor.secondarySystemFill)]
            : (colors.count == 1 ? [colors[0], colors[0].opacity(0.55)] : Array(colors.prefix(4)))
        
        return LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                if colors.isEmpty {
                    Image(systemName: "volleyball")
                        .font(.title2)
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
    }
}

/// Compact yarn row for project details and similar InfoCards
struct YarnPreview: View {
    @ObservedObject var yarnWandY : WeightAndYardage
    
    var body: some View {
        if let yarn = yarnWandY.yarn {
            HStack(spacing: 14) {
                YarnThumb(yarn: yarn, cornerRadius: 10)
                    .frame(width: 72, height: 72)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(yarn.name ?? "No Name")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    
                    if let dyer = yarn.dyer, !dyer.isEmpty {
                        Text(dyer)
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .lineLimit(1)
                    }
                    
                    YarnWandYCaption(weightAndYardage: yarnWandY)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }
}

struct YarnPreviewForProject: View {
    @ObservedObject var yarnWandY : WeightAndYardage
    @ObservedObject var projectPairing : ProjectPairing
    @ObservedObject var project : Project
    
    var body: some View {
        if let yarn = yarnWandY.yarn {
            let unit = yarnWandY.unitOfMeasure?.lowercased() ?? ""
            let length = project.complete
                ? projectPairing.lengthUsed
                : projectPairing.patternWeightAndYardage?.currentLength ?? 0
            let verb = project.inProgress ? "Using" : project.complete ? "Used" : "Requires"
            
            HStack(spacing: 14) {
                YarnThumb(yarn: yarn, cornerRadius: 10)
                    .frame(width: 72, height: 72)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(yarn.name ?? "No Name")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    
                    if let dyer = yarn.dyer, !dyer.isEmpty {
                        Text(dyer)
                            .font(.subheadline)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                            .lineLimit(1)
                    }
                    
                    Text("\(verb) \(length.formatted) \(unit)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primary)
                    
                    if yarnWandY.yardage > 0 && yarnWandY.grams > 0 {
                        Text("\(yarnWandY.yardage.formatted) \(unit) / \(yarnWandY.grams) g")
                            .font(.caption)
                            .foregroundStyle(Color(UIColor.secondaryLabel))
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }
}

/// Photo-forward yarn card for suggestion carousels
struct YarnMatchCard: View {
    @ObservedObject var yarnWandY : WeightAndYardage
    var isFavorite : Bool
    var onToggleFavorite : () -> Void
    var onAdd : (() -> Void)? = nil
    
    var body: some View {
        let yarn = yarnWandY.yarn
        
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let yarn {
                        YarnThumb(yarn: yarn, cornerRadius: 0)
                    } else {
                        Color(UIColor.tertiarySystemFill)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    MatchFavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                        .padding(8)
                }
                .overlay(alignment: .bottomTrailing) {
                    if let onAdd {
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.accentColor)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add to Project")
                        .padding(8)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if let yarn, yarn.isSockSet {
                        Text(sockLabel)
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }
                .entityCardMedia()
            
            VStack(alignment: .leading, spacing: 3) {
                Text(yarn?.name ?? "Yarn")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let dyer = yarn?.dyer, !dyer.isEmpty {
                    Text(dyer)
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                YarnWandYCaption(weightAndYardage: yarnWandY)
            }
        }
        .entityCardChrome()
        .accessibilityElement(children: .combine)
    }
    
    private var sockLabel: String {
        switch yarnWandY.order {
        case 0: return "Main"
        case 1: return "Mini"
        case 2: return "Mini #2"
        default: return "Sock Set"
        }
    }
}

struct YarnWandYCaption: View {
    @ObservedObject var weightAndYardage : WeightAndYardage
    
    var body: some View {
        let unit = weightAndYardage.unitOfMeasure?.lowercased() ?? ""
        var parts : [String] = []
        
        if weightAndYardage.availableLength > 0 {
            parts.append("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.availableLength.formatted) \(unit) available")
        } else if weightAndYardage.currentLength > 0 {
            parts.append("\(weightAndYardage.isExact ? "" : "~")\(weightAndYardage.currentLength.formatted) \(unit)")
        }
        
        if weightAndYardage.yardage > 0 && weightAndYardage.grams > 0 {
            parts.append("\(weightAndYardage.yardage.formatted) \(unit) / \(weightAndYardage.grams) g")
        }
        
        return Text(parts.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(Color(UIColor.secondaryLabel))
            .lineLimit(2)
    }
}

struct MatchFavoriteButton: View {
    var isFavorite : Bool
    var action : () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.subheadline.bold())
                .foregroundStyle(Color(UIColor.systemPink))
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

/// Soft spring used when favoriting reshuffles match cards
enum MatchCarouselMotion {
    static let reorder = Animation.spring(response: 0.48, dampingFraction: 0.86)
}

struct MatchCarousel<Content: View>: View {
    var title : String? = nil
    var count : Int
    /// Bumps when a card should stay on-screen through a reorder
    var scrollTarget : MatchScrollTarget? = nil
    var orderKey : [NSManagedObjectID] = []
    @ViewBuilder var content : () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.footnote)
                        .foregroundStyle(Color(UIColor.secondaryLabel))
                        .textCase(.uppercase)
                    
                    Text("\(count)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
            }
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        content()
                    }
                    .animation(MatchCarouselMotion.reorder, value: orderKey)
                }
                .scrollClipDisabled(false)
                .scrollDisabled(count <= 1)
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation(MatchCarouselMotion.reorder) {
                        proxy.scrollTo(target.id, anchor: .leading)
                    }
                }
            }
        }
    }
}

struct MatchScrollTarget: Equatable {
    let id : NSManagedObjectID
    let nonce : UUID
    
    init(_ id: NSManagedObjectID) {
        self.id = id
        self.nonce = UUID()
    }
}
