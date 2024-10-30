//
//  PatternEnums.swift
//  WoolWallet
//
//  Created by Mac on 10/2/24.
//

import Foundation


enum PatternType : String, CaseIterable, Identifiable, Equatable {
    var id: String { self.rawValue }
    
    case crochet = "Crochet"
    case knit = "Knit"
    case tunisianCrochet = "Tunisian Crochet"
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
    
    case none          = "--"
    case shirt         = "Shirt"
    case sweater       = "Sweater"
    case beanie        = "Beanie"
    case socks         = "Socks"
    case blanket       = "Blanket"
    case scarf         = "Scarf"
    case mittens       = "Mittens"
    case cardigan      = "Cardigan"
    case bag           = "Bag"
    case tankTop       = "Tank Top"
    case householdItem = "Household Item"
    case other         = "Other"
}
