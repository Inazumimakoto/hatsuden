import SpriteKit
import UIKit

@MainActor
final class ArtProvider {
    static let shared = ArtProvider()

    private var wheel: SKTexture?
    private let animalImages: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()
    private let animals: NSCache<NSNumber, SKTexture> = {
        let cache = NSCache<NSNumber, SKTexture>()
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()
    private let silhouettes: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 72
        return cache
    }()
    private let sleepingAnimals: NSCache<NSNumber, SKTexture> = {
        let cache = NSCache<NSNumber, SKTexture>()
        cache.totalCostLimit = 20 * 1024 * 1024
        return cache
    }()
    private var customAnimalArt: Set<Int> = []
    private let runningCycles: NSCache<NSNumber, RunningCycle> = {
        let cache = NSCache<NSNumber, RunningCycle>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()
    private var money: [String: SKTexture] = [:]
    private var preparedMoneyPages: Set<Int> = []
    private var glyphs: [Character: UIImage] = [:]
    private var missingGlyphs: Set<Character> = []

    func wheelTexture() -> SKTexture {
        if let wheel { return wheel }
        let image = UIImage(named: "wheel") ?? Self.illustration(FallbackArt.wheel)
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        wheel = texture
        return texture
    }

    func animalImage(index: Int) -> UIImage {
        let key = NSNumber(value: index)
        if let image = animalImages.object(forKey: key) { return image }
        let image: UIImage
        if let drawing = UIImage(named: Self.animalAssetKey(index: index)) {
            customAnimalArt.insert(index)
            image = drawing
        } else {
            image = Self.illustration { FallbackArt.animal(index: index, ink: $0) }
        }
        animalImages.setObject(image, forKey: key, cost: Self.textureBytes(image))
        return image
    }

    func animalTexture(index: Int) -> SKTexture {
        let key = NSNumber(value: index)
        if let texture = animals.object(forKey: key) { return texture }
        let image = animalImage(index: index)
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        animals.setObject(texture, forKey: key, cost: Self.textureBytes(image))
        return texture
    }

    func silhouetteImage(index: Int) -> UIImage {
        let key = NSNumber(value: index)
        if let image = silhouettes.object(forKey: key) { return image }

        let size = CGSize(width: 96, height: 96)
        let image = Self.renderer(size: size, scale: 1).image { renderer in
            if let custom = UIImage(named: Self.animalAssetKey(index: index)) {
                custom.draw(in: CGRect(origin: .zero, size: size))
            } else {
                let context = renderer.cgContext
                context.scaleBy(x: size.width / 240, y: size.height / 240)
                FallbackArt.animal(index: index, ink: CrayonCanvas(context: context, solid: true))
            }
        }
        silhouettes.setObject(image, forKey: key)
        return image
    }

    func sleepingTexture(index: Int) -> SKTexture {
        let key = NSNumber(value: index)
        if let texture = sleepingAnimals.object(forKey: key) { return texture }

        let image: UIImage
        if let customSleep = UIImage(named: Self.animalAssetKey(index: index) + "_sleep") {
            image = customSleep
        } else {
            let rest = animalImage(index: index)
            if customAnimalArt.contains(index) {
                image = Self.illustration { ink in
                    rest.draw(in: CGRect(x: 0, y: 0, width: 240, height: 240))
                    FallbackArt.sleepMark(ink, x: 171, y: 54, size: 13)
                    FallbackArt.sleepMark(ink, x: 193, y: 37, size: 15)
                }
            } else {
                image = Self.illustration { FallbackArt.animal(index: index, ink: $0, asleep: true) }
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        sleepingAnimals.setObject(texture, forKey: key, cost: Self.textureBytes(image))
        return texture
    }

    func runningTexture(index: Int, frame: Int) -> SKTexture {
        let key = NSNumber(value: index)
        if let cycle = runningCycles.object(forKey: key) { return cycle.frames[frame] }

        let assetKey = Self.animalAssetKey(index: index)
        let resting = animalImage(index: index)
        let customFrames = (1...4).map { number in
            UIImage(named: assetKey + "_run_0\(number)")
        }
        let hasCustomFrames = customFrames.contains { $0 != nil }
        let hasCustomRest = customAnimalArt.contains(index)
        if hasCustomRest && !hasCustomFrames {
            let texture = animalTexture(index: index)
            runningCycles.setObject(RunningCycle(frames: Array(repeating: texture, count: 4)), forKey: key)
            return texture
        }

        // A shared backing image lets SpriteKit batch animals in different poses.
        // Leave a transparent gutter between frames for linear texture sampling.
        let side: CGFloat = 240
        let pitch = side + 4
        let atlasSize = CGSize(width: pitch * 2, height: pitch * 2)
        let scale: CGFloat = hasCustomFrames ? 2 : 1
        let frameRects = (0..<4).map { slot in
            CGRect(x: CGFloat(slot % 2) * pitch + 2, y: CGFloat(slot / 2) * pitch + 2,
                   width: side, height: side)
        }
        let atlasImage = Self.renderer(size: atlasSize, scale: scale).image { renderer in
            for (slot, rect) in frameRects.enumerated() {
                if let custom = customFrames[slot] {
                    custom.draw(in: rect)
                } else if hasCustomRest {
                    resting.draw(in: rect)
                } else if let firstCustom = customFrames.compactMap({ $0 }).first {
                    firstCustom.draw(in: rect)
                } else {
                    let context = renderer.cgContext
                    context.saveGState()
                    context.translateBy(x: rect.minX, y: rect.minY)
                    FallbackArt.animal(index: index, ink: CrayonCanvas(context: context), runFrame: slot)
                    context.restoreGState()
                }
            }
        }
        let atlas = SKTexture(image: atlasImage)
        atlas.filteringMode = .linear
        let frames = frameRects.map { rect in
            let uv = CGRect(x: rect.minX / atlasSize.width,
                            y: 1 - rect.maxY / atlasSize.height,
                            width: rect.width / atlasSize.width,
                            height: rect.height / atlasSize.height)
            let texture = SKTexture(rect: uv, in: atlas)
            texture.filteringMode = .linear
            return texture
        }
        let cost = Int(atlasSize.width * atlasSize.height * scale * scale) * 4
        runningCycles.setObject(RunningCycle(frames: frames), forKey: key, cost: cost)
        return frames[frame]
    }

    private final class RunningCycle {
        let frames: [SKTexture]

        init(frames: [SKTexture]) {
            self.frames = frames
        }
    }

    private static func animalAssetKey(index: Int) -> String {
        String(format: "animal_%03d", index + 1)
    }

    func moneyTexture(index: Int, amount: Yen) -> SKTexture {
        let label = "+" + Currency.compact(amount)
        if let texture = money[label] { return texture }
        prepareMoneyPage(index / Self.moneyPageSize)
        if let texture = money[label] { return texture }

        // Custom amounts can use the same renderer without rebuilding the atlas.
        let drawing = moneyDrawing(label)
        let image = Self.renderer(size: drawing.size).image { _ in drawing.paint(.zero) }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        money[label] = texture
        return texture
    }

    private static let moneyPageSize = 32

    private func prepareMoneyPage(_ page: Int) {
        guard preparedMoneyPages.insert(page).inserted else { return }
        let start = page * Self.moneyPageSize
        let end = min(start + Self.moneyPageSize, GameModel.catalog.count)
        guard start < end else { return }

        var labels: [String] = []
        var seen: Set<String> = []
        for species in GameModel.catalog[start..<end] {
            for amount in [species.income, species.income * 2] {
                let label = "+" + Currency.compact(amount)
                if money[label] == nil, seen.insert(label).inserted { labels.append(label) }
            }
        }
        guard !labels.isEmpty else { return }

        // Retain distinct amount textures that share one backing image. Transparent
        // gutters prevent bilinear sampling of the next label at a subtexture edge.
        let columns = 8
        let drawings = labels.map(moneyDrawing)
        let stride = CGSize(width: (drawings.map(\.size.width).max() ?? 0) + 2, height: 22)
        let atlasSize = CGSize(
            width: stride.width * CGFloat(min(columns, drawings.count)),
            height: stride.height * CGFloat((drawings.count + columns - 1) / columns)
        )
        var rects: [CGRect] = []
        let image = Self.renderer(size: atlasSize).image { _ in
            for (slot, drawing) in drawings.enumerated() {
                let origin = CGPoint(x: CGFloat(slot % columns) * stride.width + 1,
                                     y: CGFloat(slot / columns) * stride.height + 1)
                drawing.paint(origin)
                rects.append(CGRect(origin: origin, size: drawing.size))
            }
        }
        let atlas = SKTexture(image: image)
        atlas.filteringMode = .linear
        for (label, rect) in zip(labels, rects) {
            let uv = CGRect(x: rect.minX / atlasSize.width,
                            y: 1 - rect.maxY / atlasSize.height,
                            width: rect.width / atlasSize.width,
                            height: rect.height / atlasSize.height)
            let texture = SKTexture(rect: uv, in: atlas)
            texture.filteringMode = .linear
            money[label] = texture
        }
    }

    private struct MoneyDrawing {
        let size: CGSize
        let paint: (CGPoint) -> Void
    }

    private func moneyDrawing(_ label: String) -> MoneyDrawing {
        let font = UIFont(name: "ChalkboardSE-Bold", size: 14)
            ?? UIFont(name: "MarkerFelt-Wide", size: 14)
            ?? .roundedSystemFont(ofSize: 14)
        let colors = FallbackArt.Colors.self
        let text: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(cgColor: colors.lightYellow)]
        let outline: [NSAttributedString.Key: Any] = [
            .font: font,
            .strokeColor: UIColor(cgColor: colors.ink),
            .strokeWidth: -10,
            .foregroundColor: UIColor(cgColor: colors.lightYellow)
        ]
        let images = label.map(glyph)
        let height: CGFloat = 20
        let baselineOffset = (height - font.lineHeight) / 2 - 0.5

        if images.allSatisfy({ $0 == nil }) {
            let string = label as NSString
            let width = ceil(string.size(withAttributes: text).width) + 6
            return MoneyDrawing(size: CGSize(width: width, height: height)) { origin in
                let point = CGPoint(x: origin.x + 3, y: origin.y + baselineOffset)
                string.draw(at: point, withAttributes: outline)
            }
        }

        let characters = label.map { String($0) as NSString }
        let advance = zip(characters, images).map { string, image -> CGFloat in
            guard let image else { return ceil(string.size(withAttributes: text).width) }
            return min(32, 14 * image.size.width / max(1, image.size.height))
        }
        let width = ceil(advance.reduce(0, +)) + 6
        return MoneyDrawing(size: CGSize(width: width, height: height)) { origin in
            var x = origin.x + 3
            for i in characters.indices {
                if let image = images[i] {
                    let size = CGSize(width: advance[i], height: 14)
                    image.draw(in: CGRect(origin: CGPoint(x: x, y: origin.y + 3), size: size))
                } else {
                    characters[i].draw(at: CGPoint(x: x, y: origin.y + baselineOffset), withAttributes: outline)
                }
                x += advance[i]
            }
        }
    }

    private func glyph(_ character: Character) -> UIImage? {
        if let image = glyphs[character] { return image }
        guard !missingGlyphs.contains(character) else { return nil }
        let names: [String]
        switch character {
        case "0"..."9": names = ["digit_\(character)"]
        case "+": names = ["digit_plus"]
        case ".": names = ["digit_dot", "digit_decimal"]
        case "-": names = ["digit_minus"]
        default: names = ["unit_\(character)", "digit_\(character)"]
        }
        if let image = names.lazy.compactMap({ UIImage(named: $0) }).first {
            glyphs[character] = image
            return image
        }
        missingGlyphs.insert(character)
        return nil
    }

    private static func renderer(size: CGSize, scale: CGFloat = 2) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format)
    }

