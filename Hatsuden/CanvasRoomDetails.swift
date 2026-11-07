import UIKit

enum CanvasRoomDetails {
    static func draw(_ subject: CanvasSubject, in context: CGContext) {
        let room = Room(wax: WaxCrayon(context: context))
        switch subject {
        case .roomRug: room.rug()
        case .roomWindow: room.window()
        case .computer: room.computer()
        case .bookshelf: room.bookshelf()
        case .deskLamp: room.lamp()
        case .toyTrain: room.train()
        case .armchair: room.armchair()
        case .wallClock: room.clock()
        case .radio: room.radio()
        case .teacup: room.teacup()
        case .pottedCactus: room.cactus()
        case .slippers: room.slippers()
        case .pictureFrame: room.picture()
        case .pencilCup: room.pencils()
        case .globe: room.globe()
        case .kettle: room.kettle()
        case .catBed: room.catBed()
        case .sewingMachine: room.sewingMachine()
        case .umbrellaStand: room.umbrellas()
        case .doorway: room.doorway()
        default: break
        }
    }
}

private struct Room {
    typealias Point = (CGFloat, CGFloat)

    let wax: WaxCrayon
    private let cocoa = UIColor(red: 0.40, green: 0.25, blue: 0.22, alpha: 1)
    private let wood = UIColor(red: 0.73, green: 0.47, blue: 0.29, alpha: 1)
    private let orange = UIColor(red: 0.90, green: 0.53, blue: 0.31, alpha: 1)
    private let straw = UIColor(red: 0.95, green: 0.73, blue: 0.42, alpha: 1)
    private let yellow = UIColor(red: 0.97, green: 0.82, blue: 0.31, alpha: 1)
    private let coral = UIColor(red: 0.84, green: 0.40, blue: 0.43, alpha: 1)
    private let pink = UIColor(red: 0.91, green: 0.62, blue: 0.63, alpha: 1)
    private let purple = UIColor(red: 0.61, green: 0.43, blue: 0.73, alpha: 1)
    private let blue = UIColor(red: 0.44, green: 0.69, blue: 0.80, alpha: 1)
    private let navy = UIColor(red: 0.28, green: 0.42, blue: 0.58, alpha: 1)
    private let leaf = UIColor(red: 0.44, green: 0.65, blue: 0.40, alpha: 1)
    private let cream = FieldInk.paper

    func rug() {
        shape([(25, 123), (42, 83), (96, 64), (162, 62), (240, 69), (283, 91), (300, 126),
               (279, 160), (227, 176), (152, 182), (82, 173), (42, 153)],
              purple, edge: purple, width: 6, opacity: 0.81)
        line([(48, 122), (67, 94), (111, 84), (173, 80), (233, 90), (271, 109), (277, 131),
              (249, 153), (191, 165), (118, 161), (73, 149), (48, 122)], pink, 4, 0.87)
        for (x, y, dx): (CGFloat, CGFloat, CGFloat) in [(40, 105, -17), (37, 119, -20), (40, 136, -18),
                                                        (282, 103, 19), (288, 117, 21), (285, 142, 17)] {
            line([(x, y), (x + dx * 0.6, y + 1), (x + dx, y + 6)], purple, 3.7, 0.66)
        }
        line([(85, 128), (119, 115), (149, 132), (180, 115), (213, 130), (239, 121)], coral, 5, 0.69)
    }

    func window() {
        shape([(70, 36), (245, 31), (255, 171), (70, 178)], straw, width: 6)
        shape([(84, 49), (234, 48), (241, 158), (85, 164)], blue, width: 5)
        shape([(87, 142), (112, 121), (130, 117), (162, 143), (202, 127), (236, 142), (241, 161), (85, 165)],
              leaf, edge: leaf, width: 2.5, opacity: 0.67)
        line([(101, 89), (113, 82), (126, 84), (133, 77), (146, 85), (153, 85)], cream, 6, 0.90)
        line([(161, 48), (166, 104), (163, 158)], wood, 6)
        line([(86, 103), (150, 101), (196, 106), (237, 103)], wood, 6)
        shape([(55, 40), (92, 29), (107, 38), (99, 86), (88, 116), (78, 170), (48, 165), (60, 117)],
              coral, width: 4)
        shape([(216, 37), (250, 29), (265, 38), (263, 94), (278, 160), (246, 173), (235, 109)],
              coral, width: 4)
        line([(68, 54), (74, 91), (63, 131), (58, 151)], pink, 5, 0.83)
        line([(242, 49), (246, 83), (252, 120), (261, 150)], pink, 5, 0.83)
        shape([(59, 176), (170, 177), (260, 172), (271, 185), (66, 193)], straw, width: 5)
    }

