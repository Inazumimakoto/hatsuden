import Foundation
import Observation

struct AnimalSpecies: Identifiable, Sendable {
    let index: Int
    let artIndex: Int
    let name: String
    let cost: Yen
    let income: Yen

    var id: Int { artIndex + 1 }
    var assetKey: String { String(format: "animal_%03d", id) }
}

enum BoostKind: String, CaseIterable, Identifiable {
    case tap
    case background

    var id: Self { self }
}

@MainActor
@Observable
final class GameModel {
    nonisolated static let ignitionLevel = 0.70
    nonisolated static let boostDuration: TimeInterval = 5 * 60
    nonisolated static let secondsPerOfflinePulse = 120
    nonisolated static let catalog = makeAnimalCatalog(names: AnimalCatalog.names)

    private static let tapCharge = 0.16
    private static let decayPerSecond = 0.10
    private static let tapWindow = 0.40
    private static let saveInterval = 8.0
    private static let saveKey = "hatsuden.save.v3"
    private static let pileLayoutKey = "hatsuden.pile.v1"
    private static let previousSaveKey = "hatsuden.save.v2"
    private static let legacySaveKey = "hatsuden.save.v1"
    private static let millisecondsPerSecond = 1_000
    private static let fractionalUnitsPerYen = UInt32(secondsPerOfflinePulse * millisecondsPerSecond)

    let species: [AnimalSpecies]
    private(set) var balance: Yen = 0
    private(set) var counts: [Int]
    private(set) var highestOwned = 0
    private(set) var meter = 0.0
    private(set) var isReceivingTaps = false
    private(set) var incomePerPulse: Yen = 0
    private(set) var tapMultiplier = 1
    private(set) var offlineEarnings: Yen?
    private var tapBoostUntil: Date?
    private var backgroundBoostUntil: Date?

    var isLit: Bool { isReceivingTaps && meter >= Self.ignitionLevel }
    var isTapBoostActive: Bool { boostRemaining(.tap) > 0 }
    var isBackgroundBoostActive: Bool { boostRemaining(.background) > 0 }
    var totalAnimals: Int {
        counts.reduce(0) { total, count in
            let (sum, overflow) = total.addingReportingOverflow(count)
            return overflow ? Int.max : sum
        }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var fractionalYenUnits: UInt32
    @ObservationIgnored private var active = true
    @ObservationIgnored private var suspendedAt: Date?
    @ObservationIgnored private var tapWindowRemaining = 0.0
    @ObservationIgnored private var saveElapsed = 0.0

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        let date = now()
        let save = Self.readSave(from: defaults)

        var counts = Array(repeating: 0, count: Self.catalog.count)
        counts[0] = 1
        var highestOwned = 0
        if let save {
            for (index, count) in save.counts.prefix(counts.count).enumerated() {
                let owned = max(count, index == 0 ? 1 : 0)
                guard owned > 0 else { break }
                counts[index] = owned
                highestOwned = index
            }
        }

        if let save {
            let adopted = Self.purchasedNames(in: save, count: highestOwned + 1)
            let ownedNames = Set(adopted)
            species = makeAnimalCatalog(names: adopted + AnimalCatalog.names.filter { !ownedNames.contains($0) })
        } else {
            species = Self.catalog
        }
        fractionalYenUnits = min(save?.fractionalYenUnits ?? 0, Self.fractionalUnitsPerYen - 1)
        self.counts = counts
        self.highestOwned = highestOwned
        balance = save?.balance ?? 0
        tapBoostUntil = save?.tapBoostUntil
        backgroundBoostUntil = save?.backgroundBoostUntil
        recalculateIncome()

        if let save, save.earnsOffline == true {
            let isFirstSaveFormat = save.ownedArtIndices == nil && save.legacyPrefixCount == nil
            let rate = isFirstSaveFormat ? Self.legacyIncome(for: counts) : incomePerPulse
            collectOffline(from: save.savedAt, through: date, income: rate)
        }
        checkpoint(at: date)
    }

    #if DEBUG
    static func pileDemoFixture() -> GameModel {
        let suite = UserDefaults(suiteName: "hatsuden.debug.pile-demo")!
        suite.removeObject(forKey: "hatsuden.pile.v1")
        let owned = 38
        let counts = (0..<catalog.count).map { $0 < owned ? 2 + ($0 * 7) % 11 : 0 }
        let save = Save(balance: catalog[owned - 1].cost * 20, counts: counts, savedAt: Date(),
                        ownedArtIndices: catalog.map(\.artIndex))
        suite.set(try! JSONEncoder().encode(save), forKey: saveKey)
        return GameModel(defaults: suite)
    }

    static func stressFixture() -> GameModel {
        let suite = UserDefaults(suiteName: "hatsuden.debug.stress")!
        let date = Date()
        let save = Save(
            balance: 0,
            counts: Array(repeating: 8, count: catalog.count),
            savedAt: date,
            ownedArtIndices: catalog.map(\.artIndex)
        )
        suite.set(try! JSONEncoder().encode(save), forKey: saveKey)
        return GameModel(defaults: suite)
    }
    #endif

