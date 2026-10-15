//
//  ColorNaming.swift
//  WoolWallet
//

import Foundation

/// Matches a color to the closest of the app's color names
enum ColorNaming {
    /// Shades people commonly call each name, most typical shade first since it doubles as the swatch.
    /// Names are saved on yarn and used by the color filter, so they shouldn't be renamed.
    static let references : [(name: String, hexes: [String])] = [
        ("Maroon", [
            "#800020", "#800000", "#650021", "#610023", "#80013F", "#840000", "#6B0F1A", "#722F37",
            "#5C0A1E", "#9E003A", "#4A0E1A", "#6B2D2D", "#7B1E3A", "#8B2252"
        ]),
        ("Red", [
            "#D2161E", "#E50000", "#FF0000", "#C8102E", "#BE0119", "#B22222", "#F7022A", "#EC2D01",
            "#D9544D", "#C44240", "#A03623", "#CB4154", "#E34234", "#E0303A"
        ]),
        ("Pink", [
            "#FF8FB1", "#FF81C0", "#FFC0CB", "#FFB6C1", "#FFD1DF", "#FFB7CE", "#FF69B4", "#FF028D",
            "#E75480", "#D58A94", "#CF6275", "#F29E8E", "#FE7B7C", "#C20078", "#E0218A", "#ED0DD9",
            "#DE5D83", "#F4C2C2", "#E8B4B8", "#C08081", "#AE7181"
        ]),
        ("Orange", [
            "#F28C28", "#F97306", "#FFA500", "#FF8C00", "#E17701", "#C04E01", "#CC5500", "#FF7F50",
            "#FC5A50", "#FFB07C", "#FFB16D", "#FFCBA4", "#E2725B", "#CA6641", "#FF9408", "#B7410E",
            "#A83C09", "#FA8072"
        ]),
        ("Beige", [
            "#D9C3A0", "#E6DAA6", "#D1B26F", "#D2B48C", "#E2CA76", "#C2B280", "#C8AD7F", "#C69F59",
            "#B9A281", "#D6C6A8", "#E8D5B5", "#CBB799", "#BFA88A", "#E3D3B8"
        ]),
        ("Cream", [
            "#FFF8DC", "#FFFFC2", "#FFFDD0", "#FFFFCB", "#FFFFF0", "#FFFFD4", "#FFFFE4", "#F5ECD6",
            "#F3E5AB", "#FAF0E6", "#FDF5E6", "#F5F5DC", "#F0E6D2", "#EEE3C8", "#F2E8CF"
        ]),
        ("Yellow", [
            "#F9D71C", "#FFFF14", "#FFFF00", "#FFEF00", "#FDFF52", "#FFFF84", "#FFFF81", "#FFC512",
            "#FFE135", "#F9E076", "#FFF380", "#FFF44F", "#FADA5E"
        ]),
        ("Gold", [
            "#D4A017", "#DBB40C", "#CEB301", "#E1AD01", "#FAC205", "#DAA520", "#BF9005",
            "#FEB308", "#D5B60A", "#B8860B", "#CFB53B", "#E4B04A", "#C9A227", "#D4AF37"
        ]),
        ("Green", [
            "#3A9D23", "#15B01A", "#008000", "#06470C", "#228B22", "#02AB2E", "#4CBB17", "#89FE05",
            "#32CD32", "#9FFEB0", "#98FF98", "#3EB489", "#87AE73", "#9CAF88", "#96F97B", "#90EE90",
            "#033500", "#013220", "#01A049", "#50C878", "#0B4008", "#355E3B", "#044A05", "#5CAC2D",
            "#769958", "#8A9A5B", "#8FBC8F", "#2E8B57", "#ACE1AF", "#A9BA9D", "#4F7942"
        ]),
        ("Olive", [
            "#708238", "#808000", "#6E750E", "#6B8E23", "#4B5D16", "#4B5320", "#556B2F", "#373E02",
            "#677A04", "#AAA662", "#BDB76B", "#8B8B3A", "#78866B", "#6C6A3E", "#9A9A3C"
        ]),
        ("Teal", [
            "#008080", "#029386", "#014D4E", "#06C2AC", "#40E0D0", "#13EAC9", "#00FFFF", "#7FFFD4",
            "#04D8B2", "#90E4C1", "#01889F", "#00555A", "#005F6A", "#A5D3C9", "#48D1CC", "#20B2AA",
            "#5F9EA0", "#367588", "#006D6F"
        ]),
        ("Blue", [
            "#1F5FD1", "#0343DF", "#0000FF", "#4169E1", "#0504AA", "#75BBFD", "#87CEEB", "#95D0FC",
            "#ADD8E6", "#A2CFFE", "#89CFF0", "#1E488F", "#0047AB", "#3B638C", "#1560BD", "#6495ED",
            "#6A79F7", "#B1D1FC", "#B0E0E6", "#0485D1", "#007BA7", "#4682B4", "#5A7D9A", "#5A86AD",
            "#069AF3", "#0165FC", "#1E90FF", "#5B7C99", "#7393B3", "#6699CC"
        ]),
        ("Navy", [
            "#1B2A57", "#000080", "#01153E", "#001146", "#00035B", "#020035", "#000435", "#1F2A44",
            "#233050", "#23297A", "#1B1F3B", "#191970", "#002147", "#003153", "#1D2951"
        ]),
        ("Purple", [
            "#7E1E9C", "#800080", "#9A0EEA", "#8F00FF", "#C79FEF", "#B57EDC", "#CEA2FD", "#C8A2C8",
            "#580F41", "#8E4585", "#380835", "#614051", "#380282", "#4B0082", "#6C3461", "#9B5FC0",
            "#9966CC", "#BF77F6", "#35063E", "#8E82FE", "#CCCCFF", "#825F87", "#C875C4", "#DA70D6",
            "#9370DB", "#663399", "#702963", "#E0B0FF", "#D8BFD8", "#E6E6FA"
        ]),
        ("Brown", [
            "#7B4A12", "#653700", "#8B4513", "#964B00", "#3D1C02", "#7B3F00", "#341C02", "#5C4033",
            "#AD8150", "#A6814C", "#6F4E37", "#AF6F09", "#742802", "#954535", "#9D7651", "#8B3103",
            "#A9561E", "#A0522D", "#B26400", "#635147", "#3B2A20", "#7A6A4F", "#826644", "#8B7355",
            "#A67B5B", "#483C32", "#5D4037", "#C68642", "#B5835A"
        ]),
        ("Black", [
            "#000000", "#111111", "#1A1A1A", "#1C1B1A", "#0E1116", "#1B1B22"
        ]),
        ("White", [
            "#FFFFFF", "#F8F8F8", "#F5F5F5", "#FAFAFA", "#F7F9FC", "#F2F2F2"
        ]),
        ("Gray", [
            "#808080", "#929591", "#A9A9A9", "#C0C0C0", "#D3D3D3", "#D8DCD6", "#C5C9C7", "#E0E0E0",
            "#696969", "#555555", "#404040", "#363737", "#343837", "#516572", "#708090", "#778899",
            "#95A3A6", "#A8A39A", "#8D8778"
        ])
    ]
    
