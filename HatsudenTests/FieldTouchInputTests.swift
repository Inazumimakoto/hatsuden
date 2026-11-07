import XCTest
@testable import Hatsuden

final class FieldTouchInputTests: XCTestCase {
    func testTwoAndThreeFingerTapsCountEachFinger() {
        for count in 2...3 {
            var input = FieldTouchInput<Int>()
            let down = Dictionary(uniqueKeysWithValues: (0..<count).map { ($0, point($0 * 40)) })
            let up = down.mapValues { CGPoint(x: $0.x + 2, y: $0.y + 3) }
            input.began(down, at: 0)

            XCTAssertNil(input.moved(up))
            XCTAssertEqual(input.ended(up, at: 0.08), count)
        }
    }

    func testStaggeredTapsCountOnLiftAndResetThePinchPair() {
        var input = FieldTouchInput<Int>()
        input.began([1: point(0)], at: 0)
        input.began([2: point(40)], at: 0.03)

        XCTAssertEqual(input.ended([1: point(0)], at: 0.08), 1)
        input.began([3: point(160)], at: 0.10)
        XCTAssertNil(input.moved([2: point(42)]))
        XCTAssertEqual(input.ended([2: point(42)], at: 0.12), 1)
        XCTAssertEqual(input.ended([3: point(160)], at: 0.17), 1)
    }

    func testPinchSuppressesOnlyItsTwoFingers() throws {
        var input = FieldTouchInput<Int>()
        input.began([1: point(0), 2: point(40)], at: 0)
        XCTAssertNil(input.moved([2: point(49)]))
        let start = try XCTUnwrap(input.moved([2: point(52)]))
        XCTAssertTrue(start.began)
        XCTAssertEqual(start.factor, 1.3, accuracy: 0.001)

        input.began([3: point(100)], at: 0.10)
        XCTAssertNil(input.moved([2: point(55)]))
        XCTAssertEqual(input.ended([3: point(100)], at: 0.16), 1)
        let resumed = try XCTUnwrap(input.moved([2: point(60)]))
        XCTAssertFalse(resumed.began)
        XCTAssertEqual(resumed.factor, 1.5, accuracy: 0.001)

        XCTAssertEqual(input.ended([2: point(60)], at: 0.20), 0)
        XCTAssertEqual(input.ended([1: point(0)], at: 0.21), 0)
    }

    func testPairStartsMeasuringAgainAfterThirdFingerLifts() throws {
        var input = FieldTouchInput<Int>()
        input.began([1: point(0), 2: point(40)], at: 0)
        input.began([3: point(110)], at: 0.04)
        XCTAssertNil(input.moved([2: point(70)]))
        XCTAssertEqual(input.ended([3: point(110)], at: 0.08), 1)
        XCTAssertNil(input.moved([2: point(73)]))
        let pinch = try XCTUnwrap(input.moved([2: point(56)]))
        XCTAssertTrue(pinch.began)
        XCTAssertEqual(pinch.factor, 0.8, accuracy: 0.001)
    }

    func testDragHoldAndCancellationDoNotCountAsTaps() {
        var input = FieldTouchInput<Int>()
        input.began([1: point(0), 2: point(40), 3: point(80)], at: 0)
        XCTAssertNil(input.moved([1: point(20)]))
        XCTAssertEqual(input.ended([1: point(0)], at: 0.10), 0)
        XCTAssertEqual(input.ended([2: point(40)], at: 0.50), 0)
        input.cancelled([3])
        XCTAssertEqual(input.ended([3: point(80)], at: 0.20), 0)
    }

    private func point(_ x: Int) -> CGPoint {
        CGPoint(x: x, y: 0)
    }

    func testTwoFingerPanMovesCameraWithoutGeneratingTaps() throws {
        var input = FieldTouchInput<Int>()
        input.began([1: point(10), 2: point(70)], at: 0)
        let pan = try XCTUnwrap(input.moved([1: point(35), 2: point(95)]))
        XCTAssertTrue(pan.began)
        XCTAssertEqual(pan.incrementalFactor, 1, accuracy: 0.001)
        XCTAssertEqual(pan.previousCenter, point(40))
        XCTAssertEqual(pan.center, point(65))
        XCTAssertEqual(input.ended([1: point(35), 2: point(95)], at: 0.2), 0)
    }

    func testReturningFromThirdFingerDoesNotReplayPausedMovement() throws {
        var input = FieldTouchInput<Int>()
        input.began([1: point(10), 2: point(70)], at: 0)
        _ = input.moved([2: point(90)])
        input.began([3: point(140)], at: 0.1)
        XCTAssertNil(input.moved([1: point(50), 2: point(130)]))
        XCTAssertEqual(input.ended([3: point(140)], at: 0.15), 1)
        let resumed = try XCTUnwrap(input.moved([1: point(51), 2: point(131)]))
        XCTAssertEqual(resumed.incrementalFactor, 1, accuracy: 0.001)
        XCTAssertEqual(resumed.center.x - resumed.previousCenter.x, 1, accuracy: 0.001)
    }
}
