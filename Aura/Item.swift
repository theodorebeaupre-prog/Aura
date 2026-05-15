//
//  Item.swift
//  Aura
//
//  Created by Theodore Beaupre on 2026-05-14.
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
