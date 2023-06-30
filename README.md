# PDefaults

Provides concise and SwiftUI friendly [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) storage with Combine publishing capability.

All regular `UserDefaults` compatible types and `Codable`types are supported (optional or not). 

## Use

```swift
@PDefaults("user.name")
var name = "Pitt"

let cancellable = $name.sink {
    print("Name: \($0)")
}

name = "François"

```
Prints:
```
Name: Pitt
Name: François
```
The value `"François"` is stored with key `"user.name"` in `UserDefaults.standard` and will be the value of the property `name` from now on even after killing the app. 

Store in another suite:

```swift

// Remember kids: heroes don't do force unwrap!
let appGroupSuite = UserDefaults(suiteName: "com.company.appgroup")!

@PDefaults("user.name", storage: appGroupSuite)
var name = "Pitt"
```

## Behavior

### Default value and `nil`

> To avoid confusion, it is recommended to set the default value to `nil` for optional types.

The initial value given to the property is the default value. The default value will be exposed until you set a non-nil value. When setting a nil value, the default value will be used.

```swift
@PDefaults("user.name")
var name: String? = "Pitt"

let cancellable = $name.sink {
    print("New name: \($0)")
} // Prints Pitt

name = "François" // Prints François
name = nil // Prints the default value: Pitt
```

### `@Published` like behavior

`PDefaults` behaves as `@Published` by default: it publishes any new value before exposing it as its wrapped value.

```swift
@PDefaults("user.name")
var name = "Pitt"

let cancellable = $name.sink {
    print("Published: \($0) - Property: \(name)")
}

name = "François"
name = "Hubert"
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
@PDefaults("user.name", behavior: .didSet)
var name = "Pitt"

let cancellable = $name.sink {
    print("Published: \($0) - Property: \(name)")
}

name = "François"
name = "Hubert"
```

Prints :

```
Published: Pitt - Property: Pitt
Published: François - Property: François
Published: Hubert - Property: Hubert
```

### App group sharing

Apps of the same app group can share preferences through `UserDefaults` using suites named after the app group
 identifier.
  
`PDefaults` plays well with this. If you change the stored value in one app and if any of the other apps in the group is 
running and has a `PDefaults` instance on the right key, its publisher will be triggered with the new value. 

In app A:

```swift
// Remember kids: heroes don't do force unwrap!
let appGroupSuite = UserDefaults(suiteName: "com.company.appgroup")!

@PDefaults("user.name", suite: appGroupSuite)
var name = "Pitt"

let cancellable = name.sink {
    print("Published: \($0)")
}

```

In app B:

```swift
// Remember kids: heroes don't do force unwrap!
let appGroupSuite = UserDefaults(suiteName: "com.company.appgroup")!

@PDefaults("user.name", suite: appGroupSuite)
var name = "Pitt"

name = "François" 
```

Then app A prints:

```
Published: François
```

### Multiple instances

**It's an antipattern**. But if you still go with multiple instances:

```swift
@PDefaults("user.name", behavior: .didSet)
var name = "Pitt"

@PDefaults("user.name", behavior: .didSet)
var otherName = "Pitt"
```

Then everything will run smoothly. Value changes on one instance will trigger the other instance's publisher, 
and the wrapped values will be the same, still honoring each instance behavior __independently__.

Note that it introduces a small overhead as decoding will occur in both instances when necessary.

Also **it's an antipattern**, you can easily create infinite loops if one's publisher triggers the other's update.

### Mock

You can mock an instance by setting its `mock` property to `true`.

```swift
@PDefaults("user.name")
var name = "Pitt"

_name.mock = true
```

Then:
- the underlying suite will never be read or written
- the app group sharing will obviously not work

Note that the instance will ignore the stored value only if the mock flag is set before any access to the wrapped value
or the projected value.

You can also mock all instances using the global configuration `mock` property.

```swift
PDefaultsConfiguration.mock = true
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

iOS 13.0+, macOS 12+

## Installation

PDefaults is available via [Swift Package Manager](https://www.swift.org/package-manager/) using this repository URL.

## Author

[Pierre Mardon](mailto:pierre@pittscraft.com)

## License

PDefaults is available under the MIT license. See the LICENSE file for more info.