    static func closestName(red: Double, green: Double, blue: Double) -> String? {
        let target = Lab(red: red, green: green, blue: blue)
        
        return labReferences.min { deltaE2000(target, $0.lab) < deltaE2000(target, $1.lab) }?.name
    }
    
    static func components(hex: String) -> (red: Double, green: Double, blue: Double) {
        var rgb : UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&rgb)
        
        return (Double((rgb >> 16) & 0xFF) / 255, Double((rgb >> 8) & 0xFF) / 255, Double(rgb & 0xFF) / 255)
    }
    
    private static let labReferences : [(name: String, lab: Lab)] = references.flatMap { reference in
        reference.hexes.map { hex in
            let rgb = components(hex: hex)
            return (reference.name, Lab(red: rgb.red, green: rgb.green, blue: rgb.blue))
        }
    }
}

/// CIE L*a*b* under D65, from sRGB components in 0...1
struct Lab {
    let l : Double
    let a : Double
    let b : Double
    
    init(red: Double, green: Double, blue: Double) {
        func linear(_ c: Double) -> Double {
            let c = min(max(c, 0), 1)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let r = linear(red), g = linear(green), b = linear(blue)
        
        let x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
        let y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b)
        let z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
        
        func f(_ t: Double) -> Double {
            t > 216.0 / 24389.0 ? cbrt(t) : (24389.0 / 27.0 * t + 16) / 116
        }
        
        let fx = f(x), fy = f(y), fz = f(z)
        
        self.l = 116 * fy - 16
        self.a = 500 * (fx - fy)
        self.b = 200 * (fy - fz)
    }
}

