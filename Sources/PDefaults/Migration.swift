//
//  Migration.swift
//  
//
//  Created by Pierre Mardon on 30/06/2023.
//

import Foundation

/// Type providing closures to perform a migration
public struct Migration<Value> {
    /// Whether the migration should be performed or not
    public let shouldPerform: () -> Bool
    /// Getter for the value to migrate, called once per migration
    public let value: () -> Value
    /// Called after a migration was performed. Some cleanup or flagging can be performed here.
    public var onDone: () -> Void = {}

    /// Initializer
    ///
    /// - parameters:
    ///    - shouldPerform: whether the migration should be performed or not
    ///    - value: getter for the value to migrate, called once per migration
    ///    - onDone:called after a migration was performed. Some cleanup or flagging can be performed here.
    public init(shouldPerform: @escaping () -> Bool,
                value: @escaping () -> Value,
                onDone: @escaping () -> Void) {
        self.shouldPerform = shouldPerform
        self.value = value
        self.onDone = onDone
    }

    /// Create a migration from an `PDefaults` instance
    ///
    /// - parameters:
    ///    - pDefaults: the source `PDefaults` instance
    ///    - mapping: a closure mapping the source to the new value. Defaults to identity
    static func from<OldValue>(
        _ pDefaults: PDefaults<OldValue>,
        _ mapping: @escaping (OldValue) -> Value = { (value: Value) in value }
    ) -> Migration {
        Migration(shouldPerform: pDefaults.hasStoredValue,
                  value: { mapping(pDefaults.wrappedValue) },
                  onDone: pDefaults.reset)
    }
}
