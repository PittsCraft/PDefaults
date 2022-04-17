//
//  PDefaults.swift
//
//  Created by Pierre Mardon on 01/01/1970. Trust me.
//
import Foundation
import Combine

/// Functions to map values before storing them
fileprivate typealias WriteMapper<Value> = (Value) -> Any?
/// Functions to map values read from storage to an expected type
fileprivate typealias ReadMapper<Value> = (Any?) -> Value?


@propertyWrapper
/// A property wrapper for efficient and type safe `UserDefaults` storage and publication using an underlying `CurrentValueSubject`
public class PDefaults<Value> {

    /// Behavior to publish before or after the wrapped value change
    public enum PublishingBehavior {
        case didSet
        case willSet
    }

    /// The default value
    private let defaultValue: Value

    /// The value holder
    private var valueHolder: Value? = nil

    /// The subject holder
    private var subjectHolder: CurrentValueSubject<Value, Never>? = nil

    /// The key in the user‘s defaults suite
    private let key: String

    /// The user's defaults suite
    private let suite: UserDefaults

    /// The publishing behavior
    private let behavior: PublishingBehavior

    /// Mapper to transform the value before storing in user defaults
    private let writeMapper: (Value) -> Any?

    /// Mapper to transform the object stored in user defaults to a value
    private let readMapper: (Any?) -> Value?

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
            let value = storedValue() ?? defaultValue
            valueHolder = value
            return value
        case .some(let value):
            return value
        }
    }

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
                 _ key: String ,
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
    public convenience init<T>(wrappedValue defaultValue: Value,
                               _ key: String,
                               suite: UserDefaults = .standard,
                               behavior: PublishingBehavior = .willSet) where Value == Optional<T>, T: UserDefaultsStorable {
        self.init(wrappedValue: defaultValue,
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

    /// Read the suite's stored value
    private func storedValue() -> Value? {
        return readMapper(suite.object(forKey: key))
    }

    /// Store the value in suite and return the value to expose
    private func store(value: Value) -> Value {
        var exposedValue = value
        let storedValue = writeMapper(value)
        if storedValue.isNil() {
            suite.removeObject(forKey: key)
            exposedValue = defaultValue
        } else {
            suite.set(storedValue, forKey: key)
        }
        return exposedValue
    }

    /// Expose the value in the wrapped value and through the subject if any
    private func expose(value: Value) {
        switch behavior {
        case .didSet:
            valueHolder = value
        case .willSet:
            break
        }
        if let subject = subjectHolder {
            subject.send(value)
        }
        switch behavior {
        case .didSet:
            break
        case .willSet:
            valueHolder = value
        }
    }

    /// Property wrapper's wrapped value
    public var wrappedValue: Value {
        set {
            let valueToExpose = store(value: newValue)
            expose(value: valueToExpose)
        }
        get { value }
    }

    /// Property wrapper's projected value
    public lazy var projectedValue: AnyPublisher<Value, Never> = { subject.eraseToAnyPublisher() }()
}
