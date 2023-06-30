//
//  UserDefaultsStorable.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

/// Flag protocol: any type implementing this protocol can be stored natively using UserDefaults
public protocol UserDefaultsStorable {}

/**
 Declare proper flag protocol conformance for all types natively compatible with UserDefaults storage
 */

extension String: UserDefaultsStorable {}
extension Int: UserDefaultsStorable {}
extension Double: UserDefaultsStorable {}
extension Float: UserDefaultsStorable {}
extension Date: UserDefaultsStorable {}
extension Data: UserDefaultsStorable {}
extension Array: UserDefaultsStorable where Element: UserDefaultsStorable {}
extension Dictionary: UserDefaultsStorable where Key == String, Value: UserDefaultsStorable {}
extension Optional: UserDefaultsStorable where Wrapped: UserDefaultsStorable {}

/// Errors related to `UserDefaultStorable` types
enum UserDefaultsStorableError: Error {
    /// Stored object could not be cast to the expected type
    case cannotCastToType(Any.Type)
    /// Value is nil and cannot be mapped for storage
    case cannotStoreNil
}

extension UserDefaultsStorable {

    /// `UserDefaultsStorable` mapping for storage
    static func writeMapper(_ value: Self) throws -> Any {
        if let optValue = value as? OptionalType, optValue.isNil() {
            throw UserDefaultsStorableError.cannotStoreNil
        }
        return value
    }

    /// `UserDefaultsStorable` mapping for reading from storage
    static func readMapper(_ object: Any) throws -> Self {
        if let value = object as? Self {
            return value
        }
        throw UserDefaultsStorableError.cannotCastToType(Self.self)
    }
}