    /// Returns one wave if this tap brings the charge to the ignition line.
    /// The scene uses the multiplier from this payout to label its sprites.
    @discardableResult
    func tap() -> Int {
        guard active else { return 0 }
        tapWindowRemaining = Self.tapWindow
        if !isReceivingTaps { isReceivingTaps = true }
        meter = min(1, meter + Self.tapCharge)
        guard meter >= Self.ignitionLevel else { return 0 }
        let multiplier = isTapBoostActive ? 2 : 1
        if tapMultiplier != multiplier { tapMultiplier = multiplier }
        balance += incomePerPulse * UInt64(multiplier)
        return 1
    }

    func update(delta: Double) {
        guard active, delta.isFinite, delta > 0 else { return }
        decayMeter(by: delta)
        if isReceivingTaps {
            tapWindowRemaining = max(0, tapWindowRemaining - delta)
            if tapWindowRemaining == 0 { isReceivingTaps = false }
        }
        saveElapsed += delta
        if saveElapsed >= Self.saveInterval { checkpoint(at: now()) }
    }

    func isUnlocked(_ index: Int) -> Bool {
        guard counts.indices.contains(index) else { return false }
        return index == 0 || counts[index] > 0 || counts[index - 1] > 0
    }

    func price(for index: Int) -> Yen {
        guard counts.indices.contains(index) else { return 0 }
        let animal = species[index]
        let owned = counts[index]
        guard owned > 0 else { return animal.cost }
        // Keep the existing early-game prices, then let extra wheels keep
        // getting more expensive without an ownership cap or Int overflow.
        let base: UInt64 = index == 0 ? 12 : 22
        let step: UInt64 = index == 0 ? 6 : 10
        return animal.income * UInt64(owned) * step + animal.income * base
    }

    func canAfford(_ index: Int) -> Bool {
        guard counts.indices.contains(index), isUnlocked(index), counts[index] < Int.max else { return false }
        return balance >= price(for: index)
    }

    @discardableResult
    func purchase(_ index: Int) -> Bool {
        guard active, canAfford(index) else { return false }
        balance -= price(for: index)
        counts[index] += 1
        highestOwned = max(highestOwned, index)
        recalculateIncome()
        checkpoint(at: now())
        return true
    }

    func boostRemaining(_ kind: BoostKind) -> TimeInterval {
        guard let expiry = boostExpiry(kind) else { return 0 }
        return max(0, expiry.timeIntervalSince(now()))
    }

    /// Call after the reward provider has granted the boost.
    @discardableResult
    func activateBoost(_ kind: BoostKind) -> Bool {
        let date = now()
        if let expiry = boostExpiry(kind), expiry > date { return false }
        if !active, let suspendedAt {
            collectOffline(from: suspendedAt, through: date, income: incomePerPulse)
            self.suspendedAt = date
        }
        let expiry = date + Self.boostDuration
        switch kind {
        case .tap: tapBoostUntil = expiry
        case .background: backgroundBoostUntil = expiry
        }
        checkpoint(at: date)
        return true
    }

    func dismissOfflineEarnings() {
        offlineEarnings = nil
    }

    func loadPileLayout() -> Data? {
        defaults.data(forKey: Self.pileLayoutKey)
    }

    func savePileLayout(_ data: Data) {
        defaults.set(data, forKey: Self.pileLayoutKey)
    }

    func setActive(_ isActive: Bool) {
        guard isActive != active else { return }
        active = isActive
        let currentDate = now()
        if isActive {
            if let suspendedAt {
                decayMeter(by: max(0, currentDate.timeIntervalSince(suspendedAt)))
                collectOffline(from: suspendedAt, through: currentDate, income: incomePerPulse)
            }
            suspendedAt = nil
        } else {
            suspendedAt = currentDate
            tapWindowRemaining = 0
            isReceivingTaps = false
        }
        checkpoint(at: currentDate)
    }

    private func boostExpiry(_ kind: BoostKind) -> Date? {
        switch kind {
        case .tap: tapBoostUntil
        case .background: backgroundBoostUntil
        }
    }

    private func decayMeter(by seconds: Double) {
        guard meter > 0 else { return }
        meter = max(0, meter - seconds * Self.decayPerSecond)
    }

    private func recalculateIncome() {
        incomePerPulse = (0...highestOwned).reduce(0) { sum, index in
            sum + species[index].income * UInt64(counts[index])
        }
    }

    private func collectOffline(from start: Date, through end: Date, income: Yen) {
        let elapsed = end.timeIntervalSince(start)
        guard elapsed.isFinite, elapsed > 0 else { return }
        var boosted: TimeInterval = 0
        if let expiry = backgroundBoostUntil {
            let boostStart = expiry - Self.boostDuration
            boosted = max(0, min(end, expiry).timeIntervalSince(max(start, boostStart)))
        }

        // A millisecond earns 1/120000 of each unit in a normal pulse.
        // Keep the remainder so short absences eventually credit a whole yen.
        let milliseconds = ((elapsed + boosted) * Double(Self.millisecondsPerSecond)).rounded()
        let ticks = UInt64(min(milliseconds, Double(Int64.max)))
        let scaledEarnings = income * ticks + Yen(UInt64(fractionalYenUnits))
        let payout = scaledEarnings.divided(by: Self.fractionalUnitsPerYen)
        fractionalYenUnits = payout.remainder
        balance += payout.whole
        if payout.whole > 0 { offlineEarnings = (offlineEarnings ?? 0) + payout.whole }
    }

