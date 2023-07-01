//
//  PDefaults+Init.swift
//  
//
//  Created by Pierre Mardon on 30/06/2023.
//

import Foundation

/// PDefaults extension declaring all public convenience init
public extension PDefaults {
    /// Initializer
    ///
    /// For non-optional UserDefault's natively compatible types
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init(wrappedValue defaultValue: Value,
                     _ key: String,
                     suite: UserDefaults = .standard,
                     behavior: PublishingBehavior = .didSet) where Value: UserDefaultsStorable {
        self.init(wrappedValue: defaultValue,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    /// Initializer
    ///
    /// For optional UserDefault's natively compatible types
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init<T>(
        wrappedValue defaultValue: Value,
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .didSet) where Value == T?, T: UserDefaultsStorable {
        self.init(wrappedValue: defaultValue,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    /// Initializer
    ///
    /// For optional UserDefault's natively compatible types with implicit default value = `nil`
    ///
    /// - parameters:
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init<T>(
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .didSet) where Value == T?, T: UserDefaultsStorable {
        self.init(wrappedValue: nil,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    /// Initializer
    ///
    /// For `Codable` types
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init(wrappedValue defaultValue: Value,
                     _ key: String,
                     suite: UserDefaults = .standard,
                     behavior: PublishingBehavior = .didSet) where Value: Codable {
        self.init(wrappedValue: defaultValue,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.codableWriteMapper,
                  readMapper: Value.decodableReadMapper)
    }

    /// Initializer
    ///
    /// For optional `Codable` types with implicit default value = `nil`
    ///
    /// - parameters:
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init<T>(_ key: String,
                        suite: UserDefaults = .standard,
                        behavior: PublishingBehavior = .didSet) where Value == T?, T: Codable {
        self.init(wrappedValue: nil,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.codableWriteMapper,
                  readMapper: Value.decodableReadMapper)
    }

    /// Initializer
    ///
    /// Disambiguation initializer to choose native UserDefaults value mapping
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init(wrappedValue defaultValue: Value,
                     _ key: String,
                     suite: UserDefaults = .standard,
                     behavior: PublishingBehavior = .didSet) where Value: Codable & UserDefaultsStorable {
        self.init(wrappedValue: defaultValue,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    /// Initializer
    ///
    /// Disambiguation initializer to choose native UserDefaults value mapping for optional `Codable`
    /// and natively compatible type
    ///
    /// - parameters:
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    convenience init<T>(
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .didSet) where Value == T?, T: Codable & UserDefaultsStorable {
        self.init(wrappedValue: nil,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    /// Constructor catching all type errors to expose compatibility constraints message
    @available(*, unavailable, message: "You can use PDefaults only types that either conform to Codable or are natively handled by UserDefaults")
    // swiftlint:disable:previous line_length
    convenience init(_ key: String,
                     suite: UserDefaults = .standard,
                     behavior: PublishingBehavior = .didSet) {
        fatalError()
    }

    /// Constructor catching all type errors to expose compatibility constraints message
    @available(*, unavailable, message: "You can use PDefaults only types that either conform to Codable or are natively handled by UserDefaults")
    // swiftlint:disable:previous line_length
    convenience init<T>(wrappedValue defaultValue: T,
                        _ key: String,
                        suite: UserDefaults = .standard,
                        behavior: PublishingBehavior = .didSet) {
        fatalError()
    }
}
