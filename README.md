# PDefaults

Provides concise [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) storage with Combine publishing capability.

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

## Migration

You can easily migrate between `PDefaults` instances

```swift
let appGroupSuite = UserDefaults(suiteName: "com.company.appgroup")!

class Service {
    @PDefaults("user.name") private var legacyName = "Pitt"
    @PDefaults("user.first-name", suite: appGroupSuite) var name = "Pete"

    init() {
        _legacyName.migrate(to: _name)
    }
}
```

The migration will be performed only if there's indeed a stored value in the source `PDefaults`.
Once the migration is performed, the source `PDefaults` is reset, removing its stored value, and guaranteeing that
the migration won't be performed again.

You can add a mapping to convert your source value:

```swift
let appGroupSuite = UserDefaults(suiteName: "com.company.appgroup")!

class Service {
    @PDefaults("count") private var legacyCount = Double(1)
    @PDefaults("index", suite: appGroupSuite) var index = 0

    init() {
        _legacyCount.migrate(to: _index, { Int($0) - 1 })
    }
}
```

## Mock

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

## How to expose through a protocol

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

## Extra features and detailed behaviors

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

### Default `CurrentValueSubject` like behavior

`PDefaults` behaves like `CurrentValueSubject` by default.

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
Published: François - Property: François
Published: Hubert - Property: Hubert
```

### `@Published` like behavior

You can make `PDefaults` behave like `@Published` by setting the `behavior` parameter to `.willSet`.
It will then publishing any new value before exposing it as its wrapped value.

```swift
@PDefaults("user.name", behavior: .willSet)
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

## Requirements

iOS 13.0+, macOS 12+

## Installation

PDefaults is available via [Swift Package Manager](https://www.swift.org/package-manager/) using this repository URL.

## Author

[Pierre Mardon](mailto:pierre@pittscraft.com)

## License

PDefaults is available under the MIT license. See the LICENSE file for more info.
