//
//  PDefaults.swift
//
//  Created by Pierre Mardon on 01/01/1970. Trust me.
//
import Foundation
import Combine

/// Functions to map values before storing them
private typealias WriteMapper<Value> = (Value) throws -> Any
/// Functions to map values read from storage to an expected type
private typealias ReadMapper<Value> = (Any) throws -> Value

@propertyWrapper
/// A property wrapper for efficient and type safe `UserDefaults` storage and publication
/// using an underlying `CurrentValueSubject`
public class PDefaults<Value>: NSObject {

    /// Behavior to publish before or after the wrapped value change
    public enum PublishingBehavior {
        case didSet
        case willSet
    }

    /// The default value
    private let defaultValue: Value

    /// The value holder
    private var valueHolder: Value?

    /// The subject holder
    private var subjectHolder: CurrentValueSubject<Value, Never>?

    /// The key in the user‘s defaults suite
    private let key: String

    /// The user's defaults suite
    private let suite: UserDefaults

    /// The publishing behavior
    private let behavior: PublishingBehavior

    /// Mapper to transform the value before storing in user defaults
    private let writeMapper: WriteMapper<Value>

    /// Mapper to transform the object stored in user defaults to a value
    private let readMapper: ReadMapper<Value>

    /// The subject
    private var subject: CurrentValueSubject<Value, Never> {
        switch subjectHolder {
        case .none:
            let subject = CurrentValueSubject<Value, Never>(value)
            subjectHolder = subject
            return subject
        case .some(let subject):
            return subject
        }
    }

    /// The value
    private var value: Value {
        switch valueHolder {
        case .none:
            let value = loadValue()
            valueHolder = value
            return value
        case .some(let value):
            return value
        }
    }

    /// Flag indicating there's a storage operation in progress and KVO notifications should be ignored
    private var isStoring = false

    /// Designated initializer
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    ///    - writeMapper: function to map values before storing them
    ///    - readMapper:functions to map values read from storage to an expected type
    private init(wrappedValue defaultValue: Value,
                 _ key: String,
                 suite: UserDefaults,
                 behavior: PublishingBehavior,
                 writeMapper: @escaping WriteMapper<Value>,
                 readMapper: @escaping ReadMapper<Value>) {
        self.defaultValue = defaultValue
        self.key = key
        self.suite = suite
        self.behavior = behavior
        self.writeMapper = writeMapper
        self.readMapper = readMapper
        super.init()
        suite.addObserver(self, forKeyPath: key, options: .new, context: nil)
    }

    /// Deinit
    deinit {
        suite.removeObserver(self, forKeyPath: key)
    }

    /// Initializer
    ///
    /// For non-optional UserDefault's natively compatible types
    ///
    /// - parameters:
    ///    - defaultValue: default value of the property
    ///    - key: key in UserDefaults suite
    ///    - suite: UserDefault's suite
    ///    - behavior: behavior to publish before or after the wrapped value change
    public convenience init(wrappedValue defaultValue: Value,
                            _ key: String,
                            suite: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: UserDefaultsStorable {
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
    public convenience init<T>(
        wrappedValue defaultValue: Value,
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .willSet
    ) where Value == T?, T: UserDefaultsStorable {
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
    public convenience init<T>(
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .willSet
    ) where Value == T?, T: UserDefaultsStorable {
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
    public convenience init(wrappedValue defaultValue: Value,
                            _ key: String,
                            suite: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: Codable {
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
    public convenience init<T>(_ key: String,
                               suite: UserDefaults = .standard,
                               behavior: PublishingBehavior = .willSet) where Value == T?, T: Codable {
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
    public convenience init(wrappedValue defaultValue: Value,
                            _ key: String,
                            suite: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: Codable & UserDefaultsStorable {
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
    public convenience init<T>(
        _ key: String,
        suite: UserDefaults = .standard,
        behavior: PublishingBehavior = .willSet
    ) where Value == T?, T: Codable & UserDefaultsStorable {
        self.init(wrappedValue: nil,
                  key,
                  suite: suite,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    @available(*, unavailable, message: "You can use PDefaults only types that either conform to Codable or are natively handled by UserDefaults")
    // swiftlint:disable:previous line_length
    /// Constructor catching all type errors to expose compatibility constraints message
    public convenience init(_ key: String,
                            suite: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) {
        fatalError()
    }

    @available(*, unavailable, message: "You can use PDefaults only types that either conform to Codable or are natively handled by UserDefaults")
    // swiftlint:disable:previous line_length
    /// Constructor catching all type errors to expose compatibility constraints message
    public convenience init<T>(wrappedValue defaultValue: T,
                               _ key: String,
                               suite: UserDefaults = .standard,
                               behavior: PublishingBehavior = .willSet) {
        fatalError()
    }

    /// Read the suite's stored value and falls back to the default value if the suite entry doesn't exist or is invalid
    ///  - returns the stored value or the default one
    private func loadValue() -> Value {
        if let object = suite.object(forKey: key) {
            do {
                return try readMapper(object)
            } catch {}
        }
        return defaultValue
    }

    /// Store the value in suite
    /// - parameters:
    ///    - value: the value to store
    private func store(value: Value) {
        // Flag to avoid KVO to potentially decode a raw value while can expose it here directly
        isStoring = true
        var exposedValue = value
        do {
            let storedValue = try writeMapper(value)
            suite.set(storedValue, forKey: key)
        } catch {
            suite.removeObject(forKey: key)
            exposedValue = defaultValue
        }
        isStoring = false
        expose(value: exposedValue)
    }

    /// Expose a value to wrappedValue and send it through the publisher in the order defined by `behavior`
    /// - parameters:
    ///    - value: the value to expose
    private func expose(value: Value) {
        switch behavior {
        case .didSet:
            valueHolder = value
            subjectHolder?.send(value)
        case .willSet:
            subjectHolder?.send(value)
            valueHolder = value
        }
    }

    /// Read the value contained in a KVO change dictionary, falls back to the default value
    ///
    ///  - parameters:
    ///     - change: KVO change dictionary
    ///  - returns the value matching the KVO change
    private func valueFor(change: [NSKeyValueChangeKey: Any]?) -> Value {
        if let rawValue = change?[.newKey] {
            do {
                return try readMapper(rawValue)
            } catch {}
        }
        return defaultValue
    }

    // swiftlint:disable:next block_based_kvo
    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard !isStoring, keyPath == key, object as? UserDefaults == suite else {
            return
        }
        let value = valueFor(change: change)
        expose(value: value)
    }

    /// Property wrapper's wrapped value
    public var wrappedValue: Value {
        get { value }
        set { store(value: newValue) }
    }

    /// Property wrapper's projected value
    public lazy var projectedValue: AnyPublisher<Value, Never> = { subject.eraseToAnyPublisher() }()
}
