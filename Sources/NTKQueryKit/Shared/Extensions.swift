//
//  Extensions.swift
//
//
//  Created by Wiktor Szlegier on 11/03/2024.
//

import Foundation

public extension Equatable {
    func isEqualTo(_ rhs: Any) -> Bool {
        if let castRHS = rhs as? Self {
            return self == castRHS
        } else {
            return false
        }
    }
}

