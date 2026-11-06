import CoreGraphics
import Foundation

/// All rectangles are in screen order, with their origin at the upper left.
struct StaircaseLayout {
    struct Partition {
        let tiles: [Int: CGRect]
        let collapsedThrough: Int?
        let dot: CGPoint

        func rect(for species: Int) -> CGRect? {
            if let tile = tiles[species] {
                return tile
            }
            if let collapsedThrough, species <= collapsedThrough {
                return CGRect(origin: dot, size: .zero)
            }
            return nil
        }
    }

    let partition: Partition
    private let previousTail: Partition?
    private let progress: CGFloat
    private let fraction: CGFloat

    init(bounds: CGRect, topSpeciesFloat: Double, highestOwned: Int, pixelSize: CGFloat) {
        let zoom = min(max(topSpeciesFloat, 0), Double(highestOwned))
        let previousTop = Int(zoom.rounded(.down))
        let fraction = CGFloat(zoom - Double(previousTop))
        self.fraction = fraction
        let top = fraction == 0 ? previousTop : previousTop + 1

        partition = Self.partition(
            bounds: bounds,
            startingAt: top,
            firstRatio: fraction == 0 ? 0.5 : fraction * 0.5,
            pixelSize: pixelSize
        )

        // At an integer boundary the first old cut changes from top to left.
        // Blend the runners through both valid tilings of the same remainder.
        if fraction > 0 {
            let topHeight = bounds.height * fraction * 0.5
            let tail = CGRect(x: bounds.minX, y: bounds.minY + topHeight,
                              width: bounds.width, height: bounds.height - topHeight)
            previousTail = Self.partition(
                bounds: tail, startingAt: previousTop, firstRatio: 0.5, pixelSize: pixelSize
            )
        } else {
            previousTail = nil
        }
        progress = fraction * fraction * (3 - 2 * fraction)
    }

    func cell(for species: Int, slot: Int) -> CGRect? {
        guard let tile = partition.rect(for: species) else { return nil }
        guard let previousTail else { return Self.cell(in: tile, slot: slot) }
        guard let oldTile = previousTail.rect(for: species) else {
            return transitionCell(in: tile, slot: slot, entering: true)
        }
        let destination = transitionCell(in: tile, slot: slot, entering: false)
        let origin = transitionCell(in: oldTile, slot: slot, entering: false)
        return Self.blend(from: origin, to: destination, progress: progress)
    }

    /// Leave space between the wheels in neighboring slots.
    static func wheelDiameter(in cell: CGRect) -> CGFloat {
        max(0, min(cell.width, cell.height) * 0.90)
    }

    static func usesPixelDot(in cell: CGRect, pixelSize: CGFloat) -> Bool {
        wheelDiameter(in: cell) <= pixelSize
    }

    func isCollapsed(_ species: Int) -> Bool {
        guard let end = partition.collapsedThrough, species <= end else { return false }
        guard let previousTail, progress < 1 else { return true }
        return previousTail.collapsedThrough.map { species <= $0 } ?? false
    }

    static func cell(in tile: CGRect, slot: Int) -> CGRect {
        cell(in: tile, slot: slot, isWide: tile.width > tile.height * 1.1)
    }

    private func transitionCell(in tile: CGRect, slot: Int, entering: Bool) -> CGRect {
        guard tile.width > 0, tile.height > 0 else { return Self.cell(in: tile, slot: slot) }

        // The entering tile grows linearly; its old neighbors share the
        // linearly shrinking remainder. Interpolate only near the aspect
        // ratio at which a grid changes direction during that transition.
        let threshold: CGFloat
        if entering {
            threshold = tile.width / (tile.height / fraction * 1.1)
            guard threshold > 0, threshold <= 1 else { return Self.cell(in: tile, slot: slot) }
        } else {
            let startHeight = tile.height / (1 - fraction * 0.5)
            threshold = 2 * (1 - tile.width / (startHeight * 1.1))
            guard threshold >= 0, threshold < 1 else { return Self.cell(in: tile, slot: slot) }
        }
        let start = max(0, threshold - 0.06)
        let end = min(1, threshold + 0.06)
        let time = min(1, max(0, (fraction - start) / (end - start)))
        let easing = time * time * (3 - 2 * time)
        let tall = Self.cell(in: tile, slot: slot, isWide: false)
        let wide = Self.cell(in: tile, slot: slot, isWide: true)
        return Self.blend(from: tall, to: wide, progress: entering ? 1 - easing : easing)
    }

    private static func blend(from origin: CGRect, to destination: CGRect, progress: CGFloat) -> CGRect {
        CGRect(
            x: origin.minX + (destination.minX - origin.minX) * progress,
            y: origin.minY + (destination.minY - origin.minY) * progress,
            width: origin.width + (destination.width - origin.width) * progress,
            height: origin.height + (destination.height - origin.height) * progress
        )
    }

    private static func cell(in tile: CGRect, slot: Int, isWide: Bool) -> CGRect {
        let columns = isWide ? 4 : 2
        let rows = isWide ? 2 : 4
        let width = tile.width / CGFloat(columns)
        let height = tile.height / CGFloat(rows)
        return CGRect(
            x: tile.minX + CGFloat(slot % columns) * width,
            y: tile.minY + CGFloat(slot / columns) * height,
            width: width, height: height
        )
    }

    private static func partition(
        bounds: CGRect, startingAt top: Int, firstRatio: CGFloat, pixelSize: CGFloat
    ) -> Partition {
        var tiles: [Int: CGRect] = [:]
        var remainder = bounds
        let dot = CGPoint(x: bounds.maxX - pixelSize / 2, y: bounds.maxY - pixelSize / 2)

        for species in stride(from: top, through: 0, by: -1) {
            if remainder.width < pixelSize * 0.8 && remainder.height < pixelSize * 0.8 {
                return Partition(tiles: tiles, collapsedThrough: species, dot: dot)
            }
            if species == 0 {
                tiles[species] = remainder
                break
            }

            let depth = top - species
            let ratio = depth == 0 ? firstRatio : 0.5
            if depth.isMultiple(of: 2) {
                let height = remainder.height * ratio
                tiles[species] = CGRect(x: remainder.minX, y: remainder.minY,
                                        width: remainder.width, height: height)
                remainder.origin.y += height
                remainder.size.height -= height
            } else {
                let width = remainder.width * ratio
                tiles[species] = CGRect(x: remainder.minX, y: remainder.minY,
                                        width: width, height: remainder.height)
                remainder.origin.x += width
                remainder.size.width -= width
            }
        }
        return Partition(tiles: tiles, collapsedThrough: nil, dot: dot)
    }
}

/// A single picture is magnified around its lower-right corner in scene coordinates.
enum FieldCamera {
    static func artworkFrame(in viewport: CGRect, topSpecies: Double, lastSpecies: Int) -> CGRect {
        guard lastSpecies > 0 else { return viewport }
        let progress = min(1, max(0, topSpecies / Double(lastSpecies)))
        guard progress < 1 else { return viewport }

        // Spend more of the visible camera movement on the early unlocks,
        // but keep revealing a little more of the picture through the final tier.
        let reveal = log1p(9 * progress) / log(10)
        let scale = CGFloat(pow(12, 1 - reveal))
        let width = viewport.width * scale
        let height = viewport.height * scale
        return CGRect(x: viewport.maxX - width, y: viewport.minY, width: width, height: height)
    }
}
