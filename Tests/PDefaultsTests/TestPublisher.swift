import XCTest
import PDefaults

// swiftlint:disable missing_docs
class TestPublisher: XCTestCase {

    let key = "mickey"
    let suite = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suite.removeObject(forKey: key)
        PDefaultsConfiguration.mock = false
    }

    func testClosureCalledOnSink() {
        let pdefaults = PDefaults(wrappedValue: 1, key, suite: suite)
        let expectCalled = expectation(description: "PDefaults publisher sink closure is expected to be called on"
                                       + " subscription")
        let cancellable = pdefaults.projectedValue.sink { _ in
            expectCalled.fulfill()
        }
        waitForExpectations(timeout: 0)
        cancellable.cancel()
    }

    func testNotPresentingValueWhilePublishing() {
        let initValue = 1
        let pdefaults = PDefaults(wrappedValue: initValue, key, suite: suite, behavior: .willSet)
        let cancellable = pdefaults.projectedValue.sink { _ in
            XCTAssert(pdefaults.wrappedValue == initValue,
                      "While sinking, the directly accessed value should be the previous one")
        }
        pdefaults.wrappedValue = 2
        cancellable.cancel()
    }

    func testPresentingValueWhilePublishing() {
        let newValue = 2
        let pdefaults = PDefaults(wrappedValue: 1, key, suite: suite, behavior: .didSet)
        let cancellable = pdefaults.projectedValue
            .dropFirst()
            .sink { _ in
                XCTAssert(pdefaults.wrappedValue == newValue,
                          "While sinking, the directly accessed value should be the current one")
            }
        pdefaults.wrappedValue = 2
        cancellable.cancel()
    }

    func testSinkRightValue() {
        var lastValue = 1
        let pdefaults = PDefaults(wrappedValue: lastValue, key, suite: suite)
        let cancellable = pdefaults.projectedValue.sink { value in
            XCTAssert(value == lastValue, "While sinking, the directly accessed value should be the previous one")
        }
        lastValue = 2
        pdefaults.wrappedValue = lastValue
        cancellable.cancel()
    }

    func testSinkOnValueChange() {
        let pdefaults = PDefaults(wrappedValue: 1, key, suite: suite)
        var count = 0
        let cancellable = pdefaults.projectedValue.sink { _ in
            count += 1
        }
        pdefaults.wrappedValue = 1
        XCTAssert(count == 2, "Expected sinking to happen twice, but happened only \(count) time")
        cancellable.cancel()
    }

    func testOptionalSinkNotNil() {
        let pdefaults = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let cancellable = pdefaults.projectedValue.sink { value in
            XCTAssert(value != nil, "While sinking, we don't expect any nil value initially")
        }
        cancellable.cancel()
    }

    func testTwoPDefaultsSameValue() {
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        pdefaults1.wrappedValue = "hello"
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        XCTAssert(pdefaults2.wrappedValue == pdefaults1.wrappedValue)
    }

    func testTwoPDefaultsReactiveInitValue() {
        let newValue = "hello"
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        pdefaults1.wrappedValue = newValue
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let cancellable = pdefaults2
            .projectedValue
            .sink {
                XCTAssert($0 == newValue,
                          "Second PDefaults should send initial (stored) value through its publisher")
            }
        cancellable.cancel()
    }

    func testTwoPDefaultsReactiveValue() {
        let newValue = "hello"
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let cancellable = pdefaults2
            .projectedValue
            .dropFirst()
            .sink {
                XCTAssert($0 == newValue,
                          "Second PDefaults should send proper value through its publisher when first one's value is"
                          + " updated")
            }
        pdefaults1.wrappedValue = newValue
        cancellable.cancel()
    }

    func testTwoPDefaultsReactiveDefaultValue() {
        let defaultValue = "hallo"
        let pdefaults1 = PDefaults<String?>(wrappedValue: nil, key, suite: suite)
        pdefaults1.wrappedValue = "hello"
        let pdefaults2 = PDefaults<String>(wrappedValue: defaultValue, key, suite: suite)
        let cancellable = pdefaults2
            .projectedValue
            .dropFirst()
            .sink {
                XCTAssert($0 == defaultValue,
                          "Second PDefaults should send its default value through its publisher when first one's value"
                          + " is reset to nil")
            }
        pdefaults1.wrappedValue = nil
        cancellable.cancel()
    }

    func testLocallyMockedPublisher() {
        let defaultValue = "coucou"
        let pdefaults1 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        pdefaults1.wrappedValue = "hello"
        let pdefaults2 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        pdefaults2.mock = true
        let cancellable = pdefaults2
            .projectedValue
            .sink {
                XCTAssert($0 == defaultValue,
                          "When locally mocked, the stored value should be ignored")
            }
        cancellable.cancel()
    }

    func testGloballyMockedPublisher() {
        let defaultValue = "coucou"
        let pdefaults1 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        pdefaults1.wrappedValue = "hello"
        let pdefaults2 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        PDefaultsConfiguration.mock = true
        let cancellable = pdefaults2
            .projectedValue
            .sink {
                XCTAssert($0 == defaultValue,
                          "When globally mocked, the stored value should be ignored")
            }
        cancellable.cancel()
    }

    func testLocallyMockedValueChange() {
        let defaultValue = "coucou"
        let newValue = "hello"
        let pdefaults1 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        pdefaults2.mock = true
        pdefaults2.wrappedValue = newValue
        let cancellable = pdefaults1
            .projectedValue
            .sink {
                XCTAssert($0 == defaultValue,
                          "When locally mocked, the value change of an instance should not affect other ones")
            }
        let cancellable2 = pdefaults2
            .projectedValue
            .sink {
                XCTAssert($0 == newValue,
                          "When locally mocked, the value change should be published")
            }
        cancellable.cancel()
        cancellable2.cancel()
    }

    func testGloballyMockedValueChange() {
        let defaultValue = "coucou"
        let newValue = "hello"
        let pdefaults1 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: defaultValue, key, suite: suite)
        PDefaultsConfiguration.mock = true
        pdefaults2.wrappedValue = newValue
        let cancellable = pdefaults1
            .projectedValue
            .sink {
                XCTAssert($0 == defaultValue,
                          "When globally mocked, the value change of an instance should not affect other ones")
            }
        let cancellable2 = pdefaults2
            .projectedValue
            .sink {
                XCTAssert($0 == newValue,
                          "When globally mocked, the value change should be published")
            }
        cancellable.cancel()
        cancellable2.cancel()
    }
}
// swiftlint:enable missing_docs
