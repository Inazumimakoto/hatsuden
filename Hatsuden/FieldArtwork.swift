import SpriteKit
import UIKit

enum FieldInk {
    static let paper = UIColor(red: 1, green: 0.978, blue: 0.923, alpha: 1)
    static let dark = UIColor(red: 0.208, green: 0.169, blue: 0.188, alpha: 1)
    static let yellow = UIColor(red: 0.98, green: 0.74, blue: 0.22, alpha: 1)
    static let orange = UIColor(red: 0.91, green: 0.52, blue: 0.23, alpha: 1)
    static let blue = UIColor(red: 0.30, green: 0.56, blue: 0.90, alpha: 1)
    static let green = UIColor(red: 0.44, green: 0.67, blue: 0.39, alpha: 1)
    static let purple = UIColor(red: 0.65, green: 0.48, blue: 0.78, alpha: 1)
}

@MainActor
final class FieldArtwork {
    private static let customArtwork = UIImage(named: "field_background").map {
        texture(from: resizeBackground($0))
    }
    private static var motifs: [FieldMotif: SKTexture] = [:]
    private static let sceneryDetails: NSCache<NSNumber, SKTexture> = {
        let cache = NSCache<NSNumber, SKTexture>()
        cache.totalCostLimit = 16 * 1_024 * 1_024
        return cache
    }()

    var customBackground: SKTexture? { Self.customArtwork }

    func texture(for detail: FieldCanvas.Detail) -> SKTexture {
        let key = NSNumber(value: detail.id)
        if let cached = Self.sceneryDetails.object(forKey: key) { return cached }
        let size = CGSize(width: 320, height: 240)
        let image = Self.renderer(size: size).image { painter in
            let context = painter.cgContext
            switch detail.artist {
            case .room: CanvasRoomDetails.draw(detail.subject, in: context)
            case .earth: CanvasEarthDetails.draw(detail.subject, in: context)
            case .sky: CanvasSkyDetails.draw(detail.subject, in: context)
            case .extra: CanvasExtraDetails.draw(detail.subject, in: context)
            }
        }
        let texture = Self.texture(from: image)
        Self.sceneryDetails.setObject(texture, forKey: key, cost: 320 * 240 * 4 * 4 / 3)
        return texture
    }

