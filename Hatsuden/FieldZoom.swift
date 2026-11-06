import CoreGraphics

/// Positions the world inside the fixed field viewport in SpriteKit coordinates.
struct FieldZoom: Equatable {
    static let overview = FieldZoom(scale: 1, offset: .zero)
    static let maximumScale: CGFloat = 12

    let scale: CGFloat
    let offset: CGPoint

    func magnified(by factor: CGFloat, from start: CGPoint, to destination: CGPoint, viewport: CGSize) -> FieldZoom {
        guard factor.isFinite, factor > 0, viewport.width > 0, viewport.height > 0 else { return self }
        let nextScale = min(max(scale * factor, 1), Self.maximumScale)
        let ratio = nextScale / scale
        let x = destination.x - (start.x - offset.x) * ratio
        let y = destination.y - (start.y - offset.y) * ratio
        return FieldZoom(
            scale: nextScale,
            offset: CGPoint(
                x: min(0, max(viewport.width * (1 - nextScale), x)),
                y: min(0, max(viewport.height * (1 - nextScale), y))
            )
        )
    }

    func point(_ worldPoint: CGPoint) -> CGPoint {
        CGPoint(x: worldPoint.x * scale + offset.x, y: worldPoint.y * scale + offset.y)
    }

    func interpolatedToOverview(progress: CGFloat) -> FieldZoom {
        let remaining = 1 - progress
        return FieldZoom(
            scale: 1 + (scale - 1) * remaining,
            offset: CGPoint(x: offset.x * remaining, y: offset.y * remaining)
        )
    }

    func resized(from oldSize: CGSize, to newSize: CGSize) -> FieldZoom {
        guard oldSize.width > 0, oldSize.height > 0, newSize.width > 0, newSize.height > 0 else { return self }
        return FieldZoom(
            scale: scale,
            offset: CGPoint(x: offset.x / oldSize.width * newSize.width, y: offset.y / oldSize.height * newSize.height)
        )
    }
}
