# PDefaults

[![Version](https://img.shields.io/cocoapods/v/PDefaults.svg?style=flat)](https://cocoapods.org/pods/PDefaults)
[![License](https://img.shields.io/cocoapods/l/PDefaults.svg?style=flat)](https://cocoapods.org/pods/PDefaults)
[![Platform](https://img.shields.io/cocoapods/p/PDefaults.svg?style=flat)](https://cocoapods.org/pods/PDefaults)

Provides concises and SwiftUI friendly [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) storage with Combine publishing capability.

All regular `UserDefaults` compatible types and `Codable`types are supported (optional or not). 

## Use

```swift
class Service {
    @PDefaults("user.name")
    var name = "Pitt"
}

let service = Service()

let cancellable = service.$name.sink {
    print("Name: \($0)")
}

service.name = "François"

```
Prints:
```
Name: Pitt
Name: François
```
The value `"François"` is stored with key `"user.name"` in `UserDefaults.standard` and will be the value of the property `service.name` from now on even after killing the app. 

Store in another suite:

```swift

// Remember kids: heroes don't do force unwrap!
let notStandardSuite = UserDefaults(suiteName: "notStandard")!

class Service {
    @PDefaults("user.name", storage: notStandardSuite)
    var name = "Pitt"
}
```

## Behavior

### Default value and `nil`

The initial value given to the property is the default value. The default value will be exposed until you set a non-nil value. When setting a nil value, the default value will be used.

```swift
class Service {
    @PDefaults("user.name")
    var name: String? = "Pitt"
}

let service = Service()

let cancellable = service.$name.sink {
    print("New name: \($0)")
} // Prints Pitt

service.name = "François" // Prints François
service.name = nil // Prints the default value: Pitt
```

To avoid confusion, it is recommended to set the default value to `nil` for optional types.

### `@Published` like behavior

`PDefaults` behaves as `@Published` by default.

```swift
class Service {
    @PDefaults("user.name")
    var name = "Pitt"
}

let service = Service()

let cancellable = service.$name.sink {
    print("Published: \($0) - Property: \(service.name)")
}

service.name = "François"
service.name = "Hubert"
```

Prints :

```
Published: Pitt - Property: Pitt
Published: François - Property: Pitt
Published: Hubert - Property: François
```

### `CurrentValueSubject` like behavior

But you can make it behave like `CurrentValueSubject` using the `behavior` parameter.

```swift
class Service {
    @PDefaults("user.name", behavior: .didSet)
    var name = "Pitt"
}

let service = Service()

let cancellable = service.$name.sink {
    print("Published: \($0) - Property: \(service.name)")
}

service.name = "François"
service.name = "Hubert"
```

Prints :

```
Published: Pitt - Property: Pitt
Published: François - Property: François
Published: Hubert - Property: Hubert
```

## Performance

Designed so that reading the value from `UserDefaults` is performed maximum once per property and app session. 
Thus there's no `UserDefaults` or decoding overhead when reading frequently. The counterpart is that the last read or written value is always in memory.

## How to expose the publisher through a protocol

There's currently no way to expose the publisher and the property in one line but you can still make it very concise and readable.

```swift

protocol ServiceProtocol {
    var name: String { get set }
    var namePublisher: AnyPublisher<String, Never> { get }
}

class Service: ServiceProtocol {
    @PDefaults("user.name")
    var name: String = "Pitt"
    
    var namePublisher: AnyPublisher<String, Never> { $name }
}

```

## Requirements

iOS 13.0+

## Installation

PDefaults is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'PDefaults'
```

## Author

[Pierre Mardon](mailto:pierre@pittscraft.com)

## License

PDefaults is available under the MIT license. See the LICENSE file for more info.
