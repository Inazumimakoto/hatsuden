import CoreGraphics
import Foundation

/// Magnification around the lower-right corner of the field.
struct FieldZoom: Equatable {
    static let overview = FieldZoom(scale: 1)

    let scale: CGFloat

    func magnified(by factor: CGFloat, highestOwned: Int) -> FieldZoom {
        guard factor.isFinite, factor > 0 else { return self }
        // Each pair of staircase cuts halves the starter tile in both axes.
        let depth = CGFloat(highestOwned / 2)
        let limit = pow(2, depth)
        let sensitivity = max(1, depth / 8)
        return FieldZoom(scale: min(max(scale * pow(factor, sensitivity), 1), limit))
    }

    func interpolatedToOverview(progress: CGFloat) -> FieldZoom {
        FieldZoom(scale: pow(scale, 1 - progress))
    }
}