    private static func textureBytes(_ image: UIImage) -> Int {
        Int(image.size.width * image.size.height * image.scale * image.scale) * 4
    }

    private static func illustration(_ paint: (CrayonCanvas) -> Void) -> UIImage {
        renderer(size: CGSize(width: 240, height: 240)).image { renderer in
            paint(CrayonCanvas(context: renderer.cgContext))
        }
    }
}

private extension UIFont {
    static func roundedSystemFont(ofSize size: CGFloat) -> UIFont {
        let bold = systemFont(ofSize: size, weight: .bold)
        guard let descriptor = bold.fontDescriptor.withDesign(.rounded) else { return bold }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// The crayon geometry only depends on Core Graphics so the app icon and
// in-game hamster can share the same drawing.
struct CrayonCanvas {
    let context: CGContext
    var solid = false

    static func color(_ rgb: UInt32) -> CGColor {
        CGColor(srgbRed: CGFloat(rgb >> 16 & 255) / 255,
                green: CGFloat(rgb >> 8 & 255) / 255,
                blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }

    func oval(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
              fill: CGColor, border: CGColor? = FallbackArt.Colors.ink, weight: CGFloat = 4) {
        let center = CGPoint(x: x + width / 2, y: y + height / 2)
        let points = (0..<32).map { step -> CGPoint in
            let angle = CGFloat(step) * .pi / 16
            let uneven = 1 + sin(angle * 3 + x * 0.02) * 0.043 + cos(angle * 7) * 0.032
            return CGPoint(x: center.x + cos(angle) * width * 0.5 * uneven,
                           y: center.y + sin(angle) * height * 0.5 * uneven)
        }
        shape(points, fill: fill, border: border, weight: weight)
    }

    func polygon(_ points: [(CGFloat, CGFloat)], fill: CGColor,
                 border: CGColor? = FallbackArt.Colors.ink, weight: CGFloat = 4) {
        shape(points.map { CGPoint(x: $0.0, y: $0.1) }, fill: fill, border: border, weight: weight)
    }

    func line(_ points: [(CGFloat, CGFloat)], color: CGColor = FallbackArt.Colors.ink,
              weight: CGFloat = 4) {
        let points = points.map { CGPoint(x: $0.0, y: $0.1) }
        crayonStroke(points, color: color, weight: weight)
    }

    private func shape(_ points: [CGPoint], fill: CGColor, border: CGColor?, weight: CGFloat) {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        let box = path.boundingBoxOfPath

        context.saveGState()
        context.addPath(path)
        context.clip()
        context.setFillColor(solid ? fill : (fill.copy(alpha: 0.89) ?? fill))
        context.fill(box)

        // Long uneven wax marks and short paper gaps leave a visible
        // direction to the colouring, even on a wheel shrunk to a few points.
        if solid {
            context.restoreGState()
            if let border { crayonStroke(points + points.prefix(1), color: border, weight: weight) }
            return
        }
        context.setLineCap(.round)
        let rows = max(3, Int(box.height / 7))
        for row in 0...rows {
            let y = box.minY + box.height * CGFloat(row) / CGFloat(rows)
            let bias = CGFloat((row * 19 + 3) % 9) - 4
            let color = row.isMultiple(of: 4) ? FallbackArt.Colors.ink : FallbackArt.Colors.lightYellow
            context.setStrokeColor(color.copy(alpha: row.isMultiple(of: 4) ? 0.10 : 0.22) ?? color)
            context.setLineWidth(1.6 + CGFloat(row % 4) * 0.9)
            context.move(to: CGPoint(x: box.minX - 2, y: y + 4))
            context.addLines(between: [
                CGPoint(x: box.minX - 2, y: y + 4),
                CGPoint(x: box.minX + box.width * 0.28, y: y + bias),
                CGPoint(x: box.minX + box.width * 0.67, y: y - 6 + bias * 0.4),
                CGPoint(x: box.maxX + 2, y: y - 8)
            ])
            context.strokePath()
        }
        for speck in 0..<max(8, min(230, Int(box.width * box.height / 130))) {
            let x = box.minX + CGFloat((speck * 113 + 3) % 257) / 257 * box.width
            let y = box.minY + CGFloat((speck * 157 + 17) % 251) / 251 * box.height
            let fleck = speck.isMultiple(of: 5) ? FallbackArt.Colors.ink : FallbackArt.Colors.lightYellow
            context.setFillColor(fleck.copy(alpha: 0.19) ?? fleck)
            context.fillEllipse(in: CGRect(x: x, y: y, width: CGFloat(speck % 4 + 1), height: 1.2))
        }
        context.restoreGState()

        if let border {
            crayonStroke(points + points.prefix(1), color: border, weight: weight)
        }
    }

    private func crayonStroke(_ points: [CGPoint], color: CGColor, weight: CGFloat) {
        guard points.count >= 2 else { return }
        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(color.copy(alpha: 0.42) ?? color)
        context.setLineWidth(weight * 1.34)
        context.addLines(between: points.enumerated().map { index, point in
            CGPoint(x: point.x + CGFloat(index % 3 - 1) * 0.74,
                    y: point.y + CGFloat((index * 7) % 5 - 2) * 0.54)
        })
        context.strokePath()
        context.setStrokeColor(color.copy(alpha: 0.96) ?? color)
        context.setLineWidth(weight * 0.83)
        context.addLines(between: points)
        context.strokePath()
        context.restoreGState()
    }
}

private enum FallbackArt {
    enum Colors {
        static let ink = CrayonCanvas.color(0x352B30)
        static let lightYellow = CrayonCanvas.color(0xFFF4D2)
        static let cream = CrayonCanvas.color(0xFFF3DC)
        static let orange = CrayonCanvas.color(0xE9853B)
        static let red = CrayonCanvas.color(0xDB5A56)
        static let yellow = CrayonCanvas.color(0xF5BC50)
        static let brown = CrayonCanvas.color(0x9E6957)
    }

    private static let c = Colors.self

    static func wheel(_ ink: CrayonCanvas) {
        ink.oval(13, 12, 214, 213, fill: c.orange, weight: 5.5)
        ink.oval(27, 27, 188, 183, fill: c.cream, border: c.brown, weight: 4.4)
        let spokes: [[(CGFloat, CGFloat)]] = [
            [(118, 116), (80, 75), (61, 47)],
            [(119, 120), (149, 73), (167, 49)],
            [(122, 121), (171, 128), (206, 132)],
            [(122, 123), (149, 166), (175, 190)],
            [(119, 123), (84, 164), (63, 190)],
            [(117, 121), (71, 121), (34, 117)]
        ]
        for spoke in spokes {
            ink.line(spoke, color: c.brown, weight: 3.6)
        }
        let marks: [[(CGFloat, CGFloat)]] = [
            [(41, 48), (49, 53)], [(83, 23), (89, 35)], [(135, 18), (135, 29)],
            [(195, 47), (186, 53)], [(218, 96), (208, 98)], [(215, 154), (203, 151)],
            [(188, 196), (179, 189)], [(134, 219), (134, 207)], [(88, 216), (91, 205)],
            [(44, 187), (53, 180)], [(22, 144), (34, 141)], [(22, 91), (35, 94)]
        ]
        for mark in marks { ink.line(mark, color: c.red, weight: 3.6) }
        ink.oval(108, 108, 24, 24, fill: c.yellow, weight: 3.6)
        ink.oval(116, 114, 8, 9, fill: c.ink, border: nil)
    }

    static func sleepMark(_ ink: CrayonCanvas, x: CGFloat, y: CGFloat, size: CGFloat,
                          color: CGColor = Colors.ink) {
        ink.line([(x, y), (x + size, y - 1), (x + 1, y + size), (x + size + 1, y + size - 0.5)],
                 color: color, weight: max(3, size * 0.26))
    }

    static func animal(index: Int, ink: CrayonCanvas, runFrame: Int? = nil, asleep: Bool = false) {
        let artID = index + 1
        switch artID {
        case 1...74:
            LandAnimalDrawings.draw(id: artID, ink: ink, runFrame: runFrame, asleep: asleep)
        case 75...99:
            LargeLandDrawings.draw(id: artID, ink: ink, runFrame: runFrame, asleep: asleep)
        default:
            let context = ink.context
            context.saveGState()
            defer { context.restoreGState() }
            if let runFrame {
                let shifts: [CGFloat] = [-2, 1, 2, 0]
                let leans: [CGFloat] = [-0.035, 0.015, 0.045, -0.010]
                context.translateBy(x: 120, y: 120 + shifts[runFrame])
                context.rotate(by: leans[runFrame])
                context.translateBy(x: -120, y: -120)
            }
            if (171...188).contains(artID) {
                ArthropodDrawings.draw(id: artID, ink: ink, asleep: asleep)
            } else {
                OtherAnimalDrawings.draw(id: artID, ink: ink, asleep: asleep)
            }
        }
    }
}
