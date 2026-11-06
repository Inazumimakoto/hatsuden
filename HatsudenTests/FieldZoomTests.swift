import XCTest
@testable import Hatsuden

final class FieldZoomTests: XCTestCase {
    func testZoomLimitGrowsWithTheStaircase() {
        XCTAssertEqual(FieldZoom.overview.magnified(by: 1_000, highestOwned: 0), .overview)
        XCTAssertEqual(FieldZoom.overview.magnified(by: 1_000, highestOwned: 15).scale, 128)
        XCTAssertEqual(
            FieldZoom.overview.magnified(by: 1_000, highestOwned: 199).scale,
            pow(2, CGFloat(99))
        )
    }

    func testDeepZoomReturnsToOverviewAtAnEvenLogarithmicRate() {
        let zoom = FieldZoom.overview.magnified(by: 1_000, highestOwned: 199)
        let halfway = zoom.interpolatedToOverview(progress: 0.5)
        XCTAssertEqual(log2(halfway.scale), 49.5, accuracy: 0.001)
        XCTAssertEqual(zoom.interpolatedToOverview(progress: 1), .overview)
    }

    func testZoomOutStopsAtOverview() {
        let zoom = FieldZoom.overview.magnified(by: 2, highestOwned: 10)
        XCTAssertEqual(zoom.magnified(by: 0.01, highestOwned: 10), .overview)
        XCTAssertEqual(zoom.magnified(by: .nan, highestOwned: 10), zoom)
    }
}
