import UIKit

@MainActor
enum GardenBackdrop {
    static func draw(_ motif: FieldMotif, in context: CGContext) {
        Painter(context: context).draw(motif)
    }

    private struct Painter {
        private typealias Point = (CGFloat, CGFloat)
        private let wax: WaxCrayon
        private let meadow = UIColor(red: 0.56, green: 0.70, blue: 0.37, alpha: 1)
        private let leaf = UIColor(red: 0.29, green: 0.52, blue: 0.28, alpha: 1)
        private let soil = UIColor(red: 0.73, green: 0.52, blue: 0.32, alpha: 1)
        private let bark = UIColor(red: 0.47, green: 0.32, blue: 0.27, alpha: 1)
        private let coral = UIColor(red: 0.85, green: 0.39, blue: 0.46, alpha: 1)
        private let lilac = UIColor(red: 0.57, green: 0.43, blue: 0.74, alpha: 1)

        init(context: CGContext) { wax = WaxCrayon(context: context) }

        func draw(_ motif: FieldMotif) {
            switch motif {
            case .hive: hive()
            case .gardenFence: fence()
            case .flowerPatch: meadowFlowers()
            default: break
            }
        }

        private func fence() {
            for y: CGFloat in [575, 662] {
                for (left, right): (CGFloat, CGFloat) in [(-21, 501), (613, 1_017)] {
                    wax.shape([(left, y + 6), (left + (right - left) * 0.48, y + 11),
                               (right, y - 7), (right, y + 24), (left, y + 36)],
                              color: FieldInk.yellow, border: soil, width: 6, opacity: 0.62)
                }
            }
            for (index, x): (Int, CGFloat) in [18, 98, 175, 257, 340, 415, 489, 625, 701, 784, 862, 944, 1_013].enumerated() {
                let y = CGFloat(528 + (index * 11) % 38)
                wax.shape([(x - 16, y + 174), (x - 20, y + 24), (x + 1, y - 2),
                           (x + 18, y + 25), (x + 16, y + 173), (x - 2, y + 178)],
                          color: FieldInk.paper, border: bark, width: 5.5, opacity: 0.69)
                wax.stroke([(x - 2, y + 51), (x + 3, y + 79), (x + 1, y + 110)],
                           color: soil, width: 3, opacity: 0.51)
            }
            wax.stroke([(501, 732), (524, 704), (549, 723), (579, 709), (600, 735)],
                       color: bark, width: 10, opacity: 0.48)
        }

        private func hive() {
            func place(_ points: [Point]) -> [Point] { points.map { ($0.0 + 190, $0.1) } }
            wax.shape(place([(143, 1_024), (167, 991), (226, 978), (333, 989), (377, 1_019),
                             (342, 1_055), (225, 1_064), (168, 1_050)]),
                      color: meadow, border: leaf, width: 5, opacity: 0.46)
            for x: CGFloat in [188, 321] {
                wax.shape(place([(x - 13, 1_044), (x - 15, 947), (x + 14, 946), (x + 17, 1_035),
                                 (x + 4, 1_052)]), color: soil, border: bark, width: 8, opacity: 0.87)
            }
            wax.shape(place([(157, 843), (352, 838), (353, 978), (298, 987), (181, 982), (153, 964)]),
                      color: FieldInk.yellow, border: bark, width: 10, opacity: 0.92)
            wax.shape(place([(135, 849), (176, 804), (248, 750), (312, 775), (374, 828),
                             (372, 857), (282, 845), (201, 862), (141, 868)]),
                      color: coral, border: bark, width: 10, opacity: 0.87)
            for y: CGFloat in [882, 923, 960] {
                wax.stroke(place([(169, y + 3), (214, y), (267, y + 4), (334, y - 4)]),
                           color: soil, width: 6, opacity: 0.70)
            }
            wax.shape(place([(222, 962), (229, 936), (249, 925), (273, 932), (287, 960)]),
                      color: bark, border: FieldInk.dark, width: 6, opacity: 0.96)
            wax.stroke(place([(216, 968), (260, 965), (293, 970)]), color: bark, width: 10, opacity: 0.9)
            for (x, y) in [(381.0, 915.0), (408, 897), (433, 867)] {
                wax.stroke(place([(x, y), (x + 11, y - 5)]), color: soil, width: 4, opacity: 0.48)
            }
        }

        private func meadowFlowers() {
            let blooms: [(CGFloat, CGFloat, CGFloat, UIColor)] = [
                (309, 889, 0.63, coral), (611, 894, 0.88, lilac), (667, 976, 0.68, FieldInk.yellow),
                (88, 1_132, 0.78, coral), (189, 1_218, 1.08, lilac), (345, 1_118, 0.88, FieldInk.yellow),
                (428, 1_268, 0.95, coral), (55, 1_357, 0.87, lilac), (247, 1_452, 1.25, coral),
                (377, 1_553, 1.05, FieldInk.yellow), (100, 1_620, 1.09, lilac), (523, 1_648, 0.83, coral),
                (103, 1_801, 0.79, coral), (314, 1_800, 1.21, lilac), (450, 1_876, 0.93, FieldInk.yellow),
                (799, 1_040, 0.74, FieldInk.yellow), (894, 1_162, 1.02, lilac), (978, 1_304, 0.84, coral)
            ]
            for (index, flower) in blooms.enumerated() {
                let (x, y, s, color) = flower
                let lean: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                func place(_ points: [Point]) -> [Point] { points.map { (x + $0.0 * s * lean, y + $0.1 * s) } }
                wax.stroke(place([(20, 105), (6, 72), (4, 44), (0, 8)]), color: leaf, width: 9 * s, opacity: 0.83)
                wax.shape(place([(7, 63), (32, 43), (54, 45), (43, 61), (21, 74)]),
                          color: meadow, border: leaf, width: 4 * s, opacity: 0.8)
                wax.shape(place([(9, 54), (-13, 35), (-29, 31), (-24, 50), (-7, 59)]),
                          color: meadow, border: leaf, width: 4 * s, opacity: 0.73)
                wax.shape(place([(-13, -17), (-29, -20), (-36, -6), (-23, 7), (-27, 21),
                                 (-14, 30), (-1, 21), (11, 30), (25, 23), (25, 9),
                                 (37, -3), (31, -18), (15, -18), (5, -32), (-8, -29)]),
                          color: color, border: color, width: 5 * s, opacity: 0.88)
                wax.shape(place([(-9, -7), (0, -10), (10, -3), (8, 7), (-1, 12), (-12, 5)]),
                          color: FieldInk.yellow, border: FieldInk.orange, width: 4 * s, opacity: 0.96)
            }
        }
    }
}
