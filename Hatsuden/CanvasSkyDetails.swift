import UIKit

enum CanvasSkyDetails {
    static func draw(_ subject: CanvasSubject, in context: CGContext) {
        Sketch(wax: WaxCrayon(context: context)).draw(subject)
    }

    private final class Sketch {
        private typealias Point = (CGFloat, CGFloat)

        private let wax: WaxCrayon
        private let cream = FieldInk.paper
        private let gold = UIColor(red: 0.98, green: 0.77, blue: 0.32, alpha: 1)
        private let coral = UIColor(red: 0.89, green: 0.42, blue: 0.41, alpha: 1)
        private let mint = UIColor(red: 0.48, green: 0.77, blue: 0.71, alpha: 1)
        private let ice = UIColor(red: 0.62, green: 0.82, blue: 0.93, alpha: 1)
        private let lilac = UIColor(red: 0.75, green: 0.57, blue: 0.83, alpha: 1)
        private let blue = UIColor(red: 0.28, green: 0.49, blue: 0.70, alpha: 1)
        private let plum = UIColor(red: 0.39, green: 0.30, blue: 0.57, alpha: 1)
        private let graphite = FieldInk.dark

        init(wax: WaxCrayon) {
            self.wax = wax
        }

        func draw(_ subject: CanvasSubject) {
            switch subject {
            case .hotAirBalloon:
                cloud(64, 162, 0.65)
                cloud(253, 105, 0.75)
                balloon(150, 106, 2.0, coral)
            case .diamondKite:
                kite(175, 88, 1.73, mint)
                line([(43, 129), (56, 127), (76, 131)], ice, 5)
                line([(234, 172), (256, 169), (271, 173)], cream, 4)
            case .propellerPlane:
                plane(170, 104, 1.83, coral)
            case .sunriseFlock:
                sunrise()
            case .thunderhead:
                thunderhead()
            case .rainbowArch:
                rainbow(160, 166)
                cloud(68, 166, 0.80)
                cloud(259, 170, 0.67)
            case .paperGlider:
                paperPlane(175, 100, 1.87, ice)
                line([(40, 184), (49, 188), (59, 187)], cream, 4)
                line([(65, 180), (82, 165), (92, 165)], cream, 4)
            case .hangGlider:
                glider(161, 104, 2.1, gold)
            case .blimp:
                blimp()
            case .rescueHelicopter:
                helicopter()
            case .meteorBelt:
                meteorBelt()
            case .flyingSaucer:
                saucer(161, 103, 2.12, lilac)
                star(61, 144, 9, cream)
                star(274, 97, 6, gold)
            case .weatherSatellite:
                weatherSatellite()
            case .constellationMap:
                constellationMap()
            case .spaceStation:
                station(158, 114, 1.92, coral)
            case .lunarRover:
                lunarRover()
            case .radioTelescope:
                observatory(166, 131, 1.95, mint)
            case .earthFromOrbit:
                orbit(165, 111, 113, 47, ice)
                globe(154, 113, 2.35, blue)
                star(267, 153, 6, gold)
            case .astronaut:
                astronaut()
            case .deepSpaceProbe:
                deepSpaceProbe()
            default:
                break
            }
        }

        private func sunrise() {
            disk(164, 115, 53, 47, fill: gold, edge: coral)
            let angles: [CGFloat] = [1, 1.18, 1.38, 1.58, 1.78, 1.96]
            for phase in angles {
                let directionX = cos(phase * .pi)
                let directionY = sin(phase * .pi)
                let inner: Point = (164 + 59 * directionX, 115 + 57 * directionY)
                let outer: Point = (162 + 77 * directionX, 114 + 68 * directionY)
                line([inner, outer], gold, 5.1)
            }
            cloud(160, 150, 1.93, fill: coral)
            birds(47, 77, 0.82)
            birds(195, 72, 0.94)
        }

        private func thunderhead() {
            cloud(161, 87, 2.03, fill: lilac)
            shape(159, 109, 1.3, [(0, 0), (21, 0), (9, 23), (25, 23), (-3, 67), (5, 34), (-12, 34)],
                  fill: gold, edge: coral)
            for (index, x) in [82.0, 106.0, 219.0, 247.0].enumerated() {
                let y = CGFloat(126 + (index % 3) * 10)
                line([(x, y), (x - 14, y + 30)], blue, 4)
                line([(x + 6, y + 32), (x - 2, y + 48)], ice, 3.2)
            }
        }

