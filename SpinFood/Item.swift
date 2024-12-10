//
//  Item.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
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
