import CoreGraphics
import Foundation

/// Wheel diameters are gameplay geometry, separate from the catalog's body-size
/// estimates shown in the shop. Respect the saved order even in migrated games.
struct PileWheelSizes {
    let diameters: [CGFloat]

    init(species: [AnimalSpecies], starterDiameter: CGFloat = 64) {
        self.init(names: species.map(\.name), starterDiameter: starterDiameter)
    }

    init(names: [String], starterDiameter: CGFloat = 64) {
        let starter = starterDiameter.isFinite && starterDiameter > 0 ? starterDiameter : 64
        let firstBodySize = max(0.001, AnimalCatalog.sizeByName[names.first ?? ""] ?? 1)
        var sizes: [CGFloat] = []
        sizes.reserveCapacity(names.count)
        for name in names {
            guard let previous = sizes.last else {
                sizes.append(starter)
                continue
            }
            let bodySize = AnimalCatalog.sizeByName[name] ?? Double(previous / starter) * firstBodySize
            let desired = CGFloat(bodySize / firstBodySize) * starter
            // Close-sized animals still get distinct wheels. Limit adjacent jumps
            // to 3x so the final fictional species cannot erase the pile in one
            // 200x pullback; the shop's biological size label remains unchanged.
            sizes.append(min(previous * 3, max(previous * 1.03, desired)))
        }
        diameters = sizes
    }

    subscript(index: Int) -> CGFloat {
        guard diameters.indices.contains(index) else { return diameters.first ?? 64 }
        return diameters[index]
    }
}
