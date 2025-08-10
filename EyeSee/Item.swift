//
//  Item.swift
//  EyeSee
//
//  Created by chii_magnus on 2025/8/10.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
