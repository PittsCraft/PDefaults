import XCTest
import PDefaults

// swiftlint:disable missing_docs
class TestMigration: XCTestCase {

    let key = "mickey"
    let sourceKey = "bob"
    let otherKey = "bill"
    let suite = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suite.removeObject(forKey: key)
        suite.removeObject(forKey: sourceKey)
        suite.removeObject(forKey: otherKey)
        PDefaultsConfiguration.mock = false
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNominalMigration() {
        let value = 1
        let source = PDefaults<Int?>(wrappedValue: nil, sourceKey)
        source.wrappedValue = value
        let target = PDefaults<Int?>(wrappedValue: nil, key)
        source.migrate(to: target)
        XCTAssert(target.wrappedValue == value,
                  "After migrating, the target PDefaults instance should hold the right value")
    }

    func testMigrationNotAppliedWhenNoValue() {
        let value = 1
        var target = PDefaults<Int?>(wrappedValue: nil, key)
        target.wrappedValue = value
        let source = PDefaults<Int?>(wrappedValue: nil, sourceKey)
        target = PDefaults(wrappedValue: nil, key)
        source.migrate(to: target)
        XCTAssert(target.wrappedValue == value,
                  "Migration should not be applied when the source PDefault has no stored value")
    }

    func testMigrationMapping() {
        let value = 0
        let source = PDefaults<Int>(wrappedValue: 0, sourceKey)
        source.wrappedValue = value
        let target = PDefaults<Int>(wrappedValue: 0, key)
        source.migrate(to: target, { $0 + 1 })
        XCTAssert(target.wrappedValue == value + 1,
                  "After migrating, the target PDefaults value should be properly mapped")
    }

    func testMigrationExecutedOnlyOnce() {
        let value = 0
        let source = PDefaults<Int>(wrappedValue: 0, sourceKey)
        source.wrappedValue = value
        var target = PDefaults<Int>(wrappedValue: 0, key)
        source.migrate(to: target)
        target = PDefaults<Int>(wrappedValue: -1, otherKey)
        source.migrate(to: target)
        XCTAssert(target.wrappedValue == -1,
                  "Migration should not be executed if another one with the same source already was")
    }
}
// swiftlint:enable missing_docs
