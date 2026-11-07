import XCTest
@testable import Hatsuden

final class PileWheelSizesTests: XCTestCase {
    func testAllTwoHundredWheelSizesIncreaseWithoutAbruptFinalJump() {
        let wheels = PileWheelSizes(names: AnimalCatalog.names)
        XCTAssertEqual(wheels.diameters.count, 200)
        XCTAssertEqual(wheels[0], 64)
        for index in 1..<wheels.diameters.count {
            XCTAssertTrue(wheels[index].isFinite)
            XCTAssertGreaterThan(wheels[index], wheels[index - 1])
            XCTAssertLessThanOrEqual(wheels[index] / wheels[index - 1], 3.000_001)
        }
        XCTAssertGreaterThan(wheels[199] / wheels[0], 1_000)
        XCTAssertEqual(AnimalCatalog.sizeByName["銀河発電竜"], 1_000_000)
    }

    func testMigratedOrderKeepsItsStarterAndStillIncreases() {
        let wheels = PileWheelSizes(names: ["ハムスター", "ネコ", "ミツバチ", "銀河発電竜"])
        XCTAssertEqual(wheels[0], 64)
        XCTAssertGreaterThan(wheels[1], wheels[0])
        XCTAssertGreaterThan(wheels[2], wheels[1])
        XCTAssertGreaterThan(wheels[3], wheels[2])
        XCTAssertEqual(AnimalCatalog.sizeByName["ミツバチ"], 1.25)
    }

    func testUnknownSpeciesHasStablePositiveGeometry() {
        let wheels = PileWheelSizes(names: ["new starter", "new animal", "new animal 2"], starterDiameter: .nan)
        XCTAssertEqual(wheels[0], 64)
        XCTAssertGreaterThan(wheels[1], wheels[0])
        XCTAssertGreaterThan(wheels[2], wheels[1])
        XCTAssertEqual(PileWheelSizes(names: [])[0], 64)
    }
}
