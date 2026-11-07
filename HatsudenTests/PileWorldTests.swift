import XCTest
@testable import Hatsuden

final class PileWorldTests: XCTestCase {
    private let box = CGRect(x: -240, y: 0, width: 240, height: 400)

    func testPurchasedWheelEntersMovingAndSettlesInsideTheBox() {
        var world = PileWorld(bounds: box)
        let id = world.add(species: 0, slot: 0, radius: 24)
        XCTAssertEqual(id, 0)
        XCTAssertEqual(world.wheels.count, 1)
        XCTAssertGreaterThan(world.wheels[0].position.x, box.midX)
        XCTAssertGreaterThan(world.wheels[0].position.y, box.midY)
        XCTAssertLessThan(world.wheels[0].velocity.dx, 0)
        XCTAssertTrue(world.isMoving)
        for _ in 0..<600 { world.advance(delta: 1.0 / 60) }
        let wheel = world.wheels[0]
        XCTAssertEqual(wheel.position.y, box.minY + wheel.radius, accuracy: 0.001)
        XCTAssertTrue(wheel.isSleeping)
        XCTAssertFalse(world.isMoving)
        assertContained(world)
    }

    func testExpandingContainerKeepsExistingArrangementAndBottomRightAnchor() {
        var world = PileWorld(bounds: box)
        world.addSettled(species: 0, slot: 0, radius: 24)
        let before = world.wheels[0].position
        world.expand(to: CGRect(x: -960, y: 0, width: 960, height: 1600))
        XCTAssertEqual(world.wheels[0].position, before)
        XCTAssertEqual(world.bounds.maxX, box.maxX)
        XCTAssertEqual(world.bounds.minY, box.minY)
        XCTAssertEqual(world.bounds.width, 960)
    }

    func testZoomedPurchaseUsesItsFrozenVisibleLaunchScale() {
        let largeBox = CGRect(x: -4_000_000, y: 0, width: 4_000_000, height: 7_000_000)
        var world = PileWorld(bounds: largeBox)
        let start = CGPoint(x: -200, y: 300)
        world.add(species: 0, slot: 0, radius: 1, at: start,
                  launchSize: CGSize(width: 200, height: 300))
        world.advance(delta: 1.0 / 60)
        XCTAssertLessThan(abs(world.wheels[0].position.x - start.x), 3)
        XCTAssertLessThan(abs(world.wheels[0].position.y - start.y), 3)
        XCTAssertGreaterThan(hypot(world.wheels[0].velocity.dx, world.wheels[0].velocity.dy), 0)
    }

    func testMixedSizeContactFindsLargerWheelAcrossTreeLevels() {
        var world = PileWorld(bounds: CGRect(x: -600, y: 0, width: 600, height: 1000))
        world.addSettled(species: 4, slot: 0, radius: 80)
        let big = world.wheels[0]
        world.add(species: 0, slot: 0, radius: 10,
                  at: CGPoint(x: big.position.x + 70, y: big.position.y))
        world.advance(delta: 1.0 / 120, minimumCollisionRadius: 20)
        let a = world.wheels[0]
        let b = world.wheels[1]
        XCTAssertGreaterThan(hypot(a.position.x - b.position.x, a.position.y - b.position.y), 88)
        assertContained(world)
    }

    func testShakeMovesAlmostEveryWheelAndKeepsAllIdentities() {
        var world = PileWorld(bounds: CGRect(x: -800, y: 0, width: 800, height: 1300))
        for slot in 0..<80 { world.addSettled(species: 0, slot: slot, radius: CGFloat(10 + slot % 3)) }
        let initial = world.wheels.map(\.position)
        let ids = world.wheels.map(\.id)
        XCTAssertEqual(world.movingCount, 0)
        world.shake()
        XCTAssertEqual(world.movingCount, 80)
        for _ in 0..<20 { world.advance(delta: 1.0 / 60) }
        world.shake()
        for _ in 0..<20 { world.advance(delta: 1.0 / 60) }
        let moved = zip(initial, world.wheels).filter {
            hypot($0.x - $1.position.x, $0.y - $1.position.y) > $1.radius
        }.count
        XCTAssertGreaterThan(moved, 72)
        XCTAssertEqual(world.wheels.map(\.id), ids)
        XCTAssertEqual(world.wheels.count, 80)
        assertContained(world)
    }

