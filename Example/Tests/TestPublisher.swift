import XCTest
import PDefaults

class TestPublisher: XCTestCase {

    let key = "mickey"
    let storage = UserDefaults.standard

    override func setUp() {
        super.setUp()
        storage.removeObject(forKey: key)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testClosureCalledOnSink() {
        let pdefaults = PDefaults(wrappedValue: 1, key, storage: storage)
        var called = false
        let cancellable = pdefaults.projectedValue.sink { _ in
            called = true
        }
        XCTAssert(called, "Sink closure is expected to be called on subscription")
        cancellable.cancel()
    }

    func testNotPresentingValueWhilePublishing() {
        let initValue = 1
        let pdefaults = PDefaults(wrappedValue: initValue, key, storage: storage)
        let cancellable = pdefaults.projectedValue.sink { _ in
            XCTAssert(pdefaults.wrappedValue == initValue, "While sinking, the directly accessed value should be the previous one")
        }
        pdefaults.wrappedValue = 2
        cancellable.cancel()
    }

    func testPresentingValueWhilePublishing() {
        let newValue = 2
        let pdefaults = PDefaults(wrappedValue: 1, key, storage: storage, behavior: .didSet)
        var isFirstReceive = true
        let cancellable = pdefaults.projectedValue.sink { _ in
            if !isFirstReceive {
                XCTAssert(pdefaults.wrappedValue == newValue, "While sinking, the directly accessed value should be the previous one")
            }
            isFirstReceive = false
        }
        pdefaults.wrappedValue = 2
        cancellable.cancel()
    }

    func testSinkRightValue() {
        var lastValue = 1
        let pdefaults = PDefaults(wrappedValue: lastValue, key, storage: storage)
        let cancellable = pdefaults.projectedValue.sink { value in
            XCTAssert(value == lastValue, "While sinking, the directly accessed value should be the previous one")
        }
        lastValue = 2
        pdefaults.wrappedValue = lastValue
        cancellable.cancel()
    }
}
