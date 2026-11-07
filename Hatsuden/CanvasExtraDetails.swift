import UIKit

enum CanvasExtraDetails {
    static func draw(_ subject: CanvasSubject, in context: CGContext) {
        let sketch = ExtraSketch(wax: WaxCrayon(context: context))
        switch subject {
        case .steppingStones: sketch.stones()
        case .teaGarden: sketch.teaGarden()
        case .cliffTrail: sketch.cliff()
        case .weatherVane: sketch.vane()
        case .sunDog: sketch.sunDog()
        case .aurora: sketch.aurora()
        case .spiralGalaxy: sketch.galaxy()
        case .ringDebris: sketch.debris()
        default: break
        }
    }
}

private struct ExtraSketch {
    typealias Point = (CGFloat, CGFloat)
    let wax: WaxCrayon
    private let ink = UIColor(red: 0.37, green: 0.29, blue: 0.36, alpha: 1)
    private let moss = UIColor(red: 0.45, green: 0.63, blue: 0.36, alpha: 1)
    private let blue = UIColor(red: 0.38, green: 0.67, blue: 0.81, alpha: 1)
    private let teal = UIColor(red: 0.46, green: 0.81, blue: 0.73, alpha: 1)
    private let lavender = UIColor(red: 0.67, green: 0.54, blue: 0.83, alpha: 1)
    private let gold = UIColor(red: 0.96, green: 0.77, blue: 0.33, alpha: 1)
    private let rose = UIColor(red: 0.83, green: 0.41, blue: 0.48, alpha: 1)
    private let brown = UIColor(red: 0.63, green: 0.42, blue: 0.29, alpha: 1)
    private let cream = FieldInk.paper

    func stones() {
        wax.fill([(25, 187), (45, 145), (90, 122), (171, 110), (238, 81), (289, 83), (308, 122),
                  (285, 157), (216, 173), (147, 183), (93, 207), (42, 213)], color: blue, opacity: 0.53)
        for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in
            [(56, 179, 27, 13), (106, 151, 24, 12), (151, 154, 20, 10), (192, 128, 18, 10), (239, 116, 15, 8)] {
            shape([(x - w, y + 1), (x - w * 0.52, y - h), (x + w * 0.56, y - h * 0.86),
                   (x + w, y + 4), (x + w * 0.21, y + h), (x - w * 0.65, y + h - 2)], lavender, width: 4)
            line([(x - w * 0.45, y - 3), (x, y - h * 0.58), (x + w * 0.45, y - 3)], cream, 2.8)
        }
        for (x, y): Point in [(42, 138), (134, 199), (219, 80), (277, 158)] {
            line([(x - 12, y + 4), (x - 4, y - 9), (x + 2, y + 2), (x + 8, y - 15), (x + 12, y + 3)], moss, 4)
        }
    }

    func teaGarden() {
        wax.fill([(21, 187), (76, 171), (177, 178), (226, 164), (303, 189), (260, 216), (65, 213)],
                 color: moss, opacity: 0.59)
        for (x, skew): (CGFloat, CGFloat) in [(83, 4), (230, -2)] {
            shape([(x - 7, 91), (x + 7, 90), (x + skew + 7, 190), (x + skew - 6, 193)], brown)
        }
        shape([(46, 97), (81, 85), (127, 54), (164, 45), (193, 66), (234, 84), (270, 92),
               (237, 106), (161, 98), (86, 109)], rose, width: 6)
        line([(70, 95), (111, 78), (158, 65), (189, 77), (241, 97)], gold, 3.7)
        shape([(112, 158), (207, 153), (220, 164), (214, 177), (113, 180), (103, 170)], brown)
        line([(124, 176), (121, 197), (201, 193), (199, 174)], ink, 5)
        shape([(153, 141), (175, 140), (174, 156), (157, 156)], teal, width: 3)
        shape([(176, 142), (189, 145), (182, 151), (176, 150)], teal, width: 2.6)
        shape([(132, 147), (145, 147), (142, 157), (135, 156)], cream, width: 2.5)
    }

    func cliff() {
        shape([(43, 196), (88, 106), (121, 95), (151, 59), (224, 49), (271, 69), (281, 162),
               (264, 207), (200, 209), (147, 191), (98, 207)], brown, width: 6, opacity: 0.77)
        shape([(88, 106), (122, 94), (152, 58), (222, 48), (273, 68), (260, 96), (215, 87), (174, 108),
               (128, 116), (106, 144), (66, 154)], moss, width: 4.6)
        line([(95, 188), (133, 167), (201, 162), (210, 145), (143, 143), (158, 123), (229, 118), (241, 95)], cream, 6)
        line([(245, 93), (245, 52)], ink, 4)
        shape([(247, 53), (271, 54), (261, 67), (246, 69)], rose, width: 3.3)
        line([(231, 174), (253, 161), (270, 137)], ink, 3.4, 0.65)
    }

