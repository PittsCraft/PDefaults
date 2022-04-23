//
//  Encodable+PDefaults.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

extension Encodable {
    /// `Encodable` mapping for storage
    static func codableWriteMapper(_ value: Self) -> Any? {
        if let optValue = self as? OptionalType, optValue.isNil() {
            return nil
        }
        do {
            return try JSONEncoder().encode(value)
        } catch {
            print("Couldn't encode \(value)", error)
            // Opinionated choice to almost ignore thrown errors
            return nil
        }
    }
}
