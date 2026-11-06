import Foundation
import XCTest
@testable import Hatsuden

final class GameModelTests: XCTestCase {
    @MainActor
    func testSpeciesUnlockSequentiallyAndAdditionalAnimalsStopAtEight() async {
        let catalog = GameModel.catalog
        XCTAssertEqual(catalog.count, 200)
        XCTAssertEqual(Set(catalog.map(\.name)).count, 200)
        XCTAssertEqual(catalog[0].income, 1)
        XCTAssertEqual(catalog.first(where: { $0.name == "ネコ" })?.assetKey, "animal_004")
        XCTAssertEqual(Set(catalog.map(\.id)), Set(1...200))
        for (previous, next) in zip(catalog, catalog.dropFirst()) {
            XCTAssertEqual(next.income, previous.income * 9)
            XCTAssertGreaterThan(next.income, previous.income * 8)
        }

        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = #"{"balance":252,"counts":[1],"savedAt":0}"#
        defaults.set(Data(legacy.utf8), forKey: "hatsuden.save.v1")
        let model = GameModel(defaults: defaults)
        XCTAssertEqual(model.totalAnimals, 1)
        XCTAssertTrue(model.isUnlocked(1))
        XCTAssertFalse(model.isUnlocked(2))
        XCTAssertFalse(model.canAfford(1))
        for _ in 1..<7 {
            XCTAssertTrue(model.purchase(0))
        }
        XCTAssertEqual(model.counts[0], 7)
        XCTAssertTrue(model.isUnlocked(1))
        XCTAssertFalse(model.purchase(1))
        XCTAssertTrue(model.purchase(0))
        XCTAssertEqual(model.counts[0], 8)
        XCTAssertTrue(model.isUnlocked(1))
        XCTAssertFalse(model.canAfford(1), "Filling the stage still leaves the next adoption to earn")
        let balanceAtCap = model.balance
        XCTAssertFalse(model.purchase(0))
        XCTAssertEqual(model.balance, balanceAtCap)

        for _ in 0..<4 { XCTAssertEqual(model.tap(), 0) }
        for _ in 0..<239 { XCTAssertEqual(model.tap(), 1) }
        XCTAssertFalse(model.canAfford(1))
        XCTAssertEqual(model.tap(), 1)
        XCTAssertTrue(model.purchase(1))
        XCTAssertTrue(model.isUnlocked(2))
        XCTAssertEqual(model.incomePerPulse, 17)
        XCTAssertEqual(GameModel(defaults: defaults).counts.prefix(3), [8, 1, 0])
    }

    @MainActor
    func testNewCatalogStartsSmallAndAnOlderSaveKeepsTheSharkItBought() async throws {
        let catalog = GameModel.catalog
        XCTAssertEqual(catalog.first?.name, "ミツバチ")
        let sizes = try catalog.map { try XCTUnwrap(AnimalCatalog.sizeByName[$0.name]) }
        XCTAssertEqual(sizes, sizes.sorted())
        let sharkRank = try XCTUnwrap(catalog.firstIndex(where: { $0.name == "足つきサメ" }))
        XCTAssertGreaterThan(sharkRank, 150)

        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let oldCounts = Array(repeating: 1, count: 9) + [3]
        let countsJSON = String(decoding: try JSONEncoder().encode(oldCounts), as: UTF8.self)
        let saved = "{\"balance\":\"122\",\"counts\":\(countsJSON),\"savedAt\":0,\"legacyPrefixCount\":0}"
        defaults.set(Data(saved.utf8), forKey: "hatsuden.save.v2")
        let model = GameModel(defaults: defaults)
        XCTAssertEqual(model.species[9].name, "足つきサメ")
        XCTAssertEqual(model.counts[9], 3)
        XCTAssertEqual(model.balance, 122)
        XCTAssertEqual(model.species[10].name, "ミツバチ")
        XCTAssertEqual(GameModel(defaults: defaults).species.map(\.id), model.species.map(\.id))
    }

    @MainActor
    func testSufficientSavingsCanBuyTheNextSpeciesBeforeOwningEight() async {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let saved = #"{"balance":"1920","counts":[1],"savedAt":0,"legacyPrefixCount":0}"#
        defaults.set(Data(saved.utf8), forKey: "hatsuden.save.v2")

        let model = GameModel(defaults: defaults)
        XCTAssertEqual(model.counts[0], 1)
        XCTAssertTrue(model.isUnlocked(1))
        XCTAssertTrue(model.purchase(1))
        XCTAssertEqual(model.counts.prefix(2), [1, 1])
        XCTAssertEqual(model.balance, 0)
    }

