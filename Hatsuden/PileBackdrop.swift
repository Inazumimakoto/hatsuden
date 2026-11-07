import SpriteKit
import UIKit

/// One fixed illustration behind the pile. The camera projects the artwork's
/// world rectangles exactly as it projects wheels; ranks never select scenes.
@MainActor
final class PileBackdrop {
    static let referenceSize = CGSize(width: 240, height: 400)
    static let referenceBounds = CGRect(x: -240, y: 0, width: 240, height: 400)

    let node = SKNode()
    let markWorldFrames: [FieldMotif: CGRect]
    let detailWorldFrames: [Int: CGRect]
    private(set) var markFrames: [FieldMotif: CGRect] = [:]
    private(set) var detailFrames: [Int: CGRect] = [:]
    private(set) var referenceFrame = CGRect.zero

    private let art = FieldArtwork()
    private let canvas = FieldCanvas()
    private let paper: CanvasPaper
    private let stretch: Double
    private var marks: [FieldMotif: SKSpriteNode] = [:]
    private var details: [Int: SKSpriteNode] = [:]
    private var lastCamera: PileCamera?

    init(sizes: PileWheelSizes) {
        let firstDiameter = max(0.001, sizes.diameters.first ?? 64)
        let largestDiameter = max(firstDiameter * 2, sizes.diameters.last ?? firstDiameter * 2)
        let compressedDepth = log2(Double(largestDiameter / firstDiameter)) / 99.5
        stretch = compressedDepth
        let field = FieldCanvas()
        markWorldFrames = Dictionary(uniqueKeysWithValues: field.marks.map { mark in
            (mark.motif, Self.worldFrame(mark.frame(in: Self.referenceSize, at: mark.depth),
                                         depth: mark.depth, stretch: compressedDepth))
        })
        detailWorldFrames = Dictionary(uniqueKeysWithValues: field.details.map { detail in
            (detail.id, Self.worldFrame(detail.frame(in: Self.referenceSize, at: detail.depth),
                                       depth: detail.depth, stretch: compressedDepth))
        })
        paper = CanvasPaper(texture: art.customBackground)
        node.name = "pile-backdrop"
        paper.node.zPosition = 0
        node.addChild(paper.node)
    }

    func project(camera: PileCamera) {
        guard lastCamera != camera else { return }
        lastCamera = camera
        paper.projectPile(camera: camera, referenceSize: Self.referenceSize, depthStretch: stretch)
        referenceFrame = screenFrame(Self.referenceBounds, camera: camera)
        guard art.customBackground == nil else { return }

        // Keep a small apron outside the screen so a pan does not repeatedly
        // attach and detach an illustration touching the edge.
        let viewport = CGRect(origin: .zero, size: camera.viewport).insetBy(dx: -8, dy: -8)
        projectDetails(camera: camera, viewport: viewport)
        projectMarks(camera: camera, viewport: viewport)
    }

    private func projectMarks(camera: PileCamera, viewport: CGRect) {
        var visibleNodes: [FieldMotif: SKSpriteNode] = [:]
        var visibleFrames: [FieldMotif: CGRect] = [:]
        for (index, mark) in canvas.marks.enumerated() {
            guard let world = markWorldFrames[mark.motif] else { continue }
            let frame = screenFrame(world, camera: camera)
            guard frame.intersects(viewport), max(frame.width, frame.height) >= 0.5 else { continue }
            let sprite = marks.removeValue(forKey: mark.motif) ?? SKSpriteNode(texture: art.texture(for: mark.motif))
            if sprite.parent == nil { node.addChild(sprite) }
            sprite.zPosition = 0.1 + CGFloat(index + 1) * 0.001
            sprite.position = CGPoint(x: frame.midX, y: frame.midY)
            sprite.size = frame.size
            visibleNodes[mark.motif] = sprite
            visibleFrames[mark.motif] = frame
        }
        for sprite in marks.values { sprite.removeFromParent() }
        marks = visibleNodes
        markFrames = visibleFrames
    }

    private func projectDetails(camera: PileCamera, viewport: CGRect) {
        var visibleNodes: [Int: SKSpriteNode] = [:]
        var visibleFrames: [Int: CGRect] = [:]
        for detail in canvas.details {
            guard let world = detailWorldFrames[detail.id] else { continue }
            let frame = screenFrame(world, camera: camera)
            let extent = max(frame.width, frame.height)
            guard extent >= 3, frame.intersects(viewport) else { continue }
            let sprite = details.removeValue(forKey: detail.id) ?? SKSpriteNode(texture: art.texture(for: detail))
            if sprite.parent == nil { node.addChild(sprite) }
            sprite.zPosition = 0.01 + CGFloat(detail.id) / 1_000_000
            sprite.position = CGPoint(x: frame.midX, y: frame.midY)
            sprite.size = frame.size
            sprite.alpha = min(1, (extent - 3) / 4)
            visibleNodes[detail.id] = sprite
            visibleFrames[detail.id] = frame
        }
        for sprite in details.values { sprite.removeFromParent() }
        details = visibleNodes
        detailFrames = visibleFrames
    }

    private func screenFrame(_ world: CGRect, camera: PileCamera) -> CGRect {
        CGRect(origin: camera.screenPoint(fromWorld: world.origin),
               size: CGSize(width: world.width * camera.scale, height: world.height * camera.scale))
    }

    private static func worldFrame(_ local: CGRect, depth: Double, stretch: Double) -> CGRect {
        let scale = CGFloat(exp2(depth * stretch))
        return CGRect(x: (local.minX - referenceSize.width) * scale,
                      y: local.minY * scale, width: local.width * scale, height: local.height * scale)
    }
}