/// Perceptual color difference (Sharma, Wu & Dalal 2005)
func deltaE2000(_ first: Lab, _ second: Lab) -> Double {
    func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    func hue(_ b: Double, _ a: Double) -> Double {
        guard a != 0 || b != 0 else { return 0 }
        let angle = atan2(b, a) * 180 / .pi
        return angle < 0 ? angle + 360 : angle
    }
    
    let pow25To7 : Double = pow(25.0, 7.0)
    
    let cBar : Double = (hypot(first.a, first.b) + hypot(second.a, second.b)) / 2
    let cBar7 : Double = pow(cBar, 7.0)
    let g : Double = 0.5 * (1 - sqrt(cBar7 / (cBar7 + pow25To7)))
    
    let a1 : Double = (1 + g) * first.a
    let a2 : Double = (1 + g) * second.a
    let c1 : Double = hypot(a1, first.b)
    let c2 : Double = hypot(a2, second.b)
    let h1 : Double = hue(first.b, a1)
    let h2 : Double = hue(second.b, a2)
    
    let deltaL : Double = second.l - first.l
    let deltaC : Double = c2 - c1
    
    var deltaHue : Double = 0
    if c1 * c2 != 0 {
        deltaHue = h2 - h1
        if deltaHue > 180 { deltaHue -= 360 } else if deltaHue < -180 { deltaHue += 360 }
    }
    let deltaH : Double = 2 * sqrt(c1 * c2) * sin(radians(deltaHue / 2))
    
    let lMean : Double = (first.l + second.l) / 2
    let cMean : Double = (c1 + c2) / 2
    
    var hMean : Double = h1 + h2
    if c1 * c2 != 0 {
        if abs(h1 - h2) <= 180 {
            hMean = (h1 + h2) / 2
        } else if h1 + h2 < 360 {
            hMean = (h1 + h2 + 360) / 2
        } else {
            hMean = (h1 + h2 - 360) / 2
        }
    }
    
    let t1 : Double = 0.17 * cos(radians(hMean - 30))
    let t2 : Double = 0.24 * cos(radians(2 * hMean))
    let t3 : Double = 0.32 * cos(radians(3 * hMean + 6))
    let t4 : Double = 0.20 * cos(radians(4 * hMean - 63))
    let t : Double = 1 - t1 + t2 + t3 - t4
    
    let hueOffset : Double = (hMean - 275) / 25
    let deltaTheta : Double = 30 * exp(-(hueOffset * hueOffset))
    let cMean7 : Double = pow(cMean, 7.0)
    let rC : Double = 2 * sqrt(cMean7 / (cMean7 + pow25To7))
    let lOffset : Double = (lMean - 50) * (lMean - 50)
    let sL : Double = 1 + 0.015 * lOffset / sqrt(20 + lOffset)
    let sC : Double = 1 + 0.045 * cMean
    let sH : Double = 1 + 0.015 * cMean * t
    let rT : Double = -sin(radians(2 * deltaTheta)) * rC
    
    let l : Double = deltaL / sL
    let c : Double = deltaC / sC
    let h : Double = deltaH / sH
    let sum : Double = l * l + c * c + h * h + rT * c * h
    
    return sqrt(sum)
}

#if canImport(UIKit)
import UIKit

extension ColorNaming {
    static func closestName(to color: UIColor) -> String? {
        var red : CGFloat = 0, green : CGFloat = 0, blue : CGFloat = 0, alpha : CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        
        return closestName(red: red, green: green, blue: blue)
    }
}
#endif
