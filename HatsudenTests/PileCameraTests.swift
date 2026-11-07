import XCTest
@testable import Hatsuden

final class PileCameraTests: XCTestCase {
    private let viewport = CGSize(width: 320, height: 640)
    private let bounds = CGRect(x: -1_000, y: -500, width: 4_000, height: 8_000)

    func testPinchKeepsTheWorldUnderItsMidpoint() {
        var camera = PileCamera(worldBounds: bounds, viewport: viewport)
        camera.magnify(by: 4, at: CGPoint(x: 160, y: 320))
        let anchor = CGPoint(x: 205, y: 390)
        let before = camera.worldPoint(fromScreen: anchor)
        camera.magnify(by: 1.6, at: anchor)
        let after = camera.screenPoint(fromWorld: before)
        XCTAssertEqual(after.x, anchor.x, accuracy: 0.000_001)
        XCTAssertEqual(after.y, anchor.y, accuracy: 0.000_001)
    }

    func testMovingPinchMidpointAlsoPansThePicture() {
        var camera = PileCamera(worldBounds: bounds, viewport: viewport)
        camera.magnify(by: 4, at: CGPoint(x: 160, y: 320))
        let from = CGPoint(x: 150, y: 300)
        let to = CGPoint(x: 190, y: 345)
        let world = camera.worldPoint(fromScreen: from)
        camera.gesture(from: from, to: to, factor: 1.25)
        let screen = camera.screenPoint(fromWorld: world)
        XCTAssertEqual(screen.x, to.x, accuracy: 0.000_001)
        XCTAssertEqual(screen.y, to.y, accuracy: 0.000_001)
    }

    func testPanClampsToAllFourEdgesAndResetFitsWholeWorld() {
        var camera = PileCamera(worldBounds: bounds, viewport: viewport)
        camera.magnify(by: 10, at: CGPoint(x: 160, y: 320))
        camera.pan(by: CGPoint(x: 1_000_000, y: -1_000_000))
        XCTAssertEqual(camera.visibleWorldBounds.minX, bounds.minX, accuracy: 0.000_001)
        XCTAssertEqual(camera.visibleWorldBounds.maxY, bounds.maxY, accuracy: 0.000_001)
        camera.pan(by: CGPoint(x: -2_000_000, y: 2_000_000))
        XCTAssertEqual(camera.visibleWorldBounds.maxX, bounds.maxX, accuracy: 0.000_001)
        XCTAssertEqual(camera.visibleWorldBounds.minY, bounds.minY, accuracy: 0.000_001)
        camera.reset()
        XCTAssertTrue(camera.isOverview)
        XCTAssertTrue(camera.visibleWorldBounds.contains(bounds))
    }

    func testStarterCanStillFillViewAfterHugeExpansion() {
        var camera = PileCamera(worldBounds: CGRect(x: 0, y: 0, width: 64_000_000, height: 128_000_000),
                                viewport: viewport, smallestWheelDiameter: 64)
        for _ in 0..<30 {
            camera.magnify(by: 2, at: CGPoint(x: 180, y: 300))
        }
        XCTAssertEqual(camera.scale * 64, 320 * 0.72, accuracy: 0.000_001)
        XCTAssertEqual(camera.scale, camera.maximumScale)
        let previous = camera
        camera.magnify(by: .infinity, at: .zero)
        camera.pan(by: CGPoint(x: CGFloat.nan, y: 0))
        XCTAssertEqual(camera, previous)
    }

    func testBoundsExpansionPreservesCloseUpUntilOverviewRequested() {
        var camera = PileCamera(worldBounds: bounds, viewport: viewport)
        camera.magnify(by: 8, at: CGPoint(x: 160, y: 320))
        let before = camera
        camera.updateWorldBounds(CGRect(x: -2_000, y: -1_000, width: 8_000, height: 16_000))
        XCTAssertEqual(camera.center, before.center)
        XCTAssertEqual(camera.scale, before.scale)
        camera.updateWorldBounds(bounds, preserveView: false)
        XCTAssertTrue(camera.isOverview)
    }

    func testZoomOutAnimationUsesGeometricScaleAndEndsExactlyAtTarget() {
        var from = PileCamera(worldBounds: bounds, viewport: viewport)
        let to = from
        from.magnify(by: 16, at: CGPoint(x: 160, y: 320))
        let midpoint = from.interpolated(to: to, progress: 0.5)
        XCTAssertEqual(midpoint.scale, to.scale * 4, accuracy: 0.000_001)
        XCTAssertEqual(from.interpolated(to: to, progress: 1), to)
    }
}
