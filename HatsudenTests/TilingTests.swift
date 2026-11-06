import XCTest
@testable import Hatsuden

final class TilingTests: XCTestCase {
    private let viewport = CGRect(x: 0, y: 0, width: 320, height: 640)

    func testAlternatingHalvesAndStarterRemainderFillTheField() {
        let partition = StaircaseLayout(bounds: viewport, topSpeciesFloat: 3,
                                        highestOwned: 3, pixelSize: 1 / 3).partition
        XCTAssertEqual(partition.rect(for: 3), CGRect(x: 0, y: 0, width: 320, height: 320))
        XCTAssertEqual(partition.rect(for: 2), CGRect(x: 0, y: 320, width: 160, height: 320))
        XCTAssertEqual(partition.rect(for: 1), CGRect(x: 160, y: 320, width: 160, height: 160))
        XCTAssertEqual(partition.rect(for: 0), CGRect(x: 160, y: 480, width: 160, height: 160))
        XCTAssertNil(partition.collapsedThrough)
    }

    func testEveryOldTierKeepsACellAtTheOnePixelCutoff() throws {
        let layout = StaircaseLayout(bounds: viewport, topSpeciesFloat: 199,
                                     highestOwned: 199, pixelSize: 1 / 3)
        let cutoff = try XCTUnwrap(layout.partition.collapsedThrough)
        XCTAssertGreaterThan(cutoff, 0)
        XCTAssertEqual(layout.partition.dot.x, viewport.maxX - 1 / 6, accuracy: 0.001)
        XCTAssertEqual(layout.partition.dot.y, viewport.maxY - 1 / 6, accuracy: 0.001)
        for species in 0...cutoff {
            for slot in 0..<8 {
                let cell = try XCTUnwrap(layout.cell(for: species, slot: slot))
                XCTAssertEqual(cell.origin, layout.partition.dot)
                XCTAssertEqual(cell.size, .zero)
            }
        }
    }

    func testUnlockKeepsExistingUnitsContinuousAtIntegerBoundary() throws {
        let exact = StaircaseLayout(bounds: viewport, topSpeciesFloat: 1,
                                    highestOwned: 2, pixelSize: 1 / 3)
        let transition = StaircaseLayout(bounds: viewport, topSpeciesFloat: 1.000001,
                                        highestOwned: 2, pixelSize: 1 / 3)
        XCTAssertEqual(try XCTUnwrap(transition.partition.rect(for: 2)).height, 0.00032, accuracy: 0.000001)
        for species in 0...1 {
            for slot in 0..<8 {
                let oldCell = try XCTUnwrap(exact.cell(for: species, slot: slot))
                let newCell = try XCTUnwrap(transition.cell(for: species, slot: slot))
                XCTAssertEqual(newCell.midX, oldCell.midX, accuracy: 0.001)
                XCTAssertEqual(newCell.midY, oldCell.midY, accuracy: 0.001)
            }
        }
    }

    func testSlotEightFitsBothGridOrientations() {
        let tall = CGRect(x: 10, y: 20, width: 100, height: 120)
        let wide = CGRect(x: 10, y: 20, width: 120, height: 100)
        XCTAssertEqual(StaircaseLayout.cell(in: tall, slot: 7), CGRect(x: 60, y: 110, width: 50, height: 30))
        XCTAssertEqual(StaircaseLayout.cell(in: wide, slot: 7), CGRect(x: 100, y: 70, width: 30, height: 50))
    }

    func testSmallWheelsOnlyBecomeDotsAtPhysicalPixelSize() {
        let pixelSize: CGFloat = 1 / 3
        XCTAssertFalse(StaircaseLayout.usesPixelDot(
            in: CGRect(x: 0, y: 0, width: 4, height: 3), pixelSize: pixelSize
        ))
        XCTAssertTrue(StaircaseLayout.usesPixelDot(
            in: CGRect(x: 0, y: 0, width: 0.5, height: 0.35), pixelSize: pixelSize
        ))
    }

    func testEveryUnlockRevealsMoreOfTheSameLowerRightAnchoredBackground() {
        let first = FieldCamera.artworkFrame(in: viewport, topSpecies: 0, lastSpecies: 199)
        XCTAssertEqual(first.width, viewport.width * 12)
        XCTAssertEqual(first.height, viewport.height * 12)
        var previous = first

        for species in 1...199 {
            let current = FieldCamera.artworkFrame(in: viewport, topSpecies: Double(species), lastSpecies: 199)
            XCTAssertEqual(current.maxX, viewport.maxX, accuracy: 0.000_01)
            XCTAssertEqual(current.minY, viewport.minY, accuracy: 0.000_01)
            XCTAssertLessThan(current.width, previous.width)
            XCTAssertLessThan(current.height, previous.height)
            XCTAssertTrue(current.contains(viewport))
            previous = current
        }
        XCTAssertEqual(previous, viewport)
    }

    func testUnlockShowsAnIntermediateBackgroundScale() {
        let start = FieldCamera.artworkFrame(in: viewport, topSpecies: 1, lastSpecies: 199)
        let middle = FieldCamera.artworkFrame(in: viewport, topSpecies: 1.5, lastSpecies: 199)
        let end = FieldCamera.artworkFrame(in: viewport, topSpecies: 2, lastSpecies: 199)
        XCTAssertGreaterThan(start.width, middle.width)
        XCTAssertGreaterThan(middle.width, end.width)
        XCTAssertEqual(middle.maxX, viewport.maxX, accuracy: 0.000_01)
    }

    #if DEBUG
    func testCornerHamstersStillEmitInEveryFullWaveAfterRecycling() async {
        await MainActor.run {
            let model = GameModel.stressFixture()
            let scene = GameScene(model: model)
            scene.size = CGSize(width: 320, height: 640)
            for _ in 0..<4 { scene.registerTap() }
            XCTAssertEqual(scene.debugHamstersAtCutoff, 8)
            XCTAssertTrue(scene.debugActiveWaveSizes.isEmpty)

            scene.registerTap()
            XCTAssertEqual(scene.debugActiveWaveSizes, [1_600])
            scene.registerTap()
            XCTAssertEqual(scene.debugActiveWaveSizes, [1_600, 1_600])
            let regularTexture = scene.debugLastWaveFirstTexture

            scene.update(100)
            scene.update(101)
            XCTAssertTrue(scene.debugActiveWaveSizes.isEmpty)

            XCTAssertTrue(model.activateBoost(.tap))
            scene.registerTap()
            XCTAssertEqual(scene.debugActiveWaveSizes, [1_600])
            XCTAssertNotNil(regularTexture)
            XCTAssertFalse(scene.debugLastWaveFirstTexture === regularTexture)
            XCTAssertTrue(scene.debugLastWaveFirstTexture === ArtProvider.shared.moneyTexture(
                index: 0, amount: GameModel.catalog[0].income * 2
            ))
        }
    }
    #endif
}
