import XCTest
@testable import Hatsuden

final class FieldZoomTests: XCTestCase {
    private let viewport = CGSize(width: 320, height: 640)

    func testPinchKeepsTheSameWorldPointBetweenTheFingers() {
        let worldAnchor = CGPoint(x: 140, y: 280)
        let zoom = FieldZoom.overview.magnified(by: 2, from: worldAnchor, to: worldAnchor, viewport: viewport)
        let destination = CGPoint(x: 150, y: 260)
        let adjusted = zoom.magnified(by: 1.5, from: zoom.point(worldAnchor), to: destination, viewport: viewport)

        XCTAssertEqual(adjusted.point(worldAnchor), destination)
        XCTAssertEqual(adjusted.point(CGPoint(x: 180, y: 240)), CGPoint(x: 270, y: 140))
    }

    func testPinchStopsAtTheViewportEdgesAndMaximumScale() {
        let upperRight = CGPoint(x: viewport.width, y: viewport.height)
        let zoom = FieldZoom.overview.magnified(by: 50, from: upperRight, to: .zero, viewport: viewport)

        XCTAssertEqual(zoom.scale, FieldZoom.maximumScale)
        XCTAssertEqual(zoom.point(upperRight), upperRight)
        XCTAssertEqual(
            zoom.magnified(by: 0.01, from: .zero, to: upperRight, viewport: viewport),
            .overview
        )
        XCTAssertEqual(zoom.magnified(by: .nan, from: .zero, to: upperRight, viewport: viewport), zoom)
    }

    func testResizePreservesNormalizedFraming() {
        let anchor = CGPoint(x: 80, y: 480)
        let zoom = FieldZoom.overview.magnified(by: 3, from: anchor, to: anchor, viewport: viewport)
        let resized = zoom.resized(from: viewport, to: CGSize(width: 640, height: 320))

        XCTAssertEqual(resized.scale, zoom.scale)
        XCTAssertEqual(resized.point(CGPoint(x: 160, y: 240)), CGPoint(x: 160, y: 240))
        XCTAssertEqual(resized.interpolatedToOverview(progress: 1), .overview)
    }
}