    func texture(for motif: FieldMotif) -> SKTexture {
        if let cached = Self.motifs[motif] { return cached }
        let crop = Self.bounds(for: motif)
        let scale = min(2, 512 / max(crop.width, crop.height))
        let size = CGSize(width: ceil(crop.width * scale), height: ceil(crop.height * scale))
        let image = Self.renderer(size: size).image { painter in
            let context = painter.cgContext
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -crop.minX, y: -crop.minY)
            switch motif {
            case .hive, .gardenFence, .flowerPatch:
                GardenBackdrop.draw(motif, in: context)
            case .railway, .neighborhood:
                NeighborhoodBackdrop.draw(motif, in: context)
            case .comet, .nebula, .icePlanet:
                SpaceBackdrop.draw(motif, in: context)
            case .creek, .windmill, .foothill, .sailboat, .cloudBank, .satellite:
                CanvasDetails.draw(motif, in: context)
            default:
                BackdropPainter(context: context).draw(motif)
            }
        }
        let texture = Self.texture(from: image)
        Self.motifs[motif] = texture
        return texture
    }

    private static func bounds(for motif: FieldMotif) -> CGRect {
        switch motif {
        case .hive: CGRect(x: 302, y: 728, width: 345, height: 355)
        case .hamsterHouse: CGRect(x: 925, y: 1_888, width: 81, height: 81)
        case .gardenFence: CGRect(x: -30, y: 515, width: 1_075, height: 240)
        case .flowerPatch: CGRect(x: 6, y: 810, width: 1_025, height: 1_190)
        case .railway: CGRect(x: -44, y: 952, width: 1_094, height: 375)
        case .neighborhood: CGRect(x: -27, y: 624, width: 1_069, height: 334)
        case .tokyo: CGRect(x: 430, y: 1_039, width: 610, height: 811)
        case .fuji: CGRect(x: 153, y: 704, width: 587, height: 493)
        case .liberty: CGRect(x: -69, y: 592, width: 441, height: 539)
        case .rocket: CGRect(x: 350, y: 139, width: 181, height: 193)
        case .moon: CGRect(x: 600, y: 241, width: 85, height: 86)
        case .mars: CGRect(x: 670, y: 58, width: 224, height: 222)
        case .ringedPlanet: CGRect(x: 19, y: 48, width: 250, height: 169)
        case .comet: CGRect(x: 254, y: 1_356, width: 467, height: 393)
        case .nebula: CGRect(x: -75, y: 360, width: 1_190, height: 940)
        case .icePlanet: CGRect(x: 726, y: 1_560, width: 260, height: 273)
        case .creek, .windmill, .foothill, .sailboat, .cloudBank, .satellite:
            CGRect(x: 0, y: 0, width: 512, height: 384)
        }
    }

    private static func resizeBackground(_ artwork: UIImage) -> UIImage {
        let largestSide = max(artwork.size.width, artwork.size.height)
        guard largestSide * artwork.scale > 4_096 else { return artwork }

        let scale = 4_096 / largestSide
        let size = CGSize(width: max(1, (artwork.size.width * scale).rounded()),
                          height: max(1, (artwork.size.height * scale).rounded()))
        let bounds = CGRect(origin: .zero, size: size)
        return renderer(size: size, opaque: true).image { painter in
            painter.cgContext.setFillColor(FieldInk.paper.cgColor)
            painter.cgContext.fill(bounds)
            artwork.draw(in: bounds)
        }
    }

    lazy var slot: SKTexture = UIImage(named: "field_slot").map(Self.texture(from:))
        ?? Self.texture(from: Self.drawSlot())
    lazy var stand: SKTexture = UIImage(named: "wheel_stand").map(Self.texture(from:))
        ?? Self.texture(from: Self.drawStand())

    private static func texture(from image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return texture
    }

    private static func renderer(size: CGSize, opaque: Bool = false) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format)
    }

    private static func drawSlot() -> UIImage {
        renderer(size: CGSize(width: 160, height: 160)).image { renderer in
            let crayon = Crayon(context: renderer.cgContext)
            let color = FieldInk.purple
            crayon.stroke([(13, 42), (12, 23), (21, 14), (47, 15)], color: color, width: 2, opacity: 0.30)
            crayon.stroke([(115, 14), (140, 13), (147, 21), (145, 42)], color: color, width: 2, opacity: 0.29)
            crayon.stroke([(148, 115), (145, 139), (138, 145), (115, 146)], color: color, width: 2, opacity: 0.30)
            crayon.stroke([(44, 144), (22, 147), (12, 139), (15, 116)], color: color, width: 2, opacity: 0.30)
        }
    }

    private static func drawStand() -> UIImage {
        renderer(size: CGSize(width: 304, height: 152)).image { renderer in
            let context = renderer.cgContext
            context.scaleBy(x: 2, y: 2)
            let crayon = Crayon(context: context)
            let legA: [(CGFloat, CGFloat)] = [(50, 17), (64, 19), (48, 57), (34, 58)]
            let legB: [(CGFloat, CGFloat)] = [(98, 19), (107, 17), (121, 55), (108, 59)]
            let foot: [(CGFloat, CGFloat)] = [(22, 54), (53, 53), (106, 55), (128, 52), (131, 63),
                                              (102, 66), (53, 63), (24, 66)]

            for shape in [legA, legB, foot] {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: shape[0].0, y: shape[0].1))
                path.addLines(between: shape.map { CGPoint(x: $0.0, y: $0.1) })
                path.closeSubpath()
                context.setFillColor(FieldInk.blue.withAlphaComponent(0.65).cgColor)
                context.addPath(path)
                context.fillPath()
                crayon.stroke(shape + [shape[0]], color: FieldInk.dark, width: 2.6, opacity: 0.94)
            }

            for x in stride(from: 28.0, to: 125, by: 5) {
                crayon.stroke([(x, 61), (x + 2, 57)], color: FieldInk.blue, width: 1.4, opacity: 0.72)
            }
        }
    }
}

private struct Crayon {
    let context: CGContext

    func stroke(_ points: [(CGFloat, CGFloat)], color: UIColor, width: CGFloat, opacity: CGFloat) {
        stroke(points.map { CGPoint(x: $0.0, y: $0.1) }, color: color, width: width, opacity: opacity)
    }

    func stroke(_ points: [CGPoint], color: UIColor, width: CGFloat, opacity: CGFloat) {
        guard let start = points.first else { return }
        context.setLineCap(.round)
        context.setLineJoin(.round)
        for layer in 0..<3 {
            let wiggle = CGFloat(layer - 1) * width * 0.24
            let path = CGMutablePath()
            path.move(to: CGPoint(x: start.x - wiggle, y: start.y + wiggle))
            for (index, point) in points.dropFirst().enumerated() {
                let jitter = CGFloat(index % 3 - 1) * width * 0.12
                path.addLine(to: CGPoint(x: point.x + wiggle - jitter, y: point.y - wiggle + jitter))
            }
            context.setLineWidth(width * (layer == 1 ? 0.72 : 0.32))
            context.setStrokeColor(color.withAlphaComponent(opacity * (layer == 1 ? 0.85 : 0.41)).cgColor)
            context.addPath(path)
            context.strokePath()
        }
    }
}