        private func blimp() {
            shape(158, 105, 1.15, [(-96, 3), (-82, -23), (-54, -37), (-13, -43),
                                  (42, -34), (78, -18), (96, 0), (82, 20), (46, 34),
                                  (3, 40), (-49, 32), (-83, 18)], fill: lilac, edge: plum)
            shape(158, 105, 1.15, [(-84, 1), (-110, -22), (-95, -29), (-61, -14),
                                  (-63, 15), (-96, 26)], fill: mint, edge: plum)
            line([(66, 106), (103, 93), (148, 91), (193, 99), (254, 107)], cream, 8)
            shape(152, 150, 1.15, [(-28, -8), (26, -10), (26, 8), (15, 17), (-20, 15)],
                  fill: gold, edge: plum)
            for x in [134.0, 151.0, 168.0] {
                line([(x, 154), (x + 5, 153)], blue, 5)
            }
        }

        private func helicopter() {
            line([(43, 95), (58, 114), (38, 124), (41, 93), (67, 99)], plum, 5)
            shape(167, 115, 1, [(-112, -15), (-39, -11), (-24, -27), (18, -31), (51, -18),
                               (68, 7), (53, 23), (-11, 23), (-28, 13), (-105, -6)],
                  fill: gold, edge: graphite)
            shape(167, 115, 1, [(10, -25), (46, -15), (59, 0), (6, -1)], fill: ice, edge: blue)
            line([(141, 135), (135, 156), (199, 157), (217, 147)], plum, 5)
            line([(183, 134), (185, 156)], plum, 5)
            line([(163, 86), (161, 68), (225, 63), (253, 58)], graphite, 4.7)
            line([(161, 68), (104, 74), (83, 76)], graphite, 4.7)
            line([(106, 56), (131, 55), (155, 53)], cream, 4)
            line([(214, 77), (249, 74), (272, 66)], cream, 4)
        }

        private func meteorBelt() {
            line([(35, 157), (70, 154), (98, 151), (140, 142)], ice, 4)
            line([(93, 143), (146, 124), (182, 108)], lilac, 7)
            line([(187, 82), (218, 72), (272, 52)], gold, 4)
            rock(113, 144, 51, coral)
            rock(203, 103, 33, lilac)
            rock(255, 68, 18, gold)
            rock(183, 172, 16, ice)
        }

        private func weatherSatellite() {
            shape(151, 120, 1.24, [(-20, -25), (20, -26), (29, -6), (20, 29), (-19, 28), (-27, -3)],
                  fill: mint, edge: cream)
            line([(127, 111), (170, 106), (178, 108)], blue, 8)
            line([(121, 137), (160, 136), (177, 130)], blue, 7)
            line([(160, 87), (192, 62), (218, 55)], cream, 5)
            shape(222, 59, 1.28, [(-27, -10), (-11, -14), (6, -11), (26, 1), (10, 16),
                                 (-7, 17), (-21, 9)], fill: ice, edge: plum)
            line([(220, 61), (234, 46), (244, 43)], gold, 4)
            line([(124, 117), (89, 108), (64, 88)], cream, 5)
            line([(176, 135), (217, 155), (261, 159)], cream, 4.5)
            star(57, 178, 8, ice)
        }

        private func constellationMap() {
            let dipper: [Point] = [(40, 145), (80, 115), (109, 121), (142, 100),
                                  (178, 108), (183, 151), (151, 160), (142, 100)]
            line(dipper, ice, 4.2, opacity: 0.85)
            for (index, point) in dipper.dropLast().enumerated() {
                star(point.0, point.1, index % 3 == 0 ? 11 : 7, index == 2 ? coral : gold)
            }
            let cross: [Point] = [(207, 60), (224, 86), (248, 80), (224, 86), (225, 118), (225, 141)]
            line(cross, lilac, 3.1)
            for point in [cross[0], cross[2], cross[4], cross[5]] { star(point.0, point.1, 7, cream) }
            star(267, 176, 5, ice)
        }

        private func lunarRover() {
            shape(158, 177, 1.05, [(-122, 6), (-70, -11), (-23, -2), (23, -8), (62, -1),
                                  (118, 13), (74, 25), (7, 25), (-52, 23), (-104, 21)],
                  fill: lilac, edge: ice, opacity: 0.75)
            shape(159, 121, 1, [(-72, 19), (-56, -4), (47, -8), (68, 7), (66, 22),
                                (-15, 24), (-64, 24)], fill: gold, edge: cream)
            for x in [105.0, 147.0, 194.0, 220.0] {
                disk(x, 145, 16, 17, fill: plum, edge: cream)
                disk(x, 145, 7, 8, fill: ice, edge: blue)
            }
            shape(152, 110, 1, [(-29, 0), (-14, -34), (24, -36), (38, -14), (31, 0)],
                  fill: coral, edge: cream)
            line([(148, 77), (140, 52), (125, 46)], cream, 4)
            shape(129, 47, 1, [(-22, -6), (17, -12), (10, 1), (-9, 8)], fill: ice, edge: plum)
            line([(204, 111), (222, 107)], cream, 6)
        }