    func computer() {
        shape([(33, 148), (65, 148), (59, 218), (40, 220)], wood, width: 5)
        shape([(257, 146), (282, 145), (291, 214), (274, 220)], wood, width: 5)
        shape([(28, 127), (73, 118), (248, 118), (294, 131), (291, 153), (38, 156)],
              straw, width: 6)
        shape([(86, 21), (210, 20), (229, 31), (225, 107), (83, 108)], cream, width: 6)
        shape([(95, 31), (206, 30), (213, 40), (212, 91), (95, 94)], navy, width: 4)
        line([(104, 78), (127, 58), (151, 71), (181, 51), (202, 60)], blue, 5, 0.85)
        oval(199, 41, 6, 5, yellow, edge: yellow)
        line([(156, 107), (156, 118), (137, 120), (179, 119)], cocoa, 6)
        shape([(81, 132), (189, 129), (207, 143), (80, 147)], cream, width: 3)
        for x in stride(from: 94.0, through: 185.0, by: 13.0) {
            line([(x, 135), (x + 3, 141)], wood, 2.5, 0.76)
        }
        oval(242, 135, 15, 9, coral)
        line([(238, 132), (239, 124), (226, 119)], cocoa, 2.5, 0.72)
    }

    func bookshelf() {
        shape([(66, 24), (243, 18), (252, 221), (66, 218)], wood, width: 7)
        shape([(78, 36), (230, 32), (238, 198), (80, 199)], straw, width: 4)
        for y: CGFloat in [91, 149] {
            line([(77, y), (136, y + 2), (187, y - 1), (235, y + 1)], cocoa, 6)
        }
        let books: [(CGFloat, CGFloat, CGFloat, CGFloat, UIColor)] = [
            (86, 52, 17, 35, blue), (105, 47, 18, 40, purple), (125, 56, 14, 31, coral),
            (145, 49, 24, 38, leaf), (182, 48, 21, 39, orange), (206, 59, 18, 28, pink),
            (91, 108, 20, 37, coral), (117, 114, 16, 30, leaf), (138, 103, 21, 40, blue),
            (171, 118, 17, 26, purple), (191, 109, 23, 35, orange), (217, 113, 12, 31, coral)
        ]
        for (x, y, w, h, color) in books {
            shape([(x, y), (x + w, y - 2), (x + w + 1, y + h), (x + 1, y + h)], color, width: 2.8)
            line([(x + 5, y + 9), (x + w - 3, y + 8)], cream, 2.7, 0.77)
        }
        shape([(88, 174), (138, 170), (171, 176), (171, 194), (90, 194)], purple, width: 4)
        oval(207, 175, 15, 19, coral)
        line([(205, 162), (209, 151), (216, 154)], leaf, 4)
    }

    func lamp() {
        oval(152, 197, 61, 14, purple)
        line([(150, 190), (157, 140), (115, 96), (145, 54)], cocoa, 10)
        line([(150, 187), (159, 142), (120, 98), (146, 59)], pink, 4)
        shape([(151, 34), (192, 40), (211, 83), (138, 81)], coral, width: 5)
        oval(175, 83, 37, 10, yellow, edge: orange)
        line([(154, 102), (147, 125)], straw, 5, 0.66)
        line([(189, 105), (200, 130)], straw, 5, 0.66)
        line([(173, 105), (172, 140)], yellow, 4, 0.64)
        line([(183, 200), (209, 211), (248, 201), (268, 206)], cocoa, 3.5)
    }