private struct PaperRandom {
    private var state: UInt64 = 0x38D5_A111_A52E_C501

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(state >> 40) / 16_777_216
    }
}

/// Coordinates follow the same top-left origin as the original drawing sheet.
private final class BackdropPainter {
    private typealias P = (CGFloat, CGFloat)
    private let wax: WaxCrayon
    private var random = PaperRandom()
    private let night = UIColor(red: 0.22, green: 0.25, blue: 0.54, alpha: 1)
    private let lake = UIColor(red: 0.23, green: 0.56, blue: 0.80, alpha: 1)
    private let leaf = UIColor(red: 0.38, green: 0.59, blue: 0.33, alpha: 1)
    private let lilac = UIColor(red: 0.57, green: 0.44, blue: 0.72, alpha: 1)
    private let red = UIColor(red: 0.81, green: 0.29, blue: 0.30, alpha: 1)
    private let honey = UIColor(red: 0.92, green: 0.64, blue: 0.28, alpha: 1)
    private let wood = UIColor(red: 0.53, green: 0.31, blue: 0.23, alpha: 1)
    private let skyBlue = UIColor(red: 0.49, green: 0.67, blue: 0.86, alpha: 1)
    private let white = UIColor(red: 1, green: 0.99, blue: 0.95, alpha: 1)

    init(context: CGContext) { wax = WaxCrayon(context: context) }

    func draw(_ motif: FieldMotif) {
        switch motif {
        case .hamsterHouse: hamsterRoom()
        case .tokyo: city()
        case .fuji: fuji()
        case .liberty: libertyHarbor()
        case .rocket: rocket()
        case .moon: crescent()
        case .mars: mars()
        case .ringedPlanet: ringedPlanet()
        default: break
        }
    }

    private func ringedPlanet() {
        // A tall, lumpy planet and its crooked ring.
        wax.shape([(87, 110), (113, 75), (168, 66), (199, 96), (210, 135),
                   (177, 180), (127, 186), (91, 158)], color: honey, border: FieldInk.orange,
                  width: 8.5, opacity: 0.94)
        wax.stroke([(97, 118), (134, 105), (172, 119), (192, 105)], color: red, width: 6, opacity: 0.63)
        wax.stroke([(124, 164), (159, 162), (181, 143)], color: white, width: 5.6, opacity: 0.65)
        wax.stroke([(87, 131), (44, 151), (42, 173), (77, 190), (160, 177), (225, 147),
                    (244, 126), (221, 114), (201, 121)], color: lilac, width: 12.5, opacity: 0.96)
        wax.stroke([(43, 168), (63, 182), (120, 178), (189, 157), (228, 130)],
                   color: white, width: 3.8, opacity: 0.66)
    }

    private func mars() {
        // Mars is the first big planet to come into view near the edge of the sheet.
        let rust = UIColor(red: 0.64, green: 0.24, blue: 0.24, alpha: 1)
        wax.shape([(692, 143), (713, 107), (755, 82), (810, 90), (849, 116),
                   (869, 163), (857, 211), (828, 245), (779, 255), (736, 233),
                   (704, 205)], color: FieldInk.orange, border: red, width: 10, opacity: 0.98)
        wax.shape([(704, 161), (719, 145), (743, 150), (753, 176), (789, 181),
                   (818, 174), (852, 185), (853, 213), (826, 241), (779, 251),
                   (742, 233), (719, 210)], color: red, border: red, width: 5, opacity: 0.66)
        wax.stroke([(720, 129), (741, 111), (767, 112), (781, 100)],
                   color: honey, width: 9.4, opacity: 0.79)
        wax.stroke([(725, 201), (752, 218), (779, 221), (802, 239)],
                   color: honey, width: 7.2, opacity: 0.72)
        wax.stroke([(811, 111), (831, 126), (840, 144)], color: white, width: 6, opacity: 0.49)
        wax.shape([(775, 140), (789, 131), (804, 134), (811, 146), (799, 155), (782, 155)],
                  color: rust, border: rust, width: 4.7, opacity: 0.73)
        wax.shape([(805, 198), (816, 191), (834, 197), (832, 208), (817, 214), (807, 210)],
                  color: rust, border: rust, width: 4, opacity: 0.70)
        wax.stroke([(750, 187), (759, 184), (770, 190)], color: rust, width: 5.6, opacity: 0.76)
    }

