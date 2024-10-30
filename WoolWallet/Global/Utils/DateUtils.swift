//
//  DateUtils.swift
//  WoolWallet
//
//  Created by Mac on 10/30/24.
//

import Foundation
import CoreData

class DateUtils {
    static let shared = DateUtils()
    
    private init() {}
    
    func formatDate(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium // You can adjust this
//        dateFormatter.timeStyle = .short   // You can adjust this
        
        return dateFormatter.string(from: date)
    }

}
