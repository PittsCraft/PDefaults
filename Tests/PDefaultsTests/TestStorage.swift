import XCTest
import PDefaults

// swiftlint:disable missing_docs
class TestStorage: XCTestCase {

    let key = "mickey"
    let suite = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suite.removeObject(forKey: key)
        PDefaultsConfiguration.mock = false
    }

    func testNoStorageWhenNotNeeded() {
        let pDefaults = PDefaults(wrappedValue: Optional.some(1), key, suite: suite)
        XCTAssert(suite.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        _ = pDefaults.wrappedValue
        XCTAssert(suite.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        _ = pDefaults.projectedValue
        XCTAssert(suite.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        pDefaults.wrappedValue = nil
        XCTAssert(suite.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        pDefaults.wrappedValue = 1
        pDefaults.wrappedValue = nil
        XCTAssert(suite.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
    }

    func testStorageValueInt() {
        let pDefaults = PDefaults(wrappedValue: 1, key, suite: suite)
        pDefaults.wrappedValue = 2
        XCTAssert(suite.object(forKey: key) as? Int == 2, "Storage contains the value set to wrappedValue")
        XCTAssert(pDefaults.wrappedValue == 2, "Wrapped value should expose the set value")
    }

    struct CodableStruct: Codable, Equatable {
        let string: String
    }

    func testCodableStorageDefaultValueNoImpact() {
        // Storage: nil
        let pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, suite: suite)
        let codable = CodableStruct(string: "youpi")
        pDefaults.wrappedValue = codable
        // Storage: codable
        let otherCodable = CodableStruct(string: "hello")
        let pDefaults2 = PDefaults<CodableStruct>(wrappedValue: otherCodable, key, suite: suite)
        XCTAssert(pDefaults2.wrappedValue == codable,
                  "Wrapped value should be equal to the value stored explicitly."
                  + " Default value of only-declared PDefaults instance should have no impact.")
    }

    func testCodableStorageNilDefaultValueNoImpact() {
        // Storage: nil
        var pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, suite: suite)
        let codable = CodableStruct(string: "youpi")
        let otherCodable = CodableStruct(string: "hello")
        let pDefaults2 = PDefaults<CodableStruct>(wrappedValue: codable, key, suite: suite)
        pDefaults2.wrappedValue = otherCodable
        // Storage: otherCodable
        pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, suite: suite)
        XCTAssert(pDefaults.wrappedValue == otherCodable,
                  "Wrapped value should be equal to the value stored explicitly."
                  + " Default value of only-declared PDefaults instance should have no impact.")
    }

    func testDistinctSuiteStorage() {
        let otherSuite = UserDefaults(suiteName: "dingo")!
        let pDefaults = PDefaults(wrappedValue: 1, key, suite: otherSuite)
        pDefaults.wrappedValue = 2
        XCTAssert(otherSuite.object(forKey: key) as? Int == 2,
                  "Distinct suite should contains the value set to wrappedValue")
        XCTAssert(pDefaults.wrappedValue == 2, "Wrapped value should expose the set value")
    }

    func testTwoPDefaultsSameValueAfterLoadingThenChange() {
        let pdefaults1 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        let pdefaults2 = PDefaults<String?>(wrappedValue: "coucou", key, suite: suite)
        _ = pdefaults2.wrappedValue
        pdefaults1.wrappedValue = "hello"
        XCTAssert(pdefaults2.wrappedValue == pdefaults1.wrappedValue)
    }

    func testNilStorageReturnsDefault() {
        let codable = CodableStruct(string: "youpi")
        let pDefaults = PDefaults<CodableStruct?>(wrappedValue: codable, key, suite: suite)
        pDefaults.wrappedValue = codable
        pDefaults.wrappedValue = nil
        XCTAssert(pDefaults.wrappedValue == codable,
                  "When setting an optional value to nil, PDefaults should return the default value")
    }

    func testTwoPDefaultsNilStorageReturnsDefault() {
        let codable = CodableStruct(string: "youpi")
        let otherCodable = CodableStruct(string: "hello")
        let pDefaults = PDefaults<CodableStruct?>(wrappedValue: codable, key, suite: suite)
        let pDefaults2 = PDefaults<CodableStruct?>(wrappedValue: otherCodable, key, suite: suite)
        pDefaults.wrappedValue = nil
        XCTAssert(pDefaults2.wrappedValue == otherCodable,
                  "When setting an optional value to nil, PDefaults should return the default value")
    }

    func testLocalMockNoStorageWriting() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        pDefaults.mock = true
        pDefaults.wrappedValue = 2
        XCTAssert(suite.object(forKey: key) == nil,
                  "Nothing should be stored to UserDefaults when a locally mocked PDefaults is set a wrapped value")
    }

    func testLocalMockNoStorageReading() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        pDefaults.mock = true
        suite.set(1, forKey: key)
        XCTAssert(pDefaults.wrappedValue == nil,
                  "PDefaults should not read anything from storage when globally mocked")
    }

    func testGlobalMockNoStorageWriting() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        PDefaultsConfiguration.mock = true
        pDefaults.wrappedValue = 2
        XCTAssert(suite.object(forKey: key) == nil,
                  "Nothing should be stored to UserDefaults when a globally mocked PDefaults is set a wrapped value")
    }

    func testGlobalMockNoStorageReading() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        PDefaultsConfiguration.mock = true
        suite.set(1, forKey: key)
        XCTAssert(pDefaults.wrappedValue == nil,
                  "PDefaults should not read anything from storage when globally mocked")
    }

    func testLocalMockWritingRightValue() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        pDefaults.mock = true
        pDefaults.wrappedValue = 2
        XCTAssert(pDefaults.wrappedValue == 2,
                  "When locally mocked, PDefaults should still hold the last value affected to it")
    }

    func testGlobalMockWritingRightValue() {
        let pDefaults = PDefaults<Int?>(wrappedValue: nil, key, suite: suite)
        PDefaultsConfiguration.mock = true
        pDefaults.wrappedValue = 2
        XCTAssert(pDefaults.wrappedValue == 2,
                  "When globally mocked, PDefaults should still hold the last value affected to it")
    }
}
// swiftlint:enable missing_docs