    @MainActor
    func testTapsChargeBeforeThresholdAndPayOnlyOnQualifyingTaps() async {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = GameModel(defaults: defaults)

        for _ in 0..<4 {
            XCTAssertEqual(model.tap(), 0)
            model.update(delta: 0.1)
        }
        XCTAssertFalse(model.isLit)
        XCTAssertEqual(model.balance, 0)
        XCTAssertEqual(model.tap(), 1)
        XCTAssertTrue(model.isLit)
        XCTAssertEqual(model.balance, 1)

        XCTAssertEqual(model.tap(), 1)
        XCTAssertEqual(model.tap(), 1)
        XCTAssertEqual(model.balance, 3)

        model.update(delta: 0.4)
        XCTAssertFalse(model.isLit)
        XCTAssertFalse(model.isReceivingTaps)
        XCTAssertEqual(model.balance, 3)
        XCTAssertGreaterThan(model.meter, GameModel.ignitionLevel)
        XCTAssertEqual(model.tap(), 1, "Every tap while already charged pays once")
        model.update(delta: 10)
        XCTAssertEqual(model.meter, 0)
        XCTAssertEqual(model.balance, 4)
    }

    @MainActor
    func testLegacySaveKeepsBalanceAndRosterAndEarnsOfflineOncePerAbsence() async throws {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        var now = Date(timeIntervalSinceReferenceDate: 100)
        struct LegacySave: Encodable {
            let balance: Double
            let counts: [Int]
            let savedAt: Date
        }
        let legacy = LegacySave(balance: 49.75, counts: [2, 1], savedAt: now - 60)
        let saveKey = "hatsuden.save.v1"
        defaults.set(try JSONEncoder().encode(legacy), forKey: saveKey)

        let model = GameModel(defaults: defaults, now: { now })
        let startingBalance: Yen = 49
        XCTAssertEqual(model.balance, startingBalance)
        XCTAssertEqual(model.counts.prefix(3), [2, 1, 0])
        model.update(delta: 15)
        XCTAssertEqual(model.balance, startingBalance)
        model.setActive(false)

        now += 120
        model.update(delta: 120)
        XCTAssertEqual(model.tap(), 0)
        model.setActive(true)
        XCTAssertEqual(model.balance, startingBalance + 11)
        XCTAssertEqual(model.offlineEarnings, 11)
        model.dismissOfflineEarnings()
        XCTAssertNil(model.offlineEarnings)
        XCTAssertEqual(model.meter, 0)

        model.setActive(false)
        now += 120
        let reloaded = GameModel(defaults: defaults, now: { now })
        XCTAssertEqual(reloaded.balance, startingBalance + 22)
        XCTAssertEqual(reloaded.offlineEarnings, 11)
        XCTAssertEqual(reloaded.counts.prefix(3), [2, 1, 0])
        XCTAssertEqual(GameModel(defaults: defaults, now: { now }).balance, reloaded.balance)

        reloaded.setActive(false)
        now += 3
        reloaded.setActive(true)
        XCTAssertEqual(reloaded.balance, startingBalance + 23, "The old 0.75 yen was carried across relaunch")
    }

    @MainActor
    func testBoostsAreIndependentAndCreditOnlyTheOverlappingOfflineTime() async {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let model = GameModel(defaults: defaults, now: { now })
        XCTAssertTrue(model.activateBoost(.tap))
        XCTAssertTrue(model.activateBoost(.background))
        XCTAssertFalse(model.activateBoost(.tap))
        XCTAssertFalse(model.activateBoost(.background))
        XCTAssertTrue(model.isBackgroundBoostActive)
        XCTAssertEqual(model.boostRemaining(.background), 300)

        for _ in 0..<4 { XCTAssertEqual(model.tap(), 0) }
        XCTAssertEqual(model.tap(), 1)
        XCTAssertEqual(model.tapMultiplier, 2)
        XCTAssertEqual(model.balance, 2)

        now += 120
        model.update(delta: 120)
        XCTAssertEqual(model.balance, 2, "The background boost does not generate foreground money")
        model.setActive(false)
        now += 120
        model.setActive(true)
        XCTAssertEqual(model.balance, 4)
        XCTAssertEqual(model.boostRemaining(.background), 60)

        model.setActive(false)
        now += 120
        let reloaded = GameModel(defaults: defaults, now: { now })
        XCTAssertEqual(reloaded.balance, 5)
        XCTAssertFalse(reloaded.isBackgroundBoostActive)
        XCTAssertFalse(reloaded.isTapBoostActive)
        for _ in 0..<5 { reloaded.tap() }
        XCTAssertEqual(reloaded.tapMultiplier, 1)
        XCTAssertEqual(reloaded.balance, 6)
        reloaded.setActive(false)
        now += 60
        reloaded.setActive(true)
        XCTAssertEqual(reloaded.balance, 7, "The two half-yen payouts combine after relaunch")
    }