    func vane() {
        shape([(36, 205), (80, 177), (122, 178), (156, 168), (198, 175), (223, 165), (286, 195),
               (263, 217), (65, 219)], brown, width: 5.5)
        line([(53, 205), (98, 191), (130, 194), (163, 183), (206, 190), (254, 197)], gold, 3.7)
        line([(153, 174), (161, 110), (160, 61)], ink, 6)
        line([(85, 124), (159, 115), (239, 124)], ink, 5)
        shape([(240, 124), (216, 111), (221, 122), (216, 135)], gold, width: 3)
        shape([(126, 83), (115, 64), (121, 45), (136, 52), (144, 64), (165, 56), (177, 39),
               (194, 44), (204, 57), (194, 66), (181, 66), (169, 89), (147, 96)], rose, width: 5)
        shape([(186, 45), (189, 29), (197, 41), (204, 35), (204, 53)], gold, width: 3)
        line([(139, 71), (154, 78), (166, 67)], gold, 3.5)
    }

    func sunDog() {
        let halo = arc(160, 115, 79, 74, from: -2.80, to: 2.9)
        line(halo, rose, 8, 0.54)
        line(arc(160, 115, 73, 67, from: -2.74, to: 2.8), gold, 8, 0.75)
        shape(arc(160, 113, 34, 35, from: 0, to: .pi * 1.88), gold, edge: rose, width: 5)
        for (x, skew): (CGFloat, CGFloat) in [(62, -1), (259, 1)] {
            line([(x - 23, 126), (x, 112), (x + 22, 102)], gold, 11, 0.75)
            line([(x - 15, 129), (x + 2, 116), (x + skew * 20, 105)], cream, 6, 0.9)
        }
        line([(42, 181), (83, 166), (118, 173), (154, 160)], blue, 4.5, 0.63)
        line([(185, 185), (230, 173), (269, 181)], blue, 4.5, 0.61)
    }

    func aurora() {
        let ribbon: [Point] = [(25, 165), (55, 148), (72, 106), (100, 87), (130, 94), (160, 115),
                               (189, 114), (222, 79), (259, 65), (296, 80)]
        for (offset, pigment, width): (CGFloat, UIColor, CGFloat) in [(22, lavender, 23), (8, blue, 23), (-5, teal, 20)] {
            line(ribbon.map { ($0.0, $0.1 + offset) }, pigment, width, 0.59)
        }
        for (index, point) in ribbon.dropFirst().dropLast().enumerated() {
            line([(point.0 + 3, point.1 - 5), (point.0 - 3, point.1 - CGFloat(16 + (index * 13) % 27))],
                 index.isMultiple(of: 2) ? teal : lavender, 4, 0.55)
        }
        star(57, 72, 8)
        star(172, 57, 6)
        star(263, 142, 9)
    }

    func galaxy() {
        for (turn, color): (CGFloat, UIColor) in [(0, blue), (.pi, lavender), (.pi * 0.55, rose)] {
            let arm: [Point] = (0...32).map { index in
                let radius = CGFloat(index) * 3.9
                let angle = CGFloat(index) * 0.17 + turn
                return (159 + cos(angle) * radius, 122 + sin(angle) * radius * 0.63)
            }
            line(arm, color, 11, 0.70)
            line(arm.enumerated().filter { $0.offset.isMultiple(of: 3) }.map { $0.element }, cream, 2.6, 0.49)
        }
        shape(arc(159, 122, 22, 16, from: 0, to: .pi * 1.89), gold, edge: cream, width: 4.5)
        star(56, 77, 8)
        star(265, 75, 9)
        star(228, 178, 7)
        star(110, 180, 6)
    }

    func debris() {
        line([(26, 169), (66, 161), (101, 146), (139, 135), (175, 111), (221, 94), (255, 75), (292, 65)],
             lavender, 10, 0.40)
        for (x, y, size, color): (CGFloat, CGFloat, CGFloat, UIColor) in
            [(50, 154, 20, lavender), (103, 154, 13, brown), (147, 119, 25, blue), (197, 105, 14, rose),
             (227, 75, 17, brown), (267, 88, 10, lavender)] {
            shape([(x - size, y + size * 0.1), (x - size * 0.55, y - size * 0.75),
                   (x + size * 0.52, y - size * 0.62), (x + size, y + size * 0.27),
                   (x + size * 0.08, y + size * 0.74), (x - size * 0.67, y + size * 0.58)],
                  color, width: 3.5)
            line([(x - size * 0.45, y), (x, y - size * 0.23), (x + size * 0.43, y - size * 0.12)], cream, 2.8)
        }
        star(71, 104, 6)
        star(179, 174, 8)
        star(266, 132, 7)
    }

    private func arc(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, from: CGFloat, to: CGFloat) -> [Point] {
        (0...20).map { index in
            let angle = from + (to - from) * CGFloat(index) / 20
            let nudge = 1 + CGFloat(index % 4 - 2) * 0.018
            return (x + cos(angle) * rx * nudge, y + sin(angle) * ry * nudge)
        }
    }

    private func star(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat) {
        line([(x - size, y + 1), (x + size, y - 1)], cream, 3.4, 0.75)
        line([(x - 1, y - size), (x + 1, y + size)], gold, 3.2, 0.76)
    }

    private func shape(_ points: [Point], _ fill: UIColor, edge: UIColor? = nil,
                       width: CGFloat = 4.3, opacity: CGFloat = 0.86) {
        wax.shape(points, color: fill, border: edge ?? ink, width: width, opacity: opacity)
    }

    private func line(_ points: [Point], _ color: UIColor, _ width: CGFloat, _ opacity: CGFloat = 0.88) {
        wax.stroke(points, color: color, width: width, opacity: opacity)
    }
}
