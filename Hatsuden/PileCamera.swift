import CoreGraphics
import Foundation

/// A camera over the pile's world, using SpriteKit's upward-positive axes.
/// `scale` is screen points per world unit; `center` is a world position.
struct PileCamera: Equatable {
    private(set) var worldBounds: CGRect
    private(set) var viewport: CGSize
    private(set) var center: CGPoint
    private(set) var scale: CGFloat
    let smallestWheelDiameter: CGFloat
    let overviewPadding: CGFloat

    init(worldBounds: CGRect, viewport: CGSize, smallestWheelDiameter: CGFloat = 64,
         overviewPadding: CGFloat = 10) {
        self.worldBounds = Self.validBounds(worldBounds)
        self.viewport = Self.validViewport(viewport)
        self.smallestWheelDiameter = smallestWheelDiameter.isFinite && smallestWheelDiameter > 0
            ? smallestWheelDiameter : 64
        self.overviewPadding = overviewPadding.isFinite ? max(0, overviewPadding) : 10
        center = CGPoint(x: self.worldBounds.midX, y: self.worldBounds.midY)
        scale = 1
        reset()
    }

    var overviewScale: CGFloat {
        let padding = min(overviewPadding, min(viewport.width, viewport.height) * 0.1)
        return min((viewport.width - padding * 2) / worldBounds.width,
                   (viewport.height - padding * 2) / worldBounds.height)
    }

    /// The zoom ceiling follows the smallest wheel, rather than the newest rank.
    /// Even after a large expansion, the original insects can fill most of the view.
    var maximumScale: CGFloat {
        max(overviewScale, min(viewport.width, viewport.height) * 0.72 / smallestWheelDiameter)
    }

    var isOverview: Bool {
        abs(scale / overviewScale - 1) < 0.000_01
    }

    var visibleWorldBounds: CGRect {
        let width = viewport.width / scale
        let height = viewport.height / scale
        return CGRect(x: center.x - width / 2, y: center.y - height / 2,
                      width: width, height: height)
    }

    func screenPoint(fromWorld point: CGPoint) -> CGPoint {
        CGPoint(x: viewport.width / 2 + (point.x - center.x) * scale,
                y: viewport.height / 2 + (point.y - center.y) * scale)
    }

    func worldPoint(fromScreen point: CGPoint) -> CGPoint {
        CGPoint(x: center.x + (point.x - viewport.width / 2) / scale,
                y: center.y + (point.y - viewport.height / 2) / scale)
    }

    /// `factor` is relative to this camera. Apply the gesture's incremental factor.
    /// The world point underneath the fingers stays there while the camera zooms.
    mutating func magnify(by factor: CGFloat, at anchor: CGPoint) {
        guard factor.isFinite, factor > 0, Self.finite(anchor) else { return }
        let anchoredWorld = worldPoint(fromScreen: anchor)
        scale = min(maximumScale, max(overviewScale, scale * factor))
        center = CGPoint(x: anchoredWorld.x - (anchor.x - viewport.width / 2) / scale,
                         y: anchoredWorld.y - (anchor.y - viewport.height / 2) / scale)
        clampCenter()
    }

    /// Move the picture with the fingers. Translation is in screen points.
    mutating func pan(by translation: CGPoint) {
        guard Self.finite(translation) else { return }
        center.x -= translation.x / scale
        center.y -= translation.y / scale
        clampCenter()
    }

    /// Apply a two-finger gesture in one step, including movement of its midpoint.
    mutating func gesture(from previousMidpoint: CGPoint, to midpoint: CGPoint, factor: CGFloat) {
        guard Self.finite(previousMidpoint), Self.finite(midpoint), factor.isFinite, factor > 0 else { return }
        let anchoredWorld = worldPoint(fromScreen: previousMidpoint)
        scale = min(maximumScale, max(overviewScale, scale * factor))
        center = CGPoint(x: anchoredWorld.x - (midpoint.x - viewport.width / 2) / scale,
                         y: anchoredWorld.y - (midpoint.y - viewport.height / 2) / scale)
        clampCenter()
    }

    mutating func reset() {
        scale = overviewScale
        center = CGPoint(x: worldBounds.midX, y: worldBounds.midY)
    }

    mutating func resize(viewport: CGSize) {
        let wasOverview = isOverview
        self.viewport = Self.validViewport(viewport)
        if wasOverview {
            reset()
        } else {
            scale = min(maximumScale, max(overviewScale, scale))
            clampCenter()
        }
    }

    /// Expanding a box can retain a player's close-up. The caller can instead
    /// request an overview for the animated arrival of a larger wheel.
    mutating func updateWorldBounds(_ bounds: CGRect, preserveView: Bool = true) {
        worldBounds = Self.validBounds(bounds)
        if preserveView {
            scale = min(maximumScale, max(overviewScale, scale))
            clampCenter()
        } else {
            reset()
        }
    }

    /// Suitable for a camera pullback: magnification changes at a constant ratio.
    func interpolated(to target: PileCamera, progress: CGFloat) -> PileCamera {
        let amount = progress.isFinite ? min(1, max(0, progress)) : 0
        if amount == 0 { return self }
        if amount == 1 { return target }
        var result = target
        result.center = CGPoint(x: center.x + (target.center.x - center.x) * amount,
                                y: center.y + (target.center.y - center.y) * amount)
        result.scale = exp(log(scale) + (log(target.scale) - log(scale)) * amount)
        return result
    }

    private mutating func clampCenter() {
        let halfWidth = viewport.width / (scale * 2)
        let halfHeight = viewport.height / (scale * 2)
        center.x = Self.clampedCoordinate(center.x, minimum: worldBounds.minX,
                                          maximum: worldBounds.maxX, halfExtent: halfWidth)
        center.y = Self.clampedCoordinate(center.y, minimum: worldBounds.minY,
                                          maximum: worldBounds.maxY, halfExtent: halfHeight)
    }

    private static func clampedCoordinate(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat,
                                          halfExtent: CGFloat) -> CGFloat {
        guard maximum - minimum > halfExtent * 2 else { return (minimum + maximum) / 2 }
        return min(maximum - halfExtent, max(minimum + halfExtent, value))
    }

    private static func finite(_ point: CGPoint) -> Bool {
        point.x.isFinite && point.y.isFinite
    }

    private static func validBounds(_ bounds: CGRect) -> CGRect {
        guard finite(bounds.origin), bounds.width.isFinite, bounds.height.isFinite,
              bounds.width > 0, bounds.height > 0 else {
            return CGRect(x: 0, y: 0, width: 320, height: 600)
        }
        return bounds
    }

    private static func validViewport(_ viewport: CGSize) -> CGSize {
        CGSize(width: viewport.width.isFinite ? max(1, viewport.width) : 1,
               height: viewport.height.isFinite ? max(1, viewport.height) : 1)
    }
}