    private func crescent() {
        // A pale crescent just beyond the blue edge of Earth.
        wax.shape([(648, 254), (629, 258), (615, 276), (615, 293), (629, 309),
                   (647, 311), (668, 299), (651, 298), (638, 285), (638, 269)],
                  color: white, border: honey, width: 4.6, opacity: 0.90)
    }

    private func rocket() {
        // A tiny rocket in a different direction from the planetary arc.
        wax.shape([(416, 261), (431, 207), (474, 166), (508, 155), (493, 195),
                   (467, 235), (442, 265)], color: white, border: skyBlue, width: 5.3, opacity: 0.9)
        wax.shape([(433, 224), (405, 227), (389, 256), (418, 254)],
                  color: red, border: honey, width: 4, opacity: 0.82)
        wax.shape([(460, 241), (459, 269), (431, 292), (435, 260)],
                  color: red, border: honey, width: 4, opacity: 0.82)
        wax.shape([(460, 216), (453, 204), (468, 191), (482, 198), (474, 215)],
                  color: lake, border: night, width: 3.5, opacity: 0.88)
        wax.stroke([(414, 268), (391, 283), (368, 312), (399, 291), (383, 316)],
                   color: honey, width: 8, opacity: 0.90)
    }

    private func libertyHarbor() {
        let copper = UIColor(red: 0.34, green: 0.69, blue: 0.56, alpha: 1)
        let copperShade = UIColor(red: 0.19, green: 0.45, blue: 0.39, alpha: 1)
        let stone = UIColor(red: 0.76, green: 0.56, blue: 0.42, alpha: 1)

        // The harbor sits to the left of Fuji, outside the earlier crops of the drawing.
        let water: [P] = [(-48, 1_014), (29, 997), (79, 1_004), (123, 1_011), (185, 997), (236, 1_012),
                          (304, 1_002), (348, 1_019), (339, 1_054), (269, 1_081),
                          (184, 1_098), (111, 1_081), (25, 1_097), (-47, 1_110)]
        wax.shape(water, color: lake, border: skyBlue, width: 7, opacity: 0.61)
        wax.shape([(121, 1_042), (146, 1_023), (193, 1_014), (248, 1_016), (296, 1_030),
                   (315, 1_050), (269, 1_065), (190, 1_069), (148, 1_060)],
                  color: leaf, border: copperShade, width: 5.8, opacity: 0.91)
        wax.stroke([(72, 1_040), (92, 1_033), (109, 1_036)], color: white, width: 4.5, opacity: 0.74)
        wax.stroke([(102, 1_072), (126, 1_068), (145, 1_072), (158, 1_068)],
                   color: white, width: 5, opacity: 0.78)
        wax.stroke([(228, 1_083), (254, 1_081), (281, 1_071), (300, 1_075)],
                   color: white, width: 4.7, opacity: 0.77)

        // A sailboat gives the statue a nearby point of reference for scale.
        wax.shape([(89, 1_016), (126, 1_019), (119, 1_029), (101, 1_029)],
                  color: red, border: wood, width: 3.5, opacity: 0.86)
        wax.shape([(102, 1_010), (115, 984), (122, 1_010)],
                  color: white, border: skyBlue, width: 3.2, opacity: 0.94)

        wax.shape([(158, 1_036), (164, 1_020), (176, 1_018), (178, 998), (192, 997),
                   (193, 947), (255, 949), (261, 997), (274, 1_000), (276, 1_020),
                   (290, 1_027), (291, 1_040), (222, 1_047)],
                  color: stone, border: wood, width: 6.4, opacity: 0.95)
        wax.stroke([(174, 1_020), (216, 1_027), (272, 1_021)], color: honey, width: 5, opacity: 0.76)
        wax.stroke([(201, 992), (221, 996), (254, 991)], color: wood, width: 4.3, opacity: 0.55)
        wax.stroke([(216, 981), (217, 966), (225, 962), (233, 966), (234, 982)],
                   color: wood, width: 5, opacity: 0.74)

        // Raised torch arm, then the gown, tablet, face, and seven crown rays.
        wax.shape([(204, 841), (182, 823), (166, 781), (151, 719), (144, 699), (160, 688),
                   (171, 705), (181, 741), (202, 778), (221, 798)],
                  color: copper, border: copperShade, width: 6.3, opacity: 0.98)
        wax.stroke([(159, 703), (155, 682), (150, 670)], color: copperShade, width: 8, opacity: 0.95)
        wax.shape([(138, 662), (163, 661), (159, 672), (145, 673)],
                  color: honey, border: wood, width: 4.5, opacity: 0.95)
        wax.shape([(144, 660), (135, 650), (142, 637), (140, 625), (153, 632),
                   (161, 619), (164, 642), (156, 657)],
                  color: honey, border: FieldInk.orange, width: 5.1, opacity: 0.97)

        wax.shape([(210, 789), (233, 785), (249, 797), (264, 808), (270, 842),
                   (253, 863), (251, 891), (267, 946), (243, 957), (180, 950),
                   (192, 909), (198, 881), (193, 851), (197, 814)],
                  color: copper, border: copperShade, width: 6.4, opacity: 0.98)
        wax.stroke([(201, 808), (219, 827), (243, 841), (257, 835)],
                   color: copperShade, width: 6.2, opacity: 0.75)
        wax.stroke([(202, 839), (216, 860), (210, 896), (199, 931)],
                   color: white, width: 5.2, opacity: 0.54)
        wax.stroke([(233, 864), (225, 902), (231, 930), (226, 948)],
                   color: copperShade, width: 5.4, opacity: 0.72)
        wax.stroke([(246, 887), (243, 908), (255, 940)], color: white, width: 5.2, opacity: 0.49)

        wax.shape([(244, 817), (270, 804), (284, 850), (254, 862)],
                  color: copperShade, border: copperShade, width: 5.2, opacity: 0.90)
        wax.stroke([(260, 842), (271, 835), (278, 839)], color: copper, width: 8.4, opacity: 1)

        wax.shape([(207, 751), (217, 738), (241, 739), (252, 757), (246, 779),
                   (232, 794), (217, 787), (209, 774)],
                  color: copper, border: copperShade, width: 5.5, opacity: 0.98)
        let crownRays: [(P, P)] = [((207, 751), (187, 742)), ((213, 742), (196, 722)),
                                   ((218, 738), (210, 709)), ((227, 738), (230, 706)),
                                   ((236, 738), (248, 713)), ((243, 743), (261, 725)),
                                   ((249, 749), (270, 740))]
        for (root, tip) in crownRays {
            wax.stroke([root, tip], color: copperShade, width: 5.2, opacity: 0.94)
        }
        wax.stroke([(209, 754), (223, 747), (239, 746), (251, 753)],
                   color: copperShade, width: 7.6, opacity: 0.93)
        wax.stroke([(218, 764), (221, 763)], color: copperShade, width: 4, opacity: 0.92)
        wax.stroke([(236, 763), (239, 764)], color: copperShade, width: 4, opacity: 0.92)
        wax.stroke([(224, 778), (229, 780), (236, 777)], color: copperShade, width: 3.8, opacity: 0.86)
    }

