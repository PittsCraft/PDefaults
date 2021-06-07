import XCTest
import PDefaults

class TestStorage: XCTestCase {

    let key = "mickey"
    let storage = UserDefaults.standard

    override func setUp() {
        super.setUp()
        storage.removeObject(forKey: key)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNoStorageWhenNotNeeded() {
        let pDefaults = PDefaults(wrappedValue: Optional.some(1), key, storage: storage)
        XCTAssert(storage.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        _ = pDefaults.wrappedValue
        XCTAssert(storage.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        _ = pDefaults.projectedValue
        XCTAssert(storage.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        pDefaults.wrappedValue = nil
        XCTAssert(storage.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
        pDefaults.wrappedValue = 1
        pDefaults.wrappedValue = nil
        XCTAssert(storage.object(forKey: key) == nil, "Storage should not contain a value for key \"\(key)\"")
    }

    func testStorageValueInt() {
        let pDefaults = PDefaults(wrappedValue: 1, key, storage: storage)
        pDefaults.wrappedValue = 2
        XCTAssert(storage.object(forKey: key) as? Int == 2, "Storage contain the value set to wrappedValue")
        XCTAssert(pDefaults.wrappedValue == 2, "Wrapped value should expose the set value")
    }

    struct CodableStruct: Codable, Equatable {
        let string: String
    }

    func testCodableStorageDefaultValueNoImpact() {
        // Storage: nil
        let pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, storage: storage)
        let codable = CodableStruct(string: "youpi")
        pDefaults.wrappedValue = codable
        // Storage: codable
        let otherCodable = CodableStruct(string: "hello")
        let pDefaults2 = PDefaults<CodableStruct>(wrappedValue: otherCodable, key, storage: storage)
        XCTAssert(pDefaults2.wrappedValue == codable, "Wrapped value should be equal to the value stored using the same key")
    }

    func testCodableStorageNilDefaultValueNoImpact() {
        // Storage: nil
        var pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, storage: storage)
        let codable = CodableStruct(string: "youpi")
        let otherCodable = CodableStruct(string: "hello")
        let pDefaults2 = PDefaults<CodableStruct>(wrappedValue: codable, key, storage: storage)
        pDefaults2.wrappedValue = otherCodable
        // Storage: otherCodable
        pDefaults = PDefaults<CodableStruct?>(wrappedValue: nil, key, storage: storage)
        XCTAssert(pDefaults.wrappedValue == otherCodable, "Wrapped value should be equal to the value stored using the same key")
    }
}
