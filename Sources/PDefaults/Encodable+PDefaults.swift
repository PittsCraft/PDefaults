//
//  Encodable+PDefaults.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

/// Encodable related errors
enum EncodableError: Error {
    /// Error thrown when the value to encode is nil
    case cannotEncodeNil
}

extension Encodable {
    /// `Encodable` mapping for storage
    static func codableWriteMapper(_ value: Self) throws -> Any {
        if let optValue = value as? OptionalType, optValue.isNil() {
            throw EncodableError.cannotEncodeNil
        }
        return try JSONEncoder().encode(value)
    }
}