    private func fuji() {
        let mountain: [P] = [(188, 1_158), (258, 1_103), (329, 1_013), (367, 933),
                             (393, 836), (415, 743), (440, 750), (467, 741),
                             (480, 778), (503, 872), (533, 932), (597, 1_029),
                             (661, 1_079), (703, 1_151), (566, 1_140), (460, 1_162),
                             (333, 1_151), (260, 1_165)]
        wax.shape(mountain, color: lilac, border: night, width: 11.4, opacity: 0.83)
        let snow: [P] = [(388, 870), (401, 816), (415, 743), (440, 750), (467, 741),
                         (480, 778), (500, 866), (479, 863), (456, 899),
                         (431, 870), (409, 903)]
        wax.shape(snow, color: white, border: skyBlue, width: 6, opacity: 0.88)
        wax.stroke([(314, 1_068), (364, 998), (402, 934)], color: skyBlue, width: 6.3, opacity: 0.62)
        wax.stroke([(516, 931), (541, 994), (599, 1_054)], color: night, width: 6.8, opacity: 0.45)
        wax.stroke([(497, 969), (522, 1_031), (553, 1_067)], color: white, width: 5.8, opacity: 0.59)
    }

    private func city() {
        let skyline: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (466, 1_468, 35, 59), (516, 1_441, 43, 99), (563, 1_487, 37, 72),
            (628, 1_413, 37, 150), (675, 1_506, 44, 72), (718, 1_499, 35, 96),
            (820, 1_518, 41, 112), (875, 1_545, 39, 104), (914, 1_579, 40, 82),
            (970, 1_519, 34, 165)
        ]
        for (i, (x, y, w, h)) in skyline.enumerated() {
            let tilt = (random.next() - 0.5) * 13
            let tint = i.isMultiple(of: 3) ? honey : i % 3 == 1 ? lilac : skyBlue
            wax.shape([(x + tilt, y + 5), (x + w * 0.55, y - 3), (x + w + tilt, y + 6),
                       (x + w + 4, y + h - 9), (x + w * 0.69, y + h),
                       (x - 3, y + h - 4)], color: tint, border: tint, width: 5, opacity: 0.55)
            for offset in stride(from: 17, to: Int(h - 11), by: 18) {
                let v = y + CGFloat(offset)
                wax.stroke([(x + 7, v + 3), (x + 12, v), (x + 18, v + 1)],
                           color: white, width: 4.4, opacity: 0.84)
                if i % 2 == 0 {
                    wax.stroke([(x + w - 15, v - 1), (x + w - 7, v + 2)],
                               color: white, width: 4, opacity: 0.73)
                }
            }
        }

