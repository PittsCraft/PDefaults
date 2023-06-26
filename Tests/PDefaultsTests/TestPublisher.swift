import XCTest
import PDefaults

class TestPublisher: XCTestCase {

    let key = "mickey"
    let suite = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suite.removeObject(forKey: key)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testClosureCalledOnSink() {
        let pdefaults = PDefaults(wrappedValue: 1, key, suite: suite)
        var called = false
        let cancellable = pdefaults.projectedValue.sink { _ in
            called = true
        }
        XCTAssert(called, "Sink closure is expected to be called on subscription")
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
        var isFirstReceive = true
        let cancellable = pdefaults.projectedValue.sink { _ in
            if !isFirstReceive {
                XCTAssert(pdefaults.wrappedValue == newValue,
                          "While sinking, the directly accessed value should be the current one")
            }
            isFirstReceive = false
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

    func testTwoPDefaultsSameValueAfterChange() {
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        pdefaults1.wrappedValue = "hello"
        XCTAssert(pdefaults2.wrappedValue == pdefaults1.wrappedValue)
    }

    func testTwoPDefaultsSameValueAfterLoadingThenChange() {
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        _ = pdefaults2.wrappedValue
        pdefaults1.wrappedValue = "hello"
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
                          "Second PDefaults should send proper value through its publisher when first one's value is"
                          + " updated")
            }
        pdefaults1.wrappedValue = nil
        cancellable.cancel()
    }
}
