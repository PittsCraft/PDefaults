import XCTest
import PDefaults

class TestStorage: XCTestCase {

    let key = "mickey"
    let suite = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suite.removeObject(forKey: key)
    }

    override func tearDown() {
        super.tearDown()
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
}