    func testSnapshotRoundTripPreservesEachWheelAndItsArrangement() throws {
        var original = PileWorld(bounds: box)
        for slot in 0..<12 { original.addSettled(species: slot % 3, slot: slot, radius: 9) }
        original.shake()
        original.advance(delta: 0.05)
        let data = try JSONEncoder().encode(original.snapshot)
        let saved = try JSONDecoder().decode(PileWorldSnapshot.self, from: data)
        var restored = PileWorld(bounds: box)
        XCTAssertTrue(restored.restore(saved))
        XCTAssertEqual(restored.wheels.map(\.id), original.wheels.map(\.id))
        XCTAssertEqual(restored.wheels.map(\.position), original.wheels.map(\.position))
        XCTAssertEqual(restored.wheels.map(\.angle), original.wheels.map(\.angle))
        XCTAssertEqual(restored.wheels.map(\.velocity), original.wheels.map(\.velocity))
        XCTAssertEqual(restored.wheels.map(\.isSleeping), original.wheels.map(\.isSleeping))
        XCTAssertEqual(restored.movingCount, original.movingCount)
        XCTAssertEqual(restored.add(species: 0, slot: 12, radius: 9), 12)
    }

    func testAirborneWheelResumesFallingAfterRestoringSave() throws {
        var original = PileWorld(bounds: box)
        original.add(species: 0, slot: 0, radius: 24)
        original.advance(delta: 0.05)
        let data = try JSONEncoder().encode(original.snapshot)
        var restored = PileWorld(bounds: box)
        XCTAssertTrue(restored.restore(try JSONDecoder().decode(PileWorldSnapshot.self, from: data)))
        let airborneY = restored.wheels[0].position.y
        XCTAssertTrue(restored.isMoving)
        restored.advance(delta: 0.05)
        XCTAssertLessThan(restored.wheels[0].position.y, airborneY)
        for _ in 0..<600 { restored.advance(delta: 1.0 / 60) }
        XCTAssertEqual(restored.wheels[0].position.y, restored.wheels[0].radius, accuracy: 0.001)
        XCTAssertTrue(restored.wheels[0].isSleeping)
    }

    func testTinyAndGiantWheelsRemainFiniteDuringRepeatedShakes() {
        var world = PileWorld(bounds: CGRect(x: -4_000_000, y: 0, width: 4_000_000, height: 7_000_000))
        world.addSettled(species: 199, slot: 0, radius: 800_000)
        for slot in 0..<40 { world.addSettled(species: 0, slot: slot, radius: 1) }
        let initial = world.wheels.map(\.position)
        let identities = world.wheels.map(\.id)
        for step in 0..<180 {
            if step.isMultiple(of: 30) { world.shake() }
            world.advance(delta: 1.0 / 60, minimumCollisionRadius: 100)
        }
        XCTAssertEqual(world.wheels.count, 41)
        XCTAssertEqual(world.wheels.map(\.id), identities)
        XCTAssertGreaterThanOrEqual(zip(initial, world.wheels).filter {
            $1.radius < 100 && hypot($0.x - $1.position.x, $0.y - $1.position.y) > $1.radius
        }.count, 36)
        XCTAssertTrue(world.wheels.allSatisfy {
            $0.position.x.isFinite && $0.position.y.isFinite
                && $0.angle.isFinite && $0.velocity.dx.isFinite && $0.velocity.dy.isFinite
        })
        assertContained(world)
    }

    private func assertContained(_ world: PileWorld, file: StaticString = #filePath, line: UInt = #line) {
        for wheel in world.wheels {
            XCTAssertGreaterThanOrEqual(wheel.position.x - wheel.radius, world.bounds.minX - 0.001, file: file, line: line)
            XCTAssertLessThanOrEqual(wheel.position.x + wheel.radius, world.bounds.maxX + 0.001, file: file, line: line)
            XCTAssertGreaterThanOrEqual(wheel.position.y - wheel.radius, world.bounds.minY - 0.001, file: file, line: line)
            XCTAssertLessThanOrEqual(wheel.position.y + wheel.radius, world.bounds.maxY + 0.001, file: file, line: line)
        }
    }
}