    @MainActor
    func testFullBalanceKeepsSingleYenInLateGameAndAcrossSave() async throws {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let saveKey = "hatsuden.save.v1"
        let fixture = #"{"balance":10000000000000000000000000000,"counts":[1],"savedAt":0}"#
        defaults.set(Data(fixture.utf8), forKey: saveKey)

        let model = GameModel(defaults: defaults)
        for _ in 0..<5 { model.tap() }
        XCTAssertEqual(Currency.full(model.balance), "10,000,000,000,000,000,000,000,000,001")
        model.setActive(false)

        let reloaded = GameModel(defaults: defaults)
        XCTAssertEqual(Currency.full(reloaded.balance), "10,000,000,000,000,000,000,000,000,001")
    }

    @MainActor
    func testPurchasedAnimalsKeepTheirIdentitiesAfterCatalogReordering() async throws {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let changedIndex = try XCTUnwrap(AnimalCatalog.names.indices.first {
            AnimalCatalog.names[$0] != AnimalCatalog.legacyNames[$0]
        })
        let counts = Array(repeating: 8, count: changedIndex) + [2]
        let countsJSON = String(decoding: try JSONEncoder().encode(counts), as: UTF8.self)
        let fixture = "{\"balance\":0,\"counts\":\(countsJSON),\"savedAt\":0}"
        defaults.set(Data(fixture.utf8), forKey: "hatsuden.save.v1")

        let model = GameModel(defaults: defaults)
        XCTAssertEqual(model.species.prefix(counts.count).map(\.name),
                       Array(AnimalCatalog.legacyNames.prefix(counts.count)))
        XCTAssertEqual(model.species[changedIndex].artIndex, changedIndex)
        XCTAssertEqual(model.counts[changedIndex], 2)
        XCTAssertTrue(model.isUnlocked(changedIndex))
        XCTAssertTrue(model.isUnlocked(changedIndex + 1))
        XCTAssertEqual(Set(model.species.map(\.name)).count, 200)
        XCTAssertEqual(Set(model.species.map(\.id)).count, 200)
        XCTAssertEqual(GameModel(defaults: defaults).species.map(\.name), model.species.map(\.name))
    }

    @MainActor
    func testUpgradeSettlesThePendingAbsenceAtTheRateFromThePreviousSave() async {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let fixture = #"{"balance":0,"counts":[8,1],"savedAt":0,"earnsOffline":true,"backgroundBoostUntil":300}"#
        defaults.set(Data(fixture.utf8), forKey: "hatsuden.save.v1")
        var now = Date(timeIntervalSinceReferenceDate: 120)
        let model = GameModel(defaults: defaults, now: { now })
        XCTAssertEqual(model.balance, 22, "The prior roster earned 11 per pulse, doubled by the boost")
        XCTAssertTrue(model.isBackgroundBoostActive)
        XCTAssertEqual(model.incomePerPulse, 17)

        model.setActive(false)
        now += 120
        model.setActive(true)
        XCTAssertEqual(model.balance, 56, "The next absence uses the new roster income")
    }

    @MainActor
    func testLastStageBalanceAboveDecimalRangeKeepsAOneYenTapAcrossSave() async throws {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let openingDigits = "1" + String(repeating: "0", count: 192)
        let fixture = "{\"balance\":\"\(openingDigits)\",\"counts\":[1],\"savedAt\":0,\"legacyPrefixCount\":0}"
        defaults.set(Data(fixture.utf8), forKey: "hatsuden.save.v2")

        let model = GameModel(defaults: defaults)
        for _ in 0..<5 { model.tap() }
        let expected = "1" + String(repeating: "0", count: 191) + "1"
        XCTAssertEqual(model.balance.digits, expected)
        XCTAssertEqual(Currency.full(model.balance).replacingOccurrences(of: ",", with: ""), expected)
        model.setActive(false)
        XCTAssertEqual(GameModel(defaults: defaults).balance.digits, expected)
        XCTAssertGreaterThan(GameModel.catalog[199].income.digits.count, 128)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let name = "hatsuden.tests.\(UUID())"
        return (UserDefaults(suiteName: name)!, name)
    }
}
