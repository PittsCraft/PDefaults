//
//  OptionalType.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

/// Protocol for Optional types only, adding a `isNil()` func to them
protocol OptionalType {
    /// Returns nil if the value or the recursively wrapped value is `Optional.none` aka `nil`
    func isNil() -> Bool
}

/// Making Optional types implement our recursive `nil` check protocol
extension Optional: OptionalType {
    func isNil() -> Bool {
        if self == nil {
            return true
        }
        let unwrapped = unsafelyUnwrapped
        if unwrapped is OptionalType {
            return (unwrapped as! OptionalType).isNil()
        }
        return false
    }
}