        let skytree: [P] = [(571, 1_482), (580, 1_413), (585, 1_329), (597, 1_246), (598, 1_152),
                            (611, 1_153), (614, 1_240), (616, 1_325), (624, 1_414), (641, 1_481)]
        wax.shape(skytree, color: skyBlue, border: lake, width: 6.7, opacity: 0.85)
        wax.stroke([(609, 1_082), (603, 1_116), (606, 1_152)], color: night, width: 5, opacity: 0.88)
        for (y, width): (CGFloat, CGFloat) in [(1_199, 42), (1_258, 61)] {
            wax.shape([(603 - width / 2, y + 1), (601, y - 4), (606 + width / 2, y + 3),
                       (605 + width / 2, y + 15), (605, y + 19), (601 - width / 2, y + 13)],
                      color: white, border: night, width: 5.2, opacity: 0.79)
        }
        wax.stroke([(604, 1_294), (600, 1_351), (600, 1_405), (605, 1_465)],
                   color: white, width: 6.8, opacity: 0.76)
        for y in stride(from: 1_312, through: 1_451, by: 28) {
            let h = CGFloat(y)
            let s = 8 + (h - 1_312) * 0.07
            wax.stroke([(604 - s, h), (605, h + 9), (606 + s, h + 20)],
                       color: lake, width: 3.5, opacity: 0.67)
        }

        let tower: [P] = [(713, 1_663), (731, 1_635), (747, 1_585), (760, 1_536),
                          (764, 1_481), (769, 1_452), (777, 1_451), (780, 1_489),
                          (784, 1_535), (793, 1_582), (810, 1_629), (831, 1_662),
                          (800, 1_663), (785, 1_639), (770, 1_629), (755, 1_635),
                          (739, 1_663)]
        wax.shape(tower, color: red, border: red, width: 8.5, opacity: 0.92)
        wax.stroke([(774, 1_406), (772, 1_434), (774, 1_455)], color: red, width: 5, opacity: 0.90)
        for (y, width): (CGFloat, CGFloat) in [(1_486, 16), (1_526, 26), (1_567, 45), (1_606, 58)] {
            wax.stroke([(774 - width / 2, y + 1), (768, y - 2), (773 + width / 2, y + 3)],
                       color: white, width: 9.5, opacity: 0.92)
            wax.stroke([(776 - width / 2, y + 5), (773 + width / 2, y + 29)],
                       color: honey, width: 4.8, opacity: 0.91)
        }
        wax.stroke([(741, 1_572), (757, 1_568), (782, 1_570), (803, 1_572)], color: red, width: 13, opacity: 0.84)

        let road: [P] = [(674, 1_784), (707, 1_756), (771, 1_723), (821, 1_727), (861, 1_758),
                         (887, 1_792), (902, 1_825)]
        wax.stroke(road, color: honey, width: 19, opacity: 0.59)
        wax.stroke(road.map { ($0.0 + 1, $0.1 - 4) }, color: white, width: 4.2, opacity: 0.57)