    func train() {
        line([(32, 182), (89, 187), (149, 183), (223, 186), (285, 179)], wood, 7)
        shape([(43, 113), (90, 111), (91, 149), (106, 151), (106, 171), (43, 173)], coral, width: 5)
        shape([(80, 134), (110, 133), (118, 144), (119, 165), (91, 171)], orange, width: 4)
        line([(109, 136), (108, 110), (118, 111)], cocoa, 5)
        shape([(53, 122), (72, 121), (74, 137), (53, 138)], blue, width: 3)
        shape([(133, 134), (189, 137), (186, 167), (136, 169)], yellow, width: 4)
        shape([(210, 127), (256, 124), (267, 140), (262, 168), (208, 167)], leaf, width: 4)
        for x: CGFloat in [53, 77, 108, 143, 178, 220, 250] { oval(x, 173, 9, 9, navy) }
        line([(118, 155), (133, 154)], cocoa, 4)
        line([(186, 153), (208, 152)], cocoa, 4)
        line([(113, 101), (128, 94), (124, 82), (146, 75)], purple, 4, 0.61)
    }

    func armchair() {
        shape([(67, 185), (81, 185), (77, 212), (64, 216)], wood, width: 4)
        shape([(228, 181), (245, 180), (255, 208), (239, 213)], wood, width: 4)
        shape([(64, 69), (82, 38), (223, 42), (244, 64), (239, 159), (78, 157)], blue, width: 7)
        shape([(57, 119), (82, 113), (98, 136), (223, 138), (230, 113), (254, 115), (265, 141),
               (255, 184), (230, 197), (82, 190), (58, 171)], navy, width: 6)
        shape([(91, 137), (228, 137), (242, 156), (223, 174), (92, 169), (77, 154)], blue, width: 5)
        shape([(107, 83), (154, 64), (184, 82), (185, 120), (133, 129), (103, 112)], yellow, width: 4)
        line([(117, 95), (142, 87), (165, 103)], orange, 4, 0.74)
    }

    func clock() {
        oval(160, 117, 81, 80, coral, edge: cocoa, width: 8)
        oval(161, 116, 66, 64, cream, edge: wood, width: 4.5)
        for tick in 0..<12 {
            let angle = CGFloat(tick) * .pi / 6
            line([(161 + cos(angle) * 54, 117 + sin(angle) * 54),
                  (161 + cos(angle) * 60, 117 + sin(angle) * 59)], cocoa, 3.5)
        }
        line([(136, 91), (161, 118), (195, 101)], navy, 6)
        oval(161, 117, 7, 7, yellow)
        line([(150, 37), (158, 23), (174, 34)], wood, 5)
    }

    func radio() {
        line([(226, 92), (260, 49), (286, 29)], cocoa, 5)
        line([(110, 88), (119, 64), (183, 63), (201, 83)], cocoa, 6)
        shape([(55, 88), (254, 83), (267, 101), (263, 179), (59, 184), (47, 168)], coral, width: 6)
        oval(101, 136, 29, 31, wood)
        for x: CGFloat in [86, 96, 106, 116] {
            line([(x, 123), (x - 2, 150)], cream, 3, 0.67)
        }
        shape([(145, 109), (239, 107), (240, 131), (145, 134)], cream, width: 4)
        line([(181, 111), (181, 129)], coral, 4)
        oval(159, 153, 8, 8, straw)
        oval(198, 155, 8, 8, straw)
        oval(231, 153, 9, 9, purple)
    }

    func teacup() {
        oval(163, 183, 94, 18, blue)
        oval(239, 128, 30, 24, pink)
        oval(240, 128, 17, 14, cream, edge: coral, width: 3)
        shape([(84, 95), (227, 95), (218, 150), (196, 177), (113, 173), (94, 148)],
              pink, edge: coral, width: 6)
        oval(155, 96, 72, 16, cream, edge: coral)
        oval(156, 100, 56, 8, wood, edge: wood, width: 2)
        line([(128, 71), (118, 56), (137, 44), (129, 26)], purple, 4, 0.57)
        line([(166, 71), (157, 53), (176, 43), (173, 25)], purple, 4, 0.57)
        line([(118, 139), (134, 127), (146, 143), (161, 128), (178, 141), (196, 128)], coral, 4, 0.73)
    }