    private func checkpoint(at date: Date) {
        let save = Save(balance: balance, counts: counts, savedAt: date,
                        ownedArtIndices: species.prefix(highestOwned + 1).map(\.artIndex),
                        fractionalYenUnits: fractionalYenUnits, earnsOffline: true,
                        tapBoostUntil: tapBoostUntil, backgroundBoostUntil: backgroundBoostUntil)
        if let data = try? JSONEncoder().encode(save) {
            defaults.set(data, forKey: Self.saveKey)
        }
        saveElapsed = 0
    }

    private static func readSave(from defaults: UserDefaults) -> Save? {
        let decoder = JSONDecoder()
        for key in [saveKey, previousSaveKey] {
            if let data = defaults.data(forKey: key), let save = try? decoder.decode(Save.self, from: data) {
                return save
            }
        }
        guard let data = defaults.data(forKey: legacySaveKey),
              let legacy = try? decoder.decode(LegacySave.self, from: data) else { return nil }
        var nonnegative = max(0, legacy.balance)
        var whole: Decimal = 0
        NSDecimalRound(&whole, &nonnegative, 0, .down)
        let fraction = (nonnegative - whole) * Decimal(fractionalUnitsPerYen)
        return Save(balance: yen(from: whole), counts: legacy.counts, savedAt: legacy.savedAt,
                    fractionalYenUnits: NSDecimalNumber(decimal: fraction).uint32Value,
                    earnsOffline: legacy.earnsOffline, tapBoostUntil: legacy.tapBoostUntil,
                    backgroundBoostUntil: legacy.backgroundBoostUntil)
    }

    private static func purchasedNames(in save: Save, count: Int) -> [String] {
        if let indices = save.ownedArtIndices, indices.count == count,
           Set(indices).count == count,
           indices.allSatisfy(AnimalCatalog.legacyNames.indices.contains) {
            return indices.map { AnimalCatalog.legacyNames[$0] }
        }

        // Version 2 stored an old-order prefix length instead of animal IDs.
        let prefixCount = min(AnimalCatalog.legacyNames.count, max(0, save.legacyPrefixCount ?? count))
        let prefix = AnimalCatalog.legacyNames.prefix(prefixCount)
        let oldNames = Set(prefix)
        let previousOrder = Array(prefix) + AnimalCatalog.previousNames.filter { !oldNames.contains($0) }
        return Array(previousOrder.prefix(count))
    }

    private static func legacyIncome(for counts: [Int]) -> Yen {
        let starterIncome: [Double] = [1, 3, 6, 10, 16, 24, 35, 50, 72, 100, 145, 210]
        return counts.enumerated().reduce(0) { sum, entry in
            let (index, count) = entry
            guard count > 0 else { return sum }
            let amount = index < starterIncome.count ? starterIncome[index] :
                floor(210 * pow(1.34, Double(index - starterIncome.count + 1)))
            let decimal = Decimal(string: String(amount)) ?? 0
            return sum + yen(from: decimal) * UInt64(count)
        }
    }

    private static func yen(from whole: Decimal) -> Yen {
        let digits = whole.formatted(.number.locale(Locale(identifier: "en_US_POSIX"))
            .grouping(.never).precision(.fractionLength(0)))
        return Yen(digits) ?? 0
    }

    private struct Save: Codable {
        let balance: Yen
        let counts: [Int]
        let savedAt: Date
        var ownedArtIndices: [Int]? = nil
        var legacyPrefixCount: Int? = nil
        var fractionalYenUnits: UInt32? = nil
        var earnsOffline: Bool? = nil
        var tapBoostUntil: Date? = nil
        var backgroundBoostUntil: Date? = nil
    }

    private struct LegacySave: Decodable {
        let balance: Decimal
        let counts: [Int]
        let savedAt: Date
        var earnsOffline: Bool?
        var tapBoostUntil: Date?
        var backgroundBoostUntil: Date?
    }
}

private func makeAnimalCatalog(names: [String]) -> [AnimalSpecies] {
    var income: Yen = 1
    return names.enumerated().map { index, name in
        // Each newly unlocked species earns nine times one prior-species
        // animal. Extra wheels remain available at every earlier stage.
        let previousIncome = income
        if index > 0 { income = income * 9 }
        let priceFactor: UInt64
        switch index {
        case 0: priceFactor = 0
        case 1: priceFactor = 1_920
        case 2: priceFactor = 2_000
        default: priceFactor = UInt64(min(4_500, max(2_040, 1_950 + 15 * index)))
        }
        return AnimalSpecies(index: index, artIndex: AnimalCatalog.artIndexByName[name]!, name: name,
                             cost: previousIncome * priceFactor, income: income)
    }
}