        tree(x: 642, y: 1_647, size: 1.22)
        tree(x: 865, y: 1_684, size: 0.96)
        tree(x: 695, y: 1_806, size: 0.74)
    }

    private func tree(x: CGFloat, y: CGFloat, size: CGFloat) {
        let leaves: [P] = [(-20, -6), (-36, -11), (-38, -26), (-26, -41), (-22, -57),
                           (-8, -59), (0, -72), (20, -67), (24, -51), (35, -45),
                           (37, -29), (25, -14), (20, -5), (4, -1), (-7, -6)]
        wax.stroke([(x - 1, y - 21 * size), (x + 4 * size, y - 6 * size), (x - 2, y + 19 * size)],
                   color: wood, width: 7.3 * size, opacity: 0.75)
        wax.shape(leaves.map { (x + $0.0 * size, y + $0.1 * size) }, color: leaf,
                  border: leaf, width: 5.3 * size, opacity: 0.75)
        wax.stroke([(x - 19 * size, y - 25 * size), (x - 8 * size, y - 34 * size),
                    (x + 5 * size, y - 26 * size), (x + 23 * size, y - 35 * size)],
                   color: honey, width: 3.8 * size, opacity: 0.56)
    }

    private func hamsterRoom() {
        wax.shape([(940, 1_916), (953, 1_911), (973, 1_912), (987, 1_917), (986, 1_940),
                   (973, 1_943), (950, 1_942), (938, 1_939)], color: honey,
                  border: wood, width: 2.5, opacity: 0.91)
        wax.shape([(933, 1_917), (943, 1_909), (956, 1_899), (962, 1_894), (968, 1_897),
                   (977, 1_907), (992, 1_915), (991, 1_920), (972, 1_917), (957, 1_916),
                   (942, 1_922)], color: red, border: wood, width: 2.25, opacity: 0.90)
        wax.shape([(953, 1_941), (953, 1_933), (955, 1_927), (960, 1_924), (966, 1_925),
                   (971, 1_929), (973, 1_935), (973, 1_942)], color: wood,
                  border: wood, width: 1.75, opacity: 0.91)

        wax.shape([(981, 1_953), (986, 1_951), (997, 1_951), (1_000, 1_955),
                   (996, 1_963), (985, 1_963)], color: lake, border: lake,
                  width: 1.6, opacity: 0.75)
        wax.stroke([(985, 1_951), (988, 1_949), (993, 1_950), (996, 1_951)],
                   color: honey, width: 1.5, opacity: 0.82)
    }
}

/// Short uneven passes leave gaps in the paper instead of a clean vector fill.
final class WaxCrayon {
    private let context: CGContext
    private var random = PaperRandom()

    init(context: CGContext) {
        self.context = context
        context.setLineCap(.round)
        context.setLineJoin(.round)
    }

    func shape(_ points: [(CGFloat, CGFloat)], color: UIColor, border: UIColor,
               width: CGFloat, opacity: CGFloat) {
        guard let first = points.first else { return }
        fill(points, color: color, opacity: opacity)
        stroke(points + [first], color: border, width: width, opacity: opacity, closed: true)
    }

    func fill(_ points: [(CGFloat, CGFloat)], color: UIColor, opacity: CGFloat) {
        guard points.count > 2 else { return }
        let vertices = points.map { CGPoint(x: $0.0, y: $0.1) }
        let minX = vertices.map(\.x).min() ?? 0
        let minY = vertices.map(\.y).min() ?? 0
        let maxX = vertices.map(\.x).max() ?? 0
        let maxY = vertices.map(\.y).max() ?? 0
        let size = min(maxX - minX, maxY - minY)
        let pitch = min(7.2, max(0.72, size * 0.041))
        let contour = rough(vertices, closed: true, step: max(0.9, pitch), wiggle: pitch * 0.41)
        let path = CGMutablePath()
        path.addLines(between: contour)
        path.closeSubpath()

        context.saveGState()
        context.addPath(path)
        context.clip()
        context.setFillColor(color.withAlphaComponent(opacity * 0.49).cgColor)
        context.fill(path.boundingBoxOfPath)

        for pass in 0..<2 {
            let slope: CGFloat = pass == 0 ? -0.17 : 0.28
            let bounds = path.boundingBoxOfPath.insetBy(dx: -pitch * 3, dy: -pitch * 3)
            let startY = bounds.minY - abs(slope) * bounds.width
            let endY = bounds.maxY + abs(slope) * bounds.width
            var y = startY
            while y < endY {
                var x = bounds.minX - pitch * random.next() * 7
                let run = min(bounds.width, max(pitch * 11, bounds.width * 0.23))
                while x < bounds.maxX {
                    let length = run * (0.55 + random.next() * 1.28)
                    let height = y + (x - bounds.minX) * slope + pitch * (random.next() - 0.5)
                    let slant = length * (slope + (random.next() - 0.5) * 0.31)
                    let end = height + slant + pitch * (random.next() - 0.5) * 1.9
                    var mark: [CGPoint] = [
                        CGPoint(x: x, y: height),
                        CGPoint(x: x + length * 0.32, y: height + slant * 0.32 + pitch * (random.next() - 0.5) * 2.3),
                        CGPoint(x: x + length * 0.69, y: height + slant * 0.69 + pitch * (random.next() - 0.5) * 2.5),
                        CGPoint(x: x + length, y: end)
                    ]
                    if random.next() < 0.28 {
                        mark.append(CGPoint(x: x + length * 0.80, y: end + pitch * (1.1 + random.next())))
                        mark.append(CGPoint(x: x + length * 0.57, y: end + pitch * 2.1 - slant * 0.36))
                    }
                    let alpha = opacity * (0.10 + random.next() * (pass == 0 ? 0.45 : 0.21))
                    draw(mark, color: color, width: pitch * (0.54 + random.next() * 1.26), opacity: alpha)
                    x += length * (0.73 + random.next() * 0.54)
                }
                y += pitch * (0.66 + random.next() * 0.92)
            }
        }
        context.restoreGState()
    }

