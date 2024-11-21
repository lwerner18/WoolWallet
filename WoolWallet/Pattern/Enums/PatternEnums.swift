//
//  PatternEnums.swift
//  WoolWallet
//
//  Created by Mac on 10/2/24.
//

import Foundation

enum PatternTab : String, CaseIterable, Identifiable, Equatable, CustomStringConvertible {
    var id: String { self.rawValue }
    
    case all = "All"
    case notUsed = "Not Used"
    case used = "Used"
    
    // CustomStringConvertible
    var description: String {
        self.rawValue
    }
}

enum PatternType : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case crochet = "Crochet"
    case knit = "Knit"
    case tunisian = "Tunisian"
}

enum CrochetHookSize : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none                  = "--"
    case twoPointTwoFive       = "2.25mm (B-1)"
    case twoPointFive          = "2.5mm"
    case twoPointSevenFive     = "2.75mm (C-2)"
    case threePointOneTwoFive  = "3.125mm (D)"
    case threePointTwoFive     = "3.25mm (D-3)"
    case threePointFive        = "3.5mm (E4)"
    case threePointSevenFive   = "3.75mm (F-5)"
    case four                  = "4mm (G-6)"
    case fourPointTwoFive      = "4.25mm (G)"
    case fourPointFive         = "4.5mm (7)"
    case five                  = "5mm (H-8)"
    case fivePointTwoFive      = "5.25mm (I)"
    case fivePointFive         = "5.5mm (I-9)"
    case fivePointSevenFive    = "5.75mm (J)"
    case six                   = "6mm (J-10)"
    case sixPointFive          = "6.5mm (K-10.5)"
    case seven                 = "7mm"
    case eight                 = "8mm (L-10)"
    case nine                  = "9mm (M/N-13)"
    case ten                   = "10mm (N/P-15)"
    case elevenPointFive       = "11.5mm (P-16)"
    case twelve                = "12mm"
    case fifteen               = "15mm (P/Q)"
    case fifteenPointSevenFive = "15.75mm (Q)"
    case sixteen               = "16mm (Q)"
    case nineteen              = "19mm (S)"
    case twentyFive            = "25mm (T/U/X)"
    case thirty                = "30mm (T/X)"
}

enum KnitNeedleSize : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none                  = "--"
    case twoPointTwoFive       = "2.25mm (1)"
    case twoPointSevenFive     = "2.75mm (2)"
    case threePointTwoFive     = "3.25mm (3)"
    case threePointFive        = "3.5mm (4)"
    case threePointSevenFive   = "3.75mm (5)"
    case four                  = "4mm (6)"
    case fourPointFive         = "4.5mm (7)"
    case five                  = "5mm (8)"
    case fivePointFive         = "5.5mm (9)"
    case six                   = "6mm (10)"
    case sixPointFive          = "6.5mm (10.5)"
    case eight                 = "8mm (11)"
    case nine                  = "9mm (13)"
    case ten                   = "10mm (15)"
    case twelvePointSevenFive  = "12.75mm (17)"
    case fifteen               = "15mm (19)"
    case nineteen              = "19mm (35)"
    case twentyFive            = "25mm (50)"
}

enum Item : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none      = "--"
    case shirt     = "Shirt"
    case sweater   = "Sweater"
    case shawl     = "Shawl"
    case beanie    = "Beanie"
    case socks     = "Socks"
    case blanket   = "Blanket"
    case scarf     = "Scarf"
    case mittens   = "Mittens"
    case cardigan  = "Cardigan"
    case bag       = "Bag"
    case tankTop   = "Tank Top"
    case vest      = "Vest"
    case household = "Household"
    case other     = "Other"
}