    func cactus() {
        shape([(115, 150), (117, 122), (91, 120), (77, 105), (79, 68), (90, 62), (102, 71),
               (102, 95), (122, 100), (120, 62), (126, 34), (147, 27), (162, 41), (165, 109),
               (189, 100), (189, 75), (206, 66), (219, 78), (216, 111), (197, 131), (172, 134), (175, 156)],
              leaf, width: 6)
        for (x, y): Point in [(132, 52), (154, 75), (135, 105), (154, 125), (90, 91), (201, 92)] {
            line([(x - 5, y + 1), (x + 2, y - 5), (x + 5, y + 1)], cream, 3.3, 0.82)
        }
        oval(145, 27, 15, 9, coral, edge: coral, width: 3)
        shape([(98, 153), (202, 150), (191, 207), (115, 211)], orange, width: 6)
        shape([(91, 148), (207, 147), (204, 166), (92, 169)], straw, width: 5)
    }

    func slippers() {
        for (x, y, tilt, color): (CGFloat, CGFloat, CGFloat, UIColor) in [(91, 109, -15, coral), (193, 97, 22, purple)] {
            let sole: [Point] = [(x - 27, y + 63), (x - 33, y + 14), (x + tilt - 31, y - 24),
                                 (x + tilt - 11, y - 40), (x + tilt + 25, y - 35), (x + 30, y - 4),
                                 (x + 31, y + 54), (x + 18, y + 67), (x - 10, y + 68)]
            shape(sole, color, width: 6)
            shape([(x - 21, y + 17), (x + 4, y + 4), (x + 21, y + 17), (x + 19, y + 49),
                   (x - 17, y + 53)], cream, width: 3.5)
            line([(x + tilt - 16, y - 16), (x + tilt, y - 9), (x + tilt + 15, y - 18)], pink, 5, 0.9)
        }
    }

    func picture() {
        line([(111, 63), (161, 28), (207, 61)], cocoa, 5)
        shape([(62, 69), (255, 61), (260, 180), (68, 187)], wood, width: 7)
        shape([(77, 80), (241, 75), (244, 167), (82, 173)], cream, width: 4)
        oval(203, 101, 16, 16, yellow, edge: orange, width: 3)
        shape([(87, 146), (120, 104), (150, 135), (171, 110), (230, 153), (232, 159), (92, 165)],
              blue, edge: navy, width: 3.4)
        line([(87, 153), (120, 147), (154, 154), (192, 146), (231, 154)], leaf, 6)
    }

    func pencils() {
        for (x, y, end, color): (CGFloat, CGFloat, CGFloat, UIColor) in [
            (105, 40, 127, yellow), (145, 29, 149, coral), (194, 51, 175, blue), (227, 64, 196, leaf)
        ] {
            shape([(x - 5, y + 15), (x, y), (x + 9, y + 13), (end + 8, 161), (end - 5, 159)],
                  color, width: 3.6)
            line([(x, y), (x + 2, y + 8)], cocoa, 2.7)
        }
        shape([(104, 111), (204, 108), (195, 195), (119, 204)], purple, width: 6)
        oval(154, 111, 51, 8, pink)
        line([(121, 158), (137, 153), (149, 162), (165, 150), (185, 157)], cream, 5, 0.81)
    }

    func globe() {
        oval(149, 102, 65, 62, blue, edge: navy, width: 6)
        shape([(102, 66), (126, 50), (156, 59), (150, 78), (130, 92), (120, 105), (108, 91)],
              leaf, edge: leaf, width: 3.7)
        shape([(172, 83), (192, 84), (207, 103), (191, 114), (179, 144), (156, 132), (157, 107)],
              leaf, edge: leaf, width: 3.7)
        line([(178, 35), (214, 61), (229, 104), (222, 141), (193, 171), (152, 181)], wood, 7)
        line([(163, 177), (161, 202)], cocoa, 8)
        oval(160, 208, 49, 12, orange)
    }

    func kettle() {
        line([(101, 85), (111, 49), (136, 35), (181, 43), (198, 86)], cocoa, 10)
        shape([(224, 110), (261, 78), (284, 84), (272, 105), (241, 151), (217, 143)], blue, width: 6)
        shape([(88, 89), (211, 86), (235, 113), (234, 158), (209, 183), (99, 188), (73, 157), (76, 115)],
              blue, width: 6)
        oval(153, 90, 69, 12, cream)
        oval(155, 74, 17, 9, coral)
        line([(91, 145), (122, 154), (159, 154), (213, 141)], cream, 6, 0.80)
        line([(277, 72), (284, 56), (266, 46), (273, 28)], purple, 4, 0.62)
    }