    func stroke(_ points: [(CGFloat, CGFloat)], color: UIColor, width: CGFloat, opacity: CGFloat, closed: Bool = false) {
        guard points.count >= 2 else { return }
        var vertices = points.map { CGPoint(x: $0.0, y: $0.1) }
        if closed, vertices.first == vertices.last { vertices.removeLast() }

        let samples = rough(vertices, closed: closed, step: max(0.9, width * 0.91), wiggle: width * 0.36)
        draw(samples, color: color, width: width * 0.72, opacity: opacity * 0.77)
        guard samples.count > 2 else { return }

        for side: CGFloat in [-1, 1] {
            var i = 0
            while i < samples.count - 1 {
                let length = 2 + Int(random.next() * 7)
                let end = min(samples.count, i + length)
                let shift = (0.20 + random.next() * 0.27) * width * side
                let mark = samples[i..<end].enumerated().map { offset, point in
                    let drift = CGFloat(offset % 3 - 1) * width * 0.06
                    return CGPoint(x: point.x + shift + drift, y: point.y + shift * 0.71 - drift)
                }
                draw(mark, color: color, width: width * (0.25 + random.next() * 0.25),
                     opacity: opacity * (0.28 + random.next() * 0.44))
                i += length + Int(random.next() * 4)
            }
        }
    }

    private func draw(_ points: [CGPoint], color: UIColor, width: CGFloat, opacity: CGFloat) {
        guard points.count >= 2 else { return }
        context.setStrokeColor(color.withAlphaComponent(opacity).cgColor)
        context.setLineWidth(width)
        context.addLines(between: points)
        context.strokePath()
    }

    private func rough(_ vertices: [CGPoint], closed: Bool, step: CGFloat, wiggle: CGFloat) -> [CGPoint] {
        guard vertices.count >= 2 else { return vertices }
        let count = vertices.count
        let segments = closed ? count : count - 1
        var result: [CGPoint] = []
        let phase = random.next() * 6.283
        for i in 0..<segments {
            let previous = vertices[closed ? (i + count - 1) % count : max(0, i - 1)]
            let from = vertices[i]
            let to = vertices[(i + 1) % count]
            let next = vertices[closed ? (i + 2) % count : min(count - 1, i + 2)]
            let distance = hypot(to.x - from.x, to.y - from.y)
            let samples = max(2, Int(ceil(distance / step)))
            let range = i == segments - 1 ? 0...samples : 0...(samples - 1)
            for sample in range {
                let t = CGFloat(sample) / CGFloat(samples)
                let t2 = t * t
                let t3 = t2 * t
                let h00 = 2 * t3 - 3 * t2 + 1
                let h10 = t3 - 2 * t2 + t
                let h01 = -2 * t3 + 3 * t2
                let h11 = t3 - t2
                let tension: CGFloat = 0.26
                let x = h00 * from.x + h10 * tension * (to.x - previous.x)
                    + h01 * to.x + h11 * tension * (next.x - from.x)
                let y = h00 * from.y + h10 * tension * (to.y - previous.y)
                    + h01 * to.y + h11 * tension * (next.y - from.y)
                let spin = CGFloat(result.count) * 0.53 + phase
                let shiftX = wiggle * (sin(spin) * 0.68 + cos(spin * 2.21) * 0.26)
                let shiftY = wiggle * (cos(spin * 0.81) * 0.72 + sin(spin * 2.12) * 0.29)
                result.append(CGPoint(x: x + shiftX, y: y + shiftY))
            }
        }
        if closed, let first = result.first { result[result.count - 1] = first }
        return result
    }
}
