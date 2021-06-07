//
//  PDefaults.swift
//
//  Created by Pierre Mardon on 01/01/1970. Trust me.
//
import Foundation
import Combine

/// Protocol for Optional types only, adding a `isNil()` func to them
fileprivate protocol OptionalType {
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

/// We need functions to map values before storing them to user defaults
fileprivate typealias WriteMapper<Value> = (Value) -> Any?
/// We need functions to map values read from user defaults storage to an expected type
fileprivate typealias ReadMapper<Value> = (Any?) -> Value?

/// Any type implementing this protocol can be stored natively in UserDefaults
public protocol UserDefaultsStorable {}

/**
 Declare proper flag protocol conformance for all types natively compatible with UserDefaults storage
 */

extension String : UserDefaultsStorable {}
extension Int: UserDefaultsStorable {}
extension Double: UserDefaultsStorable {}
extension Float: UserDefaultsStorable {}
extension Date: UserDefaultsStorable {}
extension Data: UserDefaultsStorable {}
extension Array: UserDefaultsStorable where Element: UserDefaultsStorable {}
extension Dictionary: UserDefaultsStorable where Key == String, Value: UserDefaultsStorable {}
extension Optional: UserDefaultsStorable where Wrapped: UserDefaultsStorable {}

fileprivate extension Encodable {
    /// `Encodable` mapping for storage
    static func writeMapper(_ object: Self) -> Any? {
        if let optObject = self as? OptionalType, optObject.isNil() {
            return nil
        }
        do {
            return try JSONEncoder().encode(object)
        } catch {
            print("Couldn't encode \(object)", error)
            return nil
        }
    }
}

fileprivate extension Decodable {
    /// `Decodable` mapping for reading from storage
    static func readMapper(_ value: Any?) -> Self? {
        guard let data = value as? Data else { return nil }
        do {
            return try JSONDecoder().decode(self, from: data)
        } catch {
            print("Couldn't decode \(String(describing: value))", error)
            // Very opinionated choice to almost ignore thrown errors
            return nil
        }
    }
}


@propertyWrapper
/// A property wrapper for efficient and type safe `UserDefaults` storage and publication using an underlying `CurrentValueSubject`
public class PDefaults<Value> {

    /// Behavior to publish before or after the wrapped value change
    public enum PublishingBehavior {
        case didSet
        case willSet
    }

    /// Enum for laziest behavior. Must only go forward: `none` -> `subject`
    private enum SubjectHolder {
        /// There was no need for the subject yet
        case none
        /// The subject was already read
        case subject(CurrentValueSubject<Value, Never>)
    }

    /// The default value
    private let defaultValue: Value

    /// The value holder
    private var valueHolder: Value? = nil

    /// The subject holder
    private var subjectHolder: CurrentValueSubject<Value, Never>? = nil

    /// The key in the user‘s defaults database.
    private let key: String

    /// The user's defaults database
    private let storage: UserDefaults

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

    private init(wrappedValue value: Value,
                 _ key: String ,
                 storage: UserDefaults,
                 behavior: PublishingBehavior,
                 writeMapper: @escaping WriteMapper<Value>,
                 readMapper: @escaping ReadMapper<Value>) {
        defaultValue = value
        self.key = key
        self.storage = storage
        self.behavior = behavior
        self.writeMapper = writeMapper
        self.readMapper = readMapper
    }

    public convenience init(wrappedValue value: Value,
                            _ key: String,
                            storage: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: UserDefaultsStorable {
        self.init(wrappedValue: value,
                  key,
                  storage: storage,
                  behavior: behavior,
                  writeMapper: { $0 },
                  readMapper: { $0 as? Value})
    }

    public convenience init<T>(wrappedValue value: Value,
                            _ key: String,
                            storage: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value == Optional<T>, T: UserDefaultsStorable {
        self.init(wrappedValue: value,
                  key,
                  storage: storage,
                  behavior: behavior,
                  writeMapper: { $0 },
                  readMapper: { $0 as? Value})
    }

    public convenience init(wrappedValue value: Value,
                            _ key: String,
                            storage: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: Codable {
        self.init(wrappedValue: value,
                  key,
                  storage: storage,
                  behavior: behavior,
                  writeMapper: Value.writeMapper,
                  readMapper: Value.readMapper)
    }

    public convenience init(wrappedValue value: Value,
                            _ key: String,
                            storage: UserDefaults = .standard,
                            behavior: PublishingBehavior = .willSet) where Value: Codable & UserDefaultsStorable {
        self.init(wrappedValue: value,
                  key,
                  storage: storage,
                  behavior: behavior,
                  writeMapper: { $0 },
                  readMapper: { $0 as? Value})
    }

    /// Read the user defaults stored value
    private func storedValue() -> Value? {
        return readMapper(storage.object(forKey: key))
    }

    /// Store the value in user defaults and return the value to expose
    private func store(value: Value) -> Value {
        var exposedValue = value
        let storedValue = writeMapper(value)
        if storedValue.isNil() {
            UserDefaults.standard.removeObject(forKey: key)
            exposedValue = defaultValue
        } else {
            UserDefaults.standard.set(storedValue, forKey: key)
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

    public var wrappedValue: Value {
        set {
            let valueToExpose = store(value: newValue)
            expose(value: valueToExpose)
        }
        get { value }
    }

    public lazy var projectedValue: AnyPublisher<Value, Never> = { subject.eraseToAnyPublisher() }()
}

