import UIKit

@MainActor
enum NeighborhoodBackdrop {
    static func draw(_ motif: FieldMotif, in context: CGContext) {
        NeighborhoodPainter(wax: WaxCrayon(context: context)).draw(motif)
    }
}

private struct NeighborhoodPainter {
    private typealias P = (CGFloat, CGFloat)
    let wax: WaxCrayon
    private let cream = FieldInk.paper
    private let ink = UIColor(red: 0.29, green: 0.25, blue: 0.28, alpha: 1)
    private let blue = UIColor(red: 0.27, green: 0.53, blue: 0.79, alpha: 1)
    private let paleBlue = UIColor(red: 0.54, green: 0.73, blue: 0.88, alpha: 1)
    private let fern = UIColor(red: 0.38, green: 0.62, blue: 0.37, alpha: 1)
    private let mint = UIColor(red: 0.27, green: 0.59, blue: 0.44, alpha: 1)
    private let rose = UIColor(red: 0.80, green: 0.30, blue: 0.32, alpha: 1)
    private let honey = UIColor(red: 0.92, green: 0.64, blue: 0.31, alpha: 1)
    private let sand = UIColor(red: 0.77, green: 0.62, blue: 0.46, alpha: 1)

    func draw(_ motif: FieldMotif) {
        switch motif {
        case .neighborhood:
            houses()
        case .railway:
            bridge()
            train()
        default: break
        }
    }

    private func houses() {
        home(x: 57, y: 685, scale: 1.04, roof: rose)
        home(x: 227, y: 636, scale: 0.83, roof: blue)
        home(x: 359, y: 722, scale: 1.16, roof: honey)
        home(x: 561, y: 651, scale: 0.74, roof: rose)
        home(x: 747, y: 691, scale: 1.12, roof: blue)
        home(x: 909, y: 753, scale: 0.75, roof: rose)
        tree(x: 26, y: 850, scale: 0.8)
        tree(x: 312, y: 874, scale: 0.86)
        tree(x: 692, y: 868, scale: 1.05)

        // A cat with crooked ears watches from the orange roof.
        wax.shape([(430, 747), (426, 730), (434, 711), (448, 706), (460, 719),
                   (463, 739), (476, 744), (481, 757), (457, 760), (439, 754)],
                  color: honey, border: ink, width: 5.8, opacity: 0.91)
        wax.shape([(424, 726), (419, 715), (418, 698), (428, 704), (436, 703),
                   (445, 695), (449, 708), (445, 721), (438, 729)],
                  color: honey, border: ink, width: 5.4, opacity: 0.93)
        wax.stroke([(475, 748), (491, 735), (495, 719), (490, 712)],
                   color: ink, width: 6.3, opacity: 0.86)
        wax.stroke([(426, 715), (429, 715)], color: ink, width: 3.5, opacity: 0.91)
        wax.stroke([(437, 715), (440, 714)], color: ink, width: 3.5, opacity: 0.91)
    }

    private func home(x: CGFloat, y: CGFloat, scale: CGFloat, roof: UIColor) {
        func points(_ local: [P]) -> [P] { local.map { (x + $0.0 * scale, y + $0.1 * scale) } }
        wax.shape(points([(10, 74), (132, 77), (128, 175), (15, 181)]),
                  color: honey, border: sand, width: 6 * scale, opacity: 0.66)
        wax.shape(points([(1, 76), (37, 35), (73, 8), (103, 36), (148, 78), (89, 82), (41, 79)]),
                  color: roof, border: ink, width: 6 * scale, opacity: 0.86)
        wax.stroke(points([(28, 66), (68, 30), (91, 47), (117, 69)]),
                   color: cream, width: 4 * scale, opacity: 0.54)
        for dx: CGFloat in [28, 94] {
            wax.shape(points([(dx, 104), (dx + 25, 100), (dx + 27, 132), (dx + 1, 134)]),
                      color: paleBlue, border: ink, width: 4 * scale, opacity: 0.76)
            wax.stroke(points([(dx + 12, 105), (dx + 13, 131)]), color: cream, width: 3, opacity: 0.84)
        }
        wax.shape(points([(58, 172), (59, 128), (69, 119), (82, 122), (84, 175)]),
                  color: sand, border: ink, width: 4 * scale, opacity: 0.70)
    }

    private func tree(x: CGFloat, y: CGFloat, scale: CGFloat) {
        func points(_ local: [P]) -> [P] { local.map { (x + $0.0 * scale, y + $0.1 * scale) } }
        wax.stroke(points([(-2, 13), (1, -35), (-5, -56)]), color: sand, width: 11 * scale, opacity: 0.87)
        wax.shape(points([(-38, -41), (-49, -59), (-37, -83), (-21, -88), (-12, -109), (13, -112),
                          (32, -100), (36, -82), (49, -74), (46, -53), (31, -40), (6, -47), (-14, -37)]),
                  color: fern, border: mint, width: 7 * scale, opacity: 0.85)
    }

    private func bridge() {
        for (x, y): P in [(168, 1_183), (431, 1_168), (691, 1_145), (909, 1_125)] {
            wax.shape([(x - 17, y), (x + 21, y - 3), (x + 27, y + 115),
                       (x + 3, y + 125), (x - 27, y + 117)],
                      color: sand, border: ink, width: 6.5, opacity: 0.78)
        }
        let deck: [P] = [(-28, 1_151), (198, 1_128), (469, 1_115), (733, 1_096), (1_032, 1_070)]
        wax.shape(deck + [(1_034, 1_127), (737, 1_151), (458, 1_175), (192, 1_190), (-30, 1_209)],
                  color: sand, border: ink, width: 9, opacity: 0.89)
        wax.stroke(deck.map { ($0.0, $0.1 + 19) }, color: cream, width: 7, opacity: 0.71)
    }

    private func train() {
        for (x, y, front): (CGFloat, CGFloat, Bool) in [(162, 1_121, false), (391, 1_105, false), (623, 1_089, true)] {
            let body: [P] = [(x, y - 83), (x + 32, y - 108), (x + 175, y - 112),
                             (x + (front ? 202 : 207), y - 97), (x + 214, y - (front ? 63 : 70)),
                             (x + 211, y - 11), (x + 130, y - 7), (x + 7, y)]
            wax.shape(body, color: mint, border: ink, width: 8.4, opacity: 0.94)
            wax.stroke([(x + 14, y - 25), (x + 92, y - 30), (x + 198, y - 34)],
                       color: FieldInk.yellow, width: 9, opacity: 0.92)
            for dx: CGFloat in [25, 83, 141] {
                wax.shape([(x + dx, y - 80), (x + dx + 41, y - 83),
                           (x + dx + 42, y - 47), (x + dx - 1, y - 44)],
                          color: paleBlue, border: ink, width: 5.6, opacity: 0.90)
                wax.stroke([(x + dx + 8, y - 73), (x + dx + 19, y - 75)], color: cream, width: 3.5, opacity: 0.81)
            }
            for dx: CGFloat in [47, 165] {
                wax.shape([(x + dx - 12, y - 5), (x + dx + 13, y - 6), (x + dx + 15, y + 9),
                           (x + dx, y + 16), (x + dx - 13, y + 9)],
                          color: ink, border: ink, width: 5, opacity: 0.91)
            }
        }
        wax.stroke([(853, 1_041), (883, 1_024)], color: honey, width: 5, opacity: 0.73)
        wax.stroke([(859, 1_058), (890, 1_057)], color: honey, width: 5, opacity: 0.73)
    }
}