        private func astronaut() {
            shape(147, 109, 1, [(-55, -22), (-33, -34), (-22, 12), (-29, 44), (-51, 36)],
                  fill: coral, edge: cream)
            shape(153, 127, 1, [(-38, -32), (-7, -40), (31, -30), (40, -6),
                                (27, 38), (5, 39), (-26, 25), (-42, 1)], fill: cream, edge: blue)
            shape(151, 153, 1, [(-31, -2), (-16, 6), (-16, 36), (-28, 53), (-49, 52),
                                (-46, 39), (-38, 26)], fill: cream, edge: blue)
            shape(151, 153, 1, [(12, 5), (29, -1), (45, 28), (56, 38), (52, 53), (29, 51), (24, 38)],
                  fill: cream, edge: blue)
            line([(117, 117), (98, 123), (78, 103), (65, 109)], cream, 16)
            line([(186, 117), (204, 123), (228, 92)], cream, 15)
            disk(65, 108, 10, 11, fill: coral, edge: blue)
            disk(229, 92, 11, 10, fill: coral, edge: blue)
            disk(149, 73, 41, 39, fill: cream, edge: ice)
            shape(150, 74, 1, [(-27, -13), (-11, -22), (13, -20), (28, -8), (22, 14),
                               (2, 22), (-18, 15), (-28, 4)], fill: blue, edge: plum)
            line([(132, 67), (148, 60), (160, 62)], ice, 5)
            shape(151, 128, 1, [(-15, -14), (13, -12), (11, 6), (-15, 7)], fill: lilac, edge: blue)
            line([(141, 126), (149, 126), (160, 124)], coral, 5)
            line([(186, 150), (216, 174), (255, 171), (281, 150), (298, 148)], ice, 4)
        }

        private func deepSpaceProbe() {
            shape(144, 121, 1.12, [(-25, -14), (-12, -24), (20, -20), (29, 2), (18, 20), (-17, 25)],
                  fill: gold, edge: cream)
            line([(111, 118), (63, 131), (42, 162)], cream, 4.7)
            line([(94, 121), (74, 143), (63, 131), (83, 123)], gold, 3.6)
            line([(174, 119), (225, 131), (266, 163)], cream, 4.8)
            line([(204, 126), (213, 145), (228, 133), (246, 149), (235, 152)], gold, 3.4)
            shape(162, 76, 1.0, [(-57, -8), (-34, -24), (10, -29), (49, -15), (61, 3),
                                (38, 14), (-11, 14), (-43, 3)], fill: cream, edge: ice)
            line([(123, 76), (146, 69), (177, 64), (202, 64)], blue, 4.8)
            line([(156, 104), (157, 72), (171, 45), (180, 32)], cream, 4.1)
            line([(163, 94), (183, 124), (173, 135)], coral, 6)
            star(84, 59, 7, gold)
            star(266, 95, 9, ice)
        }

        private func cloud(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, fill: UIColor? = nil) {
            shape(x, y, s, [(-50, 4), (-42, -8), (-27, -8), (-17, -20), (0, -17), (12, -26),
                             (28, -17), (32, -7), (47, -5), (54, 4), (44, 12), (18, 13),
                             (-2, 11), (-25, 14), (-46, 11)], fill: fill ?? cream, edge: blue, opacity: 0.79)
            line(x, y, s, [(-32, 4), (-11, 7), (9, 4), (30, 6)], fill == nil ? ice : cream, 3)
        }

        private func birds(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
            for i in 0..<4 {
                let center = x + CGFloat(i * 24) * s
                let height = y + [0, -8, -3, 9][i] * s
                line(center, height, s, [(-9, 1), (-4, -6), (0, -2), (3, 3), (7, -5), (13, -6)], graphite, 2.8)
            }
        }

