import SpriteKit
import XCTest
@testable import Hatsuden

final class PileSceneTests: XCTestCase {
    @MainActor
    func testSceneryAndWheelsShareTheFreeCamera() async throws {
        let (model, defaults, name) = try fixture(counts: [12, 3, 2])
        defer { defaults.removePersistentDomain(forName: name) }
        let scene = GameScene(model: model)
        scene.size = CGSize(width: 310, height: 560)
        scene.update(0)
        let before = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        let paper = scene.debugBackdropFrame
        let camera = scene.debugCamera
        let anchor = CGPoint(x: 155, y: 280)
        scene.debugSetZoom(factor: 2, at: anchor)
        let after = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        XCTAssertEqual(after.width / before.width, 2, accuracy: 0.001)
        XCTAssertEqual(scene.debugBackdropFrame.width / paper.width, 2, accuracy: 0.001)
        XCTAssertEqual(scene.debugCamera.worldPoint(fromScreen: anchor).x,
                       camera.worldPoint(fromScreen: anchor).x, accuracy: 0.001)
        scene.debugPan(by: CGPoint(x: 23, y: 15))
        let moved = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        XCTAssertEqual(moved.midX - after.midX, 23, accuracy: 0.001)
        XCTAssertEqual(moved.midY - after.midY, 15, accuracy: 0.001)
    }

    @MainActor
    func testShakingMovesThePileWithoutGeneratingMoneyAndSavesTheArrangement() async throws {
        let (model, defaults, name) = try fixture(counts: [40])
        defer { defaults.removePersistentDomain(forName: name) }
        let scene = GameScene(model: model)
        scene.size = CGSize(width: 310, height: 560)
        scene.update(0)
        let original = scene.debugWorld.wheels.map(\.position)
        let balance = model.balance
        scene.shake()
        for step in 1...30 { scene.update(Double(step) / 60) }
        let mixed = scene.debugWorld.wheels.map(\.position)
        XCTAssertGreaterThan(zip(original, mixed).filter { $0 != $1 }.count, 35)
        XCTAssertEqual(model.balance, balance)
        XCTAssertEqual(model.meter, 0)
        scene.setRenderingActive(false)
        let restored = GameScene(model: GameModel(defaults: defaults))
        restored.size = scene.size
        restored.update(0)
        XCTAssertEqual(restored.debugWorld.wheels.map(\.position), mixed)
    }

    @MainActor
    func testEveryOwnedAnimalEmitsIncludingSubpixelWheelsAfterPooling() async throws {
        let model = GameModel.stressFixture()
        let scene = GameScene(model: model)
        scene.size = CGSize(width: 310, height: 560)
        scene.update(0)
        XCTAssertEqual(scene.debugWorld.wheels.count, 1_600)
        let small = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        XCTAssertLessThan(small.width, 1)
        for _ in 0..<6 { scene.registerTap() }
        XCTAssertEqual(scene.debugActiveWaveSizes, [1_600, 1_600])
        scene.setRenderingActive(false)
        XCTAssertTrue(scene.debugActiveWaveSizes.isEmpty)
        scene.setRenderingActive(true)
        scene.registerTap()
        XCTAssertEqual(scene.debugActiveWaveSizes, [1_600])
    }

    @MainActor
    func testClosingAppInsideShopPreservesOldPileAndQueuesNewPurchases() async throws {
        let (model, defaults, name) = try fixture(counts: [12])
        defer { defaults.removePersistentDomain(forName: name) }
        let scene = GameScene(model: model)
        scene.size = CGSize(width: 310, height: 560)
        scene.update(0)
        let previous = scene.debugWorld.wheels.map(\.position)
        scene.setShopPresented(true)
        XCTAssertTrue(model.purchase(0))
        XCTAssertTrue(model.purchase(1))
        scene.setRenderingActive(false)
        let restoredModel = GameModel(defaults: defaults)
        let restored = GameScene(model: restoredModel)
        restored.size = scene.size
        restored.update(0)
        XCTAssertEqual(Array(restored.debugWorld.wheels.prefix(12)).map(\.position), previous)
        XCTAssertEqual(restored.debugWorld.wheels.count + restored.debugPendingCount, 14)
    }

    @MainActor
    func testSmallAdditionalPurchaseKeepsCloseUpAndEntersAtVisibleUpperRight() async throws {
        let (model, defaults, name) = try fixture(counts: [200])
        defer { defaults.removePersistentDomain(forName: name) }
        let scene = GameScene(model: model)
        scene.size = CGSize(width: 310, height: 560)
        scene.update(0)
        scene.debugSetZoom(factor: 2)
        let camera = scene.debugCamera
        scene.setShopPresented(true)
        XCTAssertTrue(model.purchase(0))
        scene.setShopPresented(false)
        scene.update(1.0 / 60)
        XCTAssertEqual(scene.debugCamera, camera)
        let wheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 200))
        XCTAssertGreaterThan(wheel.midX, 240)
        XCTAssertGreaterThan(wheel.midY, 450)
        XCTAssertEqual(scene.debugWorld.wheels.count, 201)
    }

    @MainActor
    private func fixture(counts: [Int]) throws -> (GameModel, UserDefaults, String) {
        let name = "hatsuden.pile.scene.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        let save: [String: Any] = ["balance": "99999999999999999999999999", "counts": counts,
            "savedAt": Date().timeIntervalSinceReferenceDate,
            "ownedArtIndices": Array(GameModel.catalog.prefix(counts.count)).map(\.artIndex)]
        defaults.set(try JSONSerialization.data(withJSONObject: save), forKey: "hatsuden.save.v3")
        return (GameModel(defaults: defaults), defaults, name)
    }
}
