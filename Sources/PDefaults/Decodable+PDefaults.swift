//
//  Decodable+PDefaults.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

/// Decodable related errors
enum DecodableError: Error {
    /// Error thrown when either the stored object is nil, or cannot be cast to data
    case cannotCastStoredObjectAsData(Any?)
}

extension Decodable {
    /// `Decodable` mapping for reading from storage
    static func decodableReadMapper(_ object: Any) throws -> Self {
        guard let data = object as? Data else {
            throw DecodableError.cannotCastStoredObjectAsData(object)
        }
        return try JSONDecoder().decode(self, from: data)
    }
}
