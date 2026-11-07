import XCTest
@testable import Hatsuden

final class CanvasGeometryTests: XCTestCase {
    private let viewport = CGRect(x: 0, y: 0, width: 320, height: 600)

    func testEveryCanvasMotifHasOneFixedLocation() {
        let canvas = FieldCanvas()
        let motifs = canvas.marks.map(\.motif)
        XCTAssertEqual(motifs.count, Set(motifs).count)
        XCTAssertEqual(Set(motifs), Set(FieldMotif.allCases))
        for mark in canvas.marks {
            let frame = mark.frame(in: viewport.size, at: mark.depth)
            XCTAssertTrue(frame.intersects(viewport), "\(mark.motif) is outside its world view.")
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
        }
    }

    func testEachCanvasMarkMagnifiesAroundTheSameLowerRightCorner() {
        let canvas = FieldCanvas()
        for mark in canvas.marks {
            let overviewDepth = mark.depth + 1
            let original = mark.frame(in: viewport.size, at: overviewDepth)
            for zoom: CGFloat in [1.25, 2, 3.5] {
                let zoomed = mark.frame(in: viewport.size, at: overviewDepth - log2(Double(zoom)))
                XCTAssertEqual(zoomed.width, original.width * zoom, accuracy: 0.001)
                XCTAssertEqual(zoomed.height, original.height * zoom, accuracy: 0.001)
                XCTAssertEqual(zoomed.midX - viewport.maxX,
                               (original.midX - viewport.maxX) * zoom, accuracy: 0.001)
                XCTAssertEqual(zoomed.midY - viewport.minY,
                               (original.midY - viewport.minY) * zoom, accuracy: 0.001)
            }
        }
    }

    func testEveryCanvasSubjectAppearsOnceWithVariedPlacementAndNaturalCropping() {
        let canvas = FieldCanvas()
        XCTAssertEqual(Set(canvas.details.map(\.id)).count, canvas.details.count)
        XCTAssertEqual(Set(canvas.details.map(\.subject)), Set(CanvasSubject.allCases))

        var frames: [CGRect] = []
        for detail in canvas.details {
            let frame = detail.frame(in: viewport.size, at: detail.depth)
            XCTAssertTrue(frame.intersects(viewport), "\(detail.subject) is outside its world view.")
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            frames.append(frame)
        }
        XCTAssertGreaterThan(Set(frames.map { $0.midX.rounded() }).count, 8)
        XCTAssertGreaterThan(Set(frames.map { $0.midY.rounded() }).count, 8)
        XCTAssertGreaterThan(Set(frames.map { $0.width.rounded() }).count, 8)
        XCTAssertGreaterThan(Set(frames.map { $0.height.rounded() }).count, 8)
        XCTAssertTrue(frames.contains { viewport.contains($0) })
        XCTAssertTrue(frames.contains { viewport.intersects($0) && !viewport.contains($0) })
    }

    func testCanvasSubjectsKeepTheSameLowerRightProjectionDuringPinch() {
        let canvas = FieldCanvas()
        let pinch: CGFloat = 1.25

        for detail in canvas.details {
            let currentDepth = detail.depth + 1
            let zoomedDepth = currentDepth - log2(Double(pinch))
            let current = detail.frame(in: viewport.size, at: currentDepth)
            let zoomed = detail.frame(in: viewport.size, at: zoomedDepth)

            XCTAssertEqual(zoomed.width, current.width * pinch, accuracy: 0.001)
            XCTAssertEqual(zoomed.height, current.height * pinch, accuracy: 0.001)
            XCTAssertEqual(zoomed.midX - viewport.maxX,
                           (current.midX - viewport.maxX) * pinch, accuracy: 0.001)
            XCTAssertEqual(zoomed.midY - viewport.minY,
                           (current.midY - viewport.minY) * pinch, accuracy: 0.001)
        }
    }

    func testStarterRoomIsAtTheSameWorldLocationWhenRevisited() throws {
        let canvas = FieldCanvas()
        let house = try XCTUnwrap(canvas.marks.first { $0.motif == .hamsterHouse })
        let rug = try XCTUnwrap(canvas.details.first { $0.subject == .roomRug })
        let window = try XCTUnwrap(canvas.details.first { $0.subject == .roomWindow })
        let originalDepth = FieldCamera.worldDepth(owned: 0, zoomScale: 1)
        let originalHouse = house.frame(in: viewport.size, at: originalDepth)
        let originalRug = rug.frame(in: viewport.size, at: originalDepth)
        let originalWindow = window.frame(in: viewport.size, at: originalDepth)
        XCTAssertTrue(originalHouse.intersects(viewport))
        XCTAssertTrue(originalRug.intersects(viewport))
        XCTAssertTrue(originalWindow.intersects(viewport))

        for owned in [18, 198] {
            let zoom = 1 / FieldCamera.pullbackScale(from: 0, to: owned)
            let revisitedDepth = FieldCamera.worldDepth(owned: owned, zoomScale: zoom)
            XCTAssertEqual(house.frame(in: viewport.size, at: revisitedDepth), originalHouse)
            XCTAssertEqual(rug.frame(in: viewport.size, at: revisitedDepth), originalRug)
            XCTAssertEqual(window.frame(in: viewport.size, at: revisitedDepth), originalWindow)
        }
    }

}