        private func balloon(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(-24, -22), (-13, -34), (5, -37), (20, -27), (27, -12), (22, 6),
                             (10, 23), (-8, 23), (-22, 9), (-28, -8)], fill: ink, edge: plum)
            line(x, y, s, [(-9, -32), (-14, -14), (-11, 3), (-4, 21)], cream, 3)
            line(x, y, s, [(9, -33), (13, -17), (10, 4), (5, 21)], cream, 3)
            line(x, y, s, [(-8, 22), (-6, 34), (7, 34), (10, 22)], plum, 2.6)
            shape(x, y, s, [(-9, 33), (11, 33), (8, 45), (-6, 46)], fill: gold, edge: plum)
        }

        private func kite(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(7, -34), (34, -2), (0, 29), (-20, 1)], fill: ink, edge: plum)
            shape(x, y, s, [(7, -33), (34, -2), (6, -2)], fill: cream, edge: plum, opacity: 0.72)
            line(x, y, s, [(0, 29), (-4, 38), (-19, 49), (-27, 67), (-20, 77)], graphite, 2.5)
            line(x, y, s, [(-25, 48), (-18, 52), (-9, 54)], gold, 4)
            line(x, y, s, [(-34, 64), (-27, 69), (-20, 73)], coral, 4)
        }

        private func plane(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            line(x, y, s, [(-78, 21), (-60, 18), (-43, 15)], cream, 3)
            line(x, y, s, [(-73, 28), (-57, 25), (-46, 23)], ice, 2.5)
            shape(x, y, s, [(-46, 7), (-33, -8), (-23, 4), (17, -7), (38, -4),
                             (45, 5), (35, 13), (3, 16), (-33, 15)], fill: ink, edge: plum)
            shape(x, y, s, [(-6, 7), (-21, -21), (-8, -23), (22, 4), (16, 11)], fill: gold, edge: plum)
            shape(x, y, s, [(1, 11), (-14, 29), (0, 30), (24, 11)], fill: cream, edge: plum)
            line(x, y, s, [(39, -6), (41, 15)], plum, 3)
            line(x, y, s, [(46, 5), (53, 3), (51, -15), (55, -19), (57, 3), (55, 18), (51, 22)],
                 graphite, 4)
            disk(x + 52 * s, y + 4 * s, 3.4 * s, 3.4 * s, fill: gold, edge: graphite)
            line(x, y, s, [(21, 1), (30, 0)], cream, 4)
        }

        private func rainbow(_ x: CGFloat, _ y: CGFloat) {
            for (i, ink) in [coral, gold, mint, blue].enumerated() {
                let radius = CGFloat(83 - i * 8)
                let points = (0...8).map { i -> Point in
                    let angle = CGFloat(i) * .pi / 8
                    return (x + cos(angle) * radius, y - sin(angle) * radius * 0.88)
                }
                line(points, ink, 7)
            }
        }

        private func paperPlane(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(-34, -4), (42, -28), (16, 28), (-1, 9), (-16, 16), (-13, 5)],
                  fill: cream, edge: plum)
            shape(x, y, s, [(-13, 5), (42, -28), (-1, 9), (-16, 16)], fill: ink, edge: plum)
            line(x, y, s, [(-35, 17), (-46, 19), (-51, 23)], blue, 3)
            line(x, y, s, [(-57, 23), (-67, 25), (-72, 30)], blue, 3)
        }

        private func glider(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(-49, -3), (-31, -24), (-11, -32), (17, -28), (42, -12), (52, 3),
                             (24, -6), (-3, -8), (-29, -1)], fill: ink, edge: plum)
            line(x, y, s, [(-30, -21), (-18, -14), (-10, -7)], cream, 3)
            line(x, y, s, [(13, -27), (10, -17), (9, -8)], cream, 3)
            line(x, y, s, [(-43, -3), (5, 30), (46, 0)], graphite, 2.2)
            line(x, y, s, [(5, 26), (6, 38), (15, 41), (21, 47)], plum, 4)
            disk(x + 5 * s, y + 24 * s, 4 * s, 4 * s, fill: gold, edge: graphite)
        }

        private func orbit(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ ink: UIColor) {
            let points = (0...13).map { i -> Point in
                let angle = CGFloat(i) * .pi / 7.5
                return (x + cos(angle) * rx, y + sin(angle) * ry - cos(angle) * 12)
            }
            line(points, ink, 3, opacity: 0.63)
        }

        private func rock(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ ink: UIColor) {
            let points = (0..<9).map { i -> Point in
                let angle = CGFloat(i) * .pi * 2 / 9
                let length = radius * [1.02, 0.91, 1.16, 0.96, 0.88, 1.09, 0.83, 1.05, 1.13][i]
                return (x + cos(angle) * length, y + sin(angle) * length * 0.73)
            }
            wax.shape(points, color: ink, border: plum, width: 3.7, opacity: 0.82)
            disk(x - radius * 0.28, y - radius * 0.08, radius * 0.22, radius * 0.14, fill: lilac, edge: plum)
            if radius > 25 {
                disk(x + radius * 0.38, y + radius * 0.14, radius * 0.18, radius * 0.11, fill: cream, edge: plum)
                line([(x - radius * 0.71, y + radius * 0.19), (x - radius * 0.28, y + radius * 0.30),
                      (x + radius * 0.02, y + radius * 0.31)], cream, 3)
            }
        }

        private func saucer(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(-9, 17), (15, 16), (30, 50), (-21, 51)], fill: mint, edge: ice, opacity: 0.60)
            shape(x, y, s, [(-22, -8), (-17, -24), (-3, -30), (14, -25), (24, -10)],
                  fill: ice, edge: plum)
            shape(x, y, s, [(-42, -2), (-23, -11), (13, -13), (37, -6), (45, 3), (30, 15),
                             (0, 19), (-26, 14), (-44, 7)], fill: ink, edge: plum)
            for dx in [-21.0, 0, 20] {
                disk(x + dx * s, y + 4 * s, 3.2 * s, 2.8 * s, fill: gold, edge: cream)
            }
            line(x, y, s, [(-13, -19), (-4, -23), (4, -22)], cream, 3)
        }

        private func panel(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
            shape(x, y, s, [(-24, -5), (15, -17), (25, 4), (-15, 15)], fill: blue, edge: ice)
            line(x, y, s, [(-10, -9), (-1, 11)], ice, 2.4)
            line(x, y, s, [(4, -13), (12, 7)], ice, 2.4)
            line(x, y, s, [(-19, 5), (20, -6)], ice, 2.1)
        }

        private func station(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            panel(x - 44 * s, y - 16 * s, s * 0.81)
            panel(x + 45 * s, y + 10 * s, s * 0.79)
            line(x, y, s, [(-45, -15), (0, -4), (43, 12)], cream, 5)
            shape(x, y, s, [(-19, -15), (1, -20), (18, -8), (20, 13), (-4, 20), (-20, 7)],
                  fill: ink, edge: cream)
            shape(x, y, s, [(-6, -30), (8, -32), (12, -17), (-3, -12)], fill: ice, edge: plum)
            line(x, y, s, [(-10, 0), (0, -1), (10, 3)], cream, 4)
        }

        private func observatory(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            shape(x, y, s, [(-46, 27), (5, 17), (33, 28), (47, 34), (21, 43), (-30, 40)],
                  fill: lilac, edge: ice, opacity: 0.70)
            line(x, y, s, [(-17, 32), (-4, 3), (16, 32)], cream, 5)
            shape(x, y, s, [(-17, -6), (15, -31), (25, -22), (-6, 5)],
                  fill: ink, edge: cream)
            line(x, y, s, [(14, -33), (28, -21)], cream, 4)
        }

        private func globe(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ink: UIColor) {
            disk(x, y, 33 * s, 30 * s, fill: ink, edge: ice)
            shape(x, y, s, [(-26, -9), (-17, -22), (-6, -23), (-3, -12), (10, -8), (4, 1),
                             (-5, 5), (-12, 15), (-20, 8)], fill: mint, edge: blue)
            shape(x, y, s, [(13, 9), (23, 2), (28, 10), (22, 18), (13, 20), (8, 15)], fill: mint, edge: blue)
            line(x, y, s, [(-19, 18), (-4, 24), (10, 24)], cream, 3)
        }

        private func disk(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                          fill: UIColor, edge: UIColor) {
            let points = (0..<9).map { i -> Point in
                let angle = CGFloat(i) * .pi * 2 / 9
                return (x + cos(angle) * rx, y + sin(angle) * ry)
            }
            wax.shape(points, color: fill, border: edge, width: max(1.6, min(4, rx * 0.12)), opacity: 0.86)
        }

        private func star(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ ink: UIColor) {
            line([(x - r, y + 1), (x, y), (x + r, y - 1)], ink, 2.7)
            line([(x - 1, y - r), (x, y), (x + 1, y + r)], ink, 2.5)
        }

        private func shape(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ points: [Point],
                           fill: UIColor, edge: UIColor, opacity: CGFloat = 0.90) {
            wax.shape(points.map { (x + $0.0 * s, y + $0.1 * s) },
                      color: fill, border: edge, width: max(2, 3.2 * s), opacity: opacity)
        }

        private func line(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ points: [Point],
                          _ ink: UIColor, _ width: CGFloat, opacity: CGFloat = 0.89) {
            line(points.map { (x + $0.0 * s, y + $0.1 * s) }, ink, max(1.5, width * s), opacity: opacity)
        }

        private func line(_ points: [Point], _ ink: UIColor, _ width: CGFloat, opacity: CGFloat = 0.89) {
            wax.stroke(points, color: ink, width: width, opacity: opacity)
        }
    }
}
