import UIKit

@MainActor
enum SpaceBackdrop {
    static func draw(_ motif: FieldMotif, in context: CGContext) {
        SpacePainter(wax: WaxCrayon(context: context)).draw(motif)
    }
}

private struct SpacePainter {
    private typealias P = (CGFloat, CGFloat)
    let wax: WaxCrayon
    private let cream = FieldInk.paper
    private let dust = UIColor(red: 0.74, green: 0.56, blue: 0.84, alpha: 1)
    private let rose = UIColor(red: 0.87, green: 0.55, blue: 0.69, alpha: 1)
    private let teal = UIColor(red: 0.38, green: 0.65, blue: 0.77, alpha: 1)
    private let ice = UIColor(red: 0.67, green: 0.87, blue: 0.91, alpha: 1)

    func draw(_ motif: FieldMotif) {
        switch motif {
        case .nebula: nebula()
        case .comet: comet()
        case .icePlanet: moon()
        default: break
        }
    }

    private func nebula() {
        let cloud: [P] = [(-37, 1_037), (156, 942), (299, 909), (442, 759), (556, 652),
                          (718, 514), (876, 506), (1_043, 401), (1_080, 617), (908, 681),
                          (745, 762), (599, 867), (496, 1_021), (300, 1_058), (169, 1_185), (-25, 1_266)]
        wax.fill(cloud, color: dust, opacity: 0.69)
        let trail: [P] = [(-15, 1_179), (185, 1_078), (315, 991), (479, 889), (592, 747),
                          (745, 649), (906, 589), (1_024, 522)]
        wax.stroke(trail, color: rose, width: 35, opacity: 0.57)
        wax.stroke(trail.map { ($0.0 - 14, $0.1 - 32) }, color: ice, width: 13, opacity: 0.47)

        // Crooked spiral arms drawn over the dust.
        let curl: [P] = [(808, 748), (767, 670), (780, 587), (832, 519), (901, 506),
                         (947, 538), (966, 586), (940, 633), (883, 648), (838, 622), (841, 576),
                         (875, 548), (920, 559), (931, 598), (900, 616), (870, 590), (897, 577)]
        wax.stroke(curl, color: cream, width: 10, opacity: 0.72)
        wax.stroke(curl.map { ($0.0 + 13, $0.1 - 9) }, color: rose, width: 8, opacity: 0.69)
    }

    private func comet() {
        let tail: [P] = [(286, 1_725), (357, 1_661), (461, 1_584), (570, 1_473), (638, 1_425)]
        wax.stroke(tail, color: rose, width: 34, opacity: 0.78)
        wax.stroke(tail.map { ($0.0 + 16, $0.1 + 3) }, color: ice, width: 21, opacity: 0.83)
        wax.stroke([(362, 1_715), (445, 1_660), (526, 1_556), (618, 1_460)],
                   color: cream, width: 12, opacity: 0.90)
        wax.shape([(622, 1_427), (632, 1_399), (669, 1_381), (695, 1_405), (695, 1_435),
                   (673, 1_463), (638, 1_456)],
                  color: FieldInk.yellow, border: cream, width: 10, opacity: 0.96)
        wax.stroke([(643, 1_420), (661, 1_406), (676, 1_405)], color: cream, width: 8, opacity: 0.82)
    }

    private func moon() {
        wax.shape([(752, 1_710), (759, 1_660), (792, 1_613), (842, 1_589), (895, 1_599),
                   (942, 1_641), (956, 1_692), (945, 1_750), (904, 1_789), (854, 1_806),
                   (797, 1_789), (767, 1_761)],
                  color: ice, border: teal, width: 13, opacity: 0.94)
        for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(818, 1_668, 20), (902, 1_717, 29), (837, 1_755, 13)] {
            wax.shape([(x - r, y), (x - r * 0.64, y - r * 0.56), (x + r * 0.35, y - r * 0.66),
                       (x + r, y - 1), (x + r * 0.76, y + r * 0.49), (x, y + r * 0.59)],
                      color: teal, border: teal, width: 5, opacity: 0.68)
        }
        wax.stroke([(782, 1_705), (794, 1_660), (821, 1_633), (865, 1_617)],
                   color: cream, width: 9, opacity: 0.78)
    }
}