    func catBed() {
        oval(154, 171, 103, 38, purple, edge: cocoa, width: 6)
        oval(152, 151, 85, 28, pink)
        shape([(86, 146), (96, 120), (122, 112), (151, 125), (166, 108), (204, 111), (221, 139), (210, 162),
               (161, 168), (111, 162)], orange, width: 5)
        shape([(173, 117), (176, 83), (194, 98), (213, 84), (222, 110), (218, 131), (194, 137)], straw, width: 5)
        line([(186, 113), (191, 111), (195, 113)], cocoa, 3)
        line([(203, 113), (208, 110), (212, 112)], cocoa, 3)
        line([(108, 146), (122, 138), (144, 142), (160, 154)], cocoa, 5)
    }

    func sewingMachine() {
        shape([(65, 165), (242, 159), (273, 173), (267, 191), (66, 195), (52, 182)], wood, width: 6)
        shape([(73, 156), (76, 78), (94, 61), (210, 61), (226, 86), (224, 119),
               (153, 118), (148, 146), (222, 144), (230, 160)], purple, width: 7)
        oval(224, 85, 23, 25, navy)
        oval(224, 85, 11, 12, straw)
        line([(152, 113), (150, 159), (158, 161)], cocoa, 5)
        shape([(134, 153), (193, 160), (201, 179), (128, 174)], coral, width: 3.5)
        line([(107, 62), (106, 42), (119, 39), (119, 63)], cocoa, 4)
        line([(118, 47), (154, 48), (150, 139)], cream, 3, 0.91)
    }

    func umbrellas() {
        line([(119, 174), (110, 106), (103, 66), (101, 46), (88, 39), (80, 51), (90, 61)], cocoa, 5)
        shape([(88, 68), (111, 66), (137, 171), (122, 179)], coral, width: 5)
        line([(192, 184), (199, 103), (208, 46), (221, 39), (230, 51), (221, 61)], cocoa, 5)
        shape([(185, 71), (213, 75), (199, 173), (180, 175)], blue, width: 5)
        shape([(91, 125), (223, 122), (206, 203), (110, 208)], straw, width: 6)
        oval(156, 126, 65, 9, wood)
        for x: CGFloat in [112, 134, 160, 183, 205] {
            line([(x, 141), (x + 1, 173), (x + 3, 196)], wood, 3.6, 0.70)
        }
    }

    func doorway() {
        shape([(77, 218), (77, 55), (99, 31), (221, 28), (239, 46), (241, 218)], straw, width: 7)
        shape([(96, 215), (96, 58), (108, 47), (221, 47), (222, 216)], blue, width: 5)
        shape([(97, 168), (123, 154), (151, 147), (176, 165), (195, 151), (223, 165), (224, 216), (98, 218)],
              leaf, edge: leaf, width: 4)
        shape([(104, 57), (156, 69), (161, 195), (102, 215)], wood, width: 5)
        line([(113, 69), (115, 137), (111, 197)], straw, 4, 0.79)
        oval(143, 137, 7, 7, yellow)
        line([(60, 217), (112, 220), (225, 217), (266, 223)], cocoa, 6)
    }

    private func shape(_ points: [Point], _ color: UIColor, edge: UIColor? = nil,
                       width: CGFloat = 5, opacity: CGFloat = 0.87) {
        wax.shape(points, color: color, border: edge ?? cocoa, width: width, opacity: opacity)
    }

    private func line(_ points: [Point], _ color: UIColor, _ width: CGFloat, _ opacity: CGFloat = 0.88) {
        wax.stroke(points, color: color, width: width, opacity: opacity)
    }

    private func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ color: UIColor,
                      edge: UIColor? = nil, width: CGFloat = 4) {
        let points: [Point] = (0..<14).map { index in
            let angle = CGFloat(index) * .pi / 7
            let wobble = 1 + CGFloat(index % 4 - 2) * 0.025
            return (x + cos(angle) * rx * wobble, y + sin(angle) * ry * wobble)
        }
        shape(points, color, edge: edge, width: width)
    }
}
