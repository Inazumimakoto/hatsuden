import UIKit
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

    func testDeepCornerZoomRevealsTheStarterAfterAllSpeciesAreUnlocked() throws {
        let highest = 199
        let overviewBounds = StaircaseLayout.zoomedBounds(viewport: viewport.size, scale: 1)
        let overview = StaircaseLayout(bounds: overviewBounds, topSpeciesFloat: Double(highest),
                                       highestOwned: highest, pixelSize: 1 / 3)
        XCTAssertTrue(overview.isCollapsed(0))

        let deepBounds = StaircaseLayout.zoomedBounds(viewport: viewport.size, scale: pow(2, 99))
        let deep = StaircaseLayout(bounds: deepBounds, topSpeciesFloat: Double(highest),
                                   highestOwned: highest, pixelSize: 1 / 3)
        XCTAssertFalse(deep.isCollapsed(0))
        XCTAssertEqual(deep.partition.rect(for: 0), CGRect(x: -320, y: -320, width: 320, height: 320))
        XCTAssertEqual(deep.partition.rect(for: 1), CGRect(x: -320, y: -640, width: 320, height: 320))
        XCTAssertEqual(deep.partition.rect(for: 2), CGRect(x: -640, y: -640, width: 320, height: 640))

        for slot in 0..<8 {
            let cell = try XCTUnwrap(deep.cell(for: 0, slot: slot))
            XCTAssertTrue(overviewBounds.contains(cell))
            XCTAssertEqual(cell, CGRect(x: -320 + (slot % 2) * 160, y: -320 + (slot / 2) * 80,
                                        width: 160, height: 80))
            XCTAssertGreaterThan(StaircaseLayout.wheelDiameter(in: cell), 1 / 3)
        }
    }

    func testCornerZoomKeepsVisibleCellsAtTheSameUniformlyScaledPositions() throws {
        let scale: CGFloat = 3.5
        let overview = StaircaseLayout(bounds: viewport, topSpeciesFloat: 6, highestOwned: 6, pixelSize: 1 / 3)
        let zoomedBounds = StaircaseLayout.zoomedBounds(viewport: viewport.size, scale: scale)
        let zoomed = StaircaseLayout(bounds: zoomedBounds, topSpeciesFloat: 6, highestOwned: 6, pixelSize: 1 / 3)
        for species in 0...2 {
            for slot in 0..<8 {
                let original = try XCTUnwrap(overview.cell(for: species, slot: slot))
                let magnified = try XCTUnwrap(zoomed.cell(for: species, slot: slot))
                XCTAssertEqual(magnified, CGRect(x: (original.minX - viewport.maxX) * scale,
                                                 y: (original.minY - viewport.maxY) * scale,
                                                 width: original.width * scale,
                                                 height: original.height * scale))
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

    func testEveryUnlockPullsBackToTheNextOverviewDepth() {
        let singleUnlock = sqrt(CGFloat(0.5))
        for newRank in 1...199 {
            let oldRank = newRank - 1
            let pullback = FieldCamera.pullbackScale(from: oldRank, to: newRank)
            XCTAssertEqual(pullback, singleUnlock, accuracy: 0.000_01)

            let endDepth = FieldCamera.worldDepth(owned: oldRank, zoomScale: pullback)
            let nextOverview = FieldCamera.worldDepth(owned: newRank, zoomScale: 1)
            XCTAssertEqual(endDepth, nextOverview, accuracy: 0.000_01)
        }
    }

    func testEveryPullbackRevealsMoreOfAnExistingDrawing() {
        let canvas = FieldCanvas()
        let oldScale = FieldCamera.pullbackScale(from: 0, to: 1)
        let previousView = CGRect(x: viewport.width * (1 - oldScale), y: 0,
                                  width: viewport.width * oldScale, height: viewport.height * oldScale)
        func area(_ rect: CGRect) -> CGFloat { rect.isNull ? 0 : rect.width * rect.height }

        for rank in 1...199 {
            let depth = FieldCamera.worldDepth(owned: rank, zoomScale: 1)
            let frames = canvas.details.map { $0.frame(in: viewport.size, at: depth) }
                + canvas.marks.map { $0.frame(in: viewport.size, at: depth) }
            XCTAssertTrue(frames.contains { frame in
                let visible = frame.intersection(viewport)
                return area(visible) - area(visible.intersection(previousView)) >= area(viewport) * 0.02
            }, "No drawing is substantially revealed at rank \(rank).")
        }
    }

    func testPinchReturnsToHistoricalSceneryAcrossTheEntireStaircase() {
        for owned in [8, 9, 198, 199] {
            for oldRank in [1, owned / 2, owned] {
                let originalDepth = FieldCamera.worldDepth(owned: oldRank, zoomScale: 1)
                let historicalZoom = 1 / FieldCamera.pullbackScale(from: oldRank, to: owned)
                XCTAssertEqual(FieldCamera.worldDepth(owned: owned, zoomScale: historicalZoom),
                               originalDepth, accuracy: 0.000_01)
            }
        }
    }

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

    #if DEBUG
    @MainActor
    func testFreshStarterBeeReturnsToItsOriginalRoomAtDeepestZoom() async throws {
        let suite = "TilingTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = GameModel(defaults: defaults)
        XCTAssertEqual(model.species[0].name, "ミツバチ")
        let original = GameScene(model: model)
        original.size = viewport.size
        original.update(1)
        let originalHouse = try XCTUnwrap(original.debugBackdropMarks[.hamsterHouse])
        XCTAssertTrue(originalHouse.intersects(viewport))
        XCTAssertNotNil(original.debugCanvasDetails[CanvasSubject.roomRug.rawValue])
        XCTAssertNotNil(original.debugCanvasDetails[CanvasSubject.roomWindow.rawValue])

        let counts = Array(repeating: "1", count: 9).joined(separator: ",")
        let owned = GameModel.catalog.prefix(9).map { String($0.artIndex) }.joined(separator: ",")
        let save = #"{"balance":"0","counts":[\#(counts)],"savedAt":0,"ownedArtIndices":[\#(owned)]}"#
        defaults.set(Data(save.utf8), forKey: "hatsuden.save.v3")

        let revisited = GameScene(model: GameModel(defaults: defaults))
        revisited.size = viewport.size
        revisited.update(1)
        revisited.debugSetZoom(factor: 14)
        let beforeHouse = try XCTUnwrap(revisited.debugBackdropMarks[.hamsterHouse])
        let beforeWheel = try XCTUnwrap(revisited.debugRunnerFrame(species: 0, slot: 0))
        revisited.debugSetZoom(factor: 16)
        let afterWheel = try XCTUnwrap(revisited.debugRunnerFrame(species: 0, slot: 0))
        let afterHouse = try XCTUnwrap(revisited.debugBackdropMarks[.hamsterHouse])
        XCTAssertEqual(afterHouse.width / beforeHouse.width, afterWheel.width / beforeWheel.width,
                       accuracy: 0.001)
        XCTAssertEqual(revisited.debugBackdropDepth, original.debugBackdropDepth, accuracy: 0.001)
        XCTAssertEqual(revisited.debugBackdropMarks, original.debugBackdropMarks)
        XCTAssertEqual(revisited.debugCanvasDetails, original.debugCanvasDetails)
    }

    @MainActor
    func testLegacyFirstBeeReappearsWithTheSameRoomForEvenAndOddStaircases() async throws {
        let suite = "TilingTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let initialSave = #"{"balance":"0","counts":[1],"savedAt":0,"ownedArtIndices":[0]}"#
        defaults.set(Data(initialSave.utf8), forKey: "hatsuden.save.v3")
        let original = GameScene(model: GameModel(defaults: defaults))
        original.size = viewport.size
        original.update(1)
        let originalHouse = try XCTUnwrap(original.debugBackdropMarks[.hamsterHouse])
        let rugID = CanvasSubject.roomRug.rawValue
        let originalRug = try XCTUnwrap(original.debugCanvasDetails[rugID])

        for highest in [8, 9] {
            defaults.removePersistentDomain(forName: suite)
            let counts = Array(repeating: "1", count: highest + 1).joined(separator: ",")
            let firstIDs = [0, 182]
            let remainingIDs = GameModel.catalog.map(\.artIndex).filter { !firstIDs.contains($0) }
            let owned = (firstIDs + remainingIDs.prefix(highest - 1)).map(String.init).joined(separator: ",")
            let save = #"{"balance":"0","counts":[\#(counts)],"savedAt":0,"ownedArtIndices":[\#(owned)]}"#
            defaults.set(Data(save.utf8), forKey: "hatsuden.save.v3")

            let model = GameModel(defaults: defaults)
            XCTAssertEqual(model.highestOwned, highest)
            XCTAssertEqual(model.species[1].name, "ミツバチ")
            let scene = GameScene(model: model)
            scene.size = viewport.size
            scene.update(1)
            // In an even staircase the bee is the left slab, so frame it
            // shortly before the deepest zoom crops it from the viewport.
            scene.debugSetZoom(factor: highest.isMultiple(of: 2) ? 8 * 1.08 : 16)
            let bee = try XCTUnwrap(scene.debugRunnerFrame(species: 1, slot: 0))
            let beeCenter = CGPoint(x: bee.midX, y: bee.midY)
            XCTAssertTrue(viewport.contains(beeCenter))
            let house = try XCTUnwrap(scene.debugBackdropMarks[.hamsterHouse])
            let rug = try XCTUnwrap(scene.debugCanvasDetails[rugID])
            let roomScale = FieldCamera.magnification(of: original.debugBackdropDepth,
                                                      at: scene.debugBackdropDepth)
            XCTAssertTrue(house.intersects(viewport))
            XCTAssertEqual(house.width, originalHouse.width * roomScale, accuracy: 0.001)
            XCTAssertEqual(rug.midX - viewport.maxX,
                           (originalRug.midX - viewport.maxX) * roomScale, accuracy: 0.001)
            XCTAssertEqual(rug.midY - viewport.minY,
                           (originalRug.midY - viewport.minY) * roomScale, accuracy: 0.001)
        }
    }

    @MainActor
    func testPinchUsesTheSameScaleForTheBackdropAndVisibleWheels() async throws {
        let scene = GameScene(model: GameModel.stressFixture())
        scene.size = viewport.size
        scene.update(1)
        let originalBackdrop = scene.debugBackdropFrame
        let originalWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 195, slot: 0))

        let pinchFactor: CGFloat = 1.04
        scene.debugSetZoom(factor: pinchFactor)
        let zoomedBackdrop = scene.debugBackdropFrame
        let zoomedWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 195, slot: 0))
        let zoom = FieldZoom.overview.magnified(by: pinchFactor, highestOwned: 199).scale
        XCTAssertEqual(zoomedBackdrop.width / originalBackdrop.width, zoom, accuracy: 0.001)
        XCTAssertEqual(zoomedWheel.width / originalWheel.width, zoom, accuracy: 0.001)
        XCTAssertEqual(zoomedWheel.midX - viewport.maxX,
                       (originalWheel.midX - viewport.maxX) * zoom, accuracy: 0.001)
        XCTAssertEqual(zoomedWheel.midY - viewport.minY,
                       (originalWheel.midY - viewport.minY) * zoom, accuracy: 0.001)
    }

    @MainActor
    func testShopAdditionsAreAlreadyOnTheFieldBeforeTheCoverCloses() async throws {
        let suite = "TilingTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let save = #"{"balance":"1938","counts":[1],"savedAt":0,"legacyPrefixCount":0}"#
        defaults.set(Data(save.utf8), forKey: "hatsuden.save.v2")

        let model = GameModel(defaults: defaults)
        let scene = GameScene(model: model)
        scene.size = viewport.size
        scene.update(1)
        let original = scene.debugBackdropDepth
        XCTAssertNil(scene.debugRunnerFrame(species: 0, slot: 1))

        scene.setShopPresented(true)
        XCTAssertTrue(model.purchase(0))
        scene.synchronizeShopAdditions()
        let extra = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 1))
        XCTAssertEqual(scene.debugBackdropDepth, original)

        XCTAssertTrue(model.purchase(1))
        scene.synchronizeShopAdditions()
        scene.update(2)
        XCTAssertEqual(scene.debugRunnerFrame(species: 0, slot: 1), extra)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))
        XCTAssertEqual(scene.debugBackdropDepth, original)

        scene.setShopPresented(false)
        if !UIAccessibility.isReduceMotionEnabled {
            XCTAssertEqual(scene.debugRunnerFrame(species: 0, slot: 1), extra)
            XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))
        }
    }

    @MainActor
    func testUnlockShrinksTogetherPausesSlidesAndThenShowsTheNewAnimal() async throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "The reveal respects Reduce Motion.")
        let suite = "TilingTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let save = #"{"balance":"1920","counts":[1],"savedAt":0,"legacyPrefixCount":0}"#
        defaults.set(Data(save.utf8), forKey: "hatsuden.save.v2")

        let model = GameModel(defaults: defaults)
        let scene = GameScene(model: model)
        scene.size = viewport.size
        scene.update(1)
        let original = scene.debugBackdropFrame
        let starterWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        let originalDetails = scene.debugCanvasDetails
        let computerID = CanvasSubject.computer.rawValue
        let originalComputer = try XCTUnwrap(originalDetails[computerID])
        let originalComputerCoverage = visibleFraction(of: originalComputer)
        XCTAssertGreaterThan(originalComputerCoverage, 0)
        XCTAssertLessThan(originalComputerCoverage, 1)

        scene.setShopPresented(true)
        XCTAssertTrue(model.purchase(1))
        scene.update(2)
        XCTAssertEqual(scene.debugBackdropFrame, original)
        XCTAssertEqual(scene.debugRunnerFrame(species: 0, slot: 0), starterWheel)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))

        let revealStartBackdrop = scene.debugBackdropFrame
        let revealStartWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        scene.setShopPresented(false)
        scene.update(3)
        XCTAssertEqual(scene.debugBackdropFrame, revealStartBackdrop)
        XCTAssertEqual(scene.debugRunnerFrame(species: 0, slot: 0), revealStartWheel)
        XCTAssertEqual(scene.debugCanvasDetails, originalDetails)

        scene.update(3.65)
        let shrinkingBackdrop = scene.debugBackdropFrame
        let shrinkingWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        let shrink = shrinkingBackdrop.width / revealStartBackdrop.width
        XCTAssertLessThan(shrink, 1)
        let shrinkingComputer = try XCTUnwrap(scene.debugCanvasDetails[computerID])
        let shrinkingComputerCoverage = visibleFraction(of: shrinkingComputer)
        XCTAssertGreaterThan(shrinkingComputerCoverage, originalComputerCoverage)
        XCTAssertEqual(shrinkingComputer.width / originalComputer.width, shrink, accuracy: 0.001)
        XCTAssertEqual(shrinkingWheel.width / revealStartWheel.width, shrink, accuracy: 0.001)
        XCTAssertEqual(shrinkingBackdrop.height / revealStartBackdrop.height, shrink, accuracy: 0.001)
        XCTAssertEqual(shrinkingWheel.midX - shrinkingBackdrop.maxX,
                       (revealStartWheel.midX - revealStartBackdrop.maxX) * shrink, accuracy: 0.001)
        XCTAssertEqual(shrinkingWheel.midY - shrinkingBackdrop.minY,
                       (revealStartWheel.midY - revealStartBackdrop.minY) * shrink, accuracy: 0.001)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))

        scene.update(4.22)
        let pausedBackdrop = scene.debugBackdropFrame
        let pausedWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        let pausedDepth = scene.debugBackdropDepth
        let pausedMarks = scene.debugBackdropMarks
        let pausedDetails = scene.debugCanvasDetails
        let pausedComputer = try XCTUnwrap(pausedDetails[computerID])
        XCTAssertGreaterThan(visibleFraction(of: pausedComputer), shrinkingComputerCoverage)
        XCTAssertLessThan(pausedBackdrop.width, shrinkingBackdrop.width)
        XCTAssertEqual(pausedBackdrop.width / revealStartBackdrop.width,
                       FieldCamera.pullbackScale(from: 0, to: 1), accuracy: 0.001)
        XCTAssertEqual(pausedDepth, FieldCamera.worldDepth(owned: 1, zoomScale: 1), accuracy: 0.001)
        scene.update(4.44)
        XCTAssertEqual(scene.debugBackdropFrame, pausedBackdrop)
        XCTAssertEqual(scene.debugBackdropDepth, pausedDepth, accuracy: 0.001)
        XCTAssertEqual(scene.debugBackdropMarks, pausedMarks)
        XCTAssertEqual(scene.debugCanvasDetails, pausedDetails)
        XCTAssertEqual(scene.debugRunnerFrame(species: 0, slot: 0), pausedWheel)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))

        scene.update(5.1)
        let slidingWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        XCTAssertLessThan(slidingWheel.midY, pausedWheel.midY)
        XCTAssertEqual(scene.debugBackdropFrame, pausedBackdrop)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))

        scene.update(5.60)
        let loweredWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        XCTAssertLessThan(loweredWheel.midY, slidingWheel.midY)
        XCTAssertNil(scene.debugRunnerFrame(species: 1, slot: 0))

        scene.update(6.40)
        let settledWheel = try XCTUnwrap(scene.debugRunnerFrame(species: 0, slot: 0))
        let newcomer = try XCTUnwrap(scene.debugRunnerFrame(species: 1, slot: 0))
        XCTAssertLessThanOrEqual(settledWheel.midY, loweredWheel.midY)
        XCTAssertGreaterThan(newcomer.midY, settledWheel.midY)
        XCTAssertEqual(scene.debugBackdropDepth, pausedDepth, accuracy: 0.001)
        XCTAssertEqual(scene.debugBackdropMarks, pausedMarks)
        XCTAssertEqual(scene.debugCanvasDetails, pausedDetails)
    }

    private func visibleFraction(of frame: CGRect) -> CGFloat {
        let visible = viewport.intersection(frame)
        guard !visible.isNull else { return 0 }
        return (visible.width * visible.height) / (frame.width * frame.height)
    }

    func testDeepZoomRestoresAllStarterWheelsFromTheCornerDot() async {
        let viewport = viewport
        await MainActor.run {
            let scene = GameScene(model: GameModel.stressFixture())
            scene.size = viewport.size
            scene.registerTap()
            XCTAssertTrue(scene.debugStarterWheelWidths.isEmpty)
            XCTAssertEqual(scene.debugBackdropFrame, viewport)

            scene.debugZoomToStarter()
            let widths = scene.debugStarterWheelWidths
            XCTAssertEqual(widths.count, 8)
            XCTAssertTrue(widths.allSatisfy { $0 >= 60 })
            let zoom = FieldZoom.overview.magnified(by: 1_000, highestOwned: 199).scale
            XCTAssertEqual(scene.debugBackdropFrame.width / viewport.width, zoom, accuracy: zoom * 0.000_001)
        }
    }

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