enum PatternNotion : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none            = "--"
    case stitchMarkers   = "Stitch Markers"
    case rowCounters     = "Row Counters"
    case tapestryNeedles = "Tapestry Needles"
    case measuringTape   = "Measuring Tape"
    case yarnWinder      = "Yarn Winder"
    case yarnBowl        = "Yarn Bowl"
    case scissors        = "Scissors"
    case needleGauge     = "Needle Gauge"
    case cableNeedles    = "Cable Needles"
    case pomPomMaker     = "Pom Pom Maker"
    case swatchTool      = "Swatch Tool"
    case stitchHolders   = "Stitch Holders"
    case projectBags     = "Project Bags"
    case yarnSnips       = "Yarn Snips"
    case knittersLanyard = "Knitters' Lanyard"
    case notionPouches   = "Notion Pouches"
    case blockingMats    = "Blocking Mats"
    case darningNeedle   = "Darning Needle"
    case other           = "Other"
}

enum PatternTechnique : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case none   = "--"
    case other  = "Other"
    
    // crochet techniques
    case slipKnot                = "Slip Knot"
    case chainStitch             = "Chain Stitch"
    case singleCrochet           = "Single Crochet"
    case halfDoubleCrochet       = "Half Double Crochet"
    case doubleCrochet           = "Double Crochet"
    case tripleCrochet           = "Triple Crochet"
    case slipStitch              = "Slip Stitch"
    case shellStitch             = "Shell Stitch"
    case vStitch                 = "V-Stitch"
    case grannySquare            = "Granny Square"
    case bobbleStitch            = "Bobble Stitch"
    case clusterStitch           = "Cluster Stitch"
    case crossStitch             = "Cross Stitch"
    case frontPostStitch         = "Front Post Stitch"
    case backPostStitch          = "Back Post Stitch"
    case colorChanges            = "Color Changes"
    case joinAsYouGo             = "Join As You Go"
    case foundationRowTechniques = "Foundation Row Techniques"
    case surfaceCrochet          = "Surface Crochet"
    case overlayCrochet          = "Overlay Crochet"
    
    // knitting techniques
    case castingOn          = "Casting On"
    case bindingOff         = "Binding Off"
    case knitStitch         = "Knit Stitch"
    case purlStitch         = "Purl Stitch"
    case garterStitch       = "Garter Stitch"
    case stockinetteStitch  = "Stockinette Stitch"
    case ribbing            = "Ribbing"
    case cableKnitting      = "Cable Knitting"
    case laceKnitting       = "Lace Knitting"
    case colorwork          = "Colorwork"
    case shortRows          = "Short Rows"
    case mosaicKnitting     = "Mosaic Knitting"
    case twistedStitches    = "Twisted Stitches"
    case kitchenerStitch    = "Kitchener Stitch"
    case doubleKnitting     = "Double Knitting"
    case entrelac           = "Entrelac"
    case feltedKnitting     = "Felted Knitting"
    case threeNeedleBindOff = "Three-Needle Bind Off"
    case seaming            = "Seaming"
    case blocking           = "Blocking"
    case beading            = "Beading"
    case iCord              = "I-Cord"
    
    // add tunisian techniques
    case tunisianSimpleStitch                          = "Tunisian Simple Stitch (TSS)"
    case tunisianKnitStitch                            = "Tunisian Knit Stitch (TKS)"
    case tunisianPurlStitch                            = "Tunisian Purl Stitch (TPS)"
    case tunisianFullStitch                            = "Tunisian Full Stitch (TFS)"
    case tunisianReverseStitch                         = "Tunisian Reverse Stitch (TRS)"
    case tunisianLaceStitch                            = "Tunisian Lace Stitch"
    case tunisianShellStitch                           = "Tunisian Shell Stitch"
    case tunisianHoneycombStitch                       = "Tunisian Honeycomb Stitch"
    case tunisianSimpleStitchWithIncreasesAndDecreases = "Tunisian Simple Stitch with Increases and Decreases"
    case tunisianColorwork                             = "Tunisian Colorwork"
    case tunisianRibbing                               = "Tunisian Ribbing"
    case tunisianDoubleCrochet                         = "Tunisian Double Crochet (TDC)"
    case tunisianEntrelac                              = "Tunisian Entrelac"
    case tunisianChevronStitch                         = "Tunisian Chevron Stitch"
}
