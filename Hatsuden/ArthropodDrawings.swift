import CoreGraphics

/// A separate silhouette for each shell, insect, arachnid, and fossil.
enum ArthropodDrawings {
    static func draw(id: Int, ink: CrayonCanvas, asleep: Bool = false) {
        let art = Brush(ink: ink, asleep: asleep)
        switch id {
        case 171: art.horseshoeCrab()
        case 172: art.kingCrab()
        case 173: art.spiderCrab()
        case 174: art.spinyLobster()
        case 175: art.mantisShrimp()
        case 176: art.hermitCrab()
        case 177: art.rhinocerosBeetle()
        case 178: art.stagBeetle()
        case 179: art.mantis()
        case 180: art.dragonfly()
        case 181: art.orchidMantis()
        case 182: art.firefly()
        case 183: art.honeybee()
        case 184: art.purpleEmperor()
        case 185: art.tarantula()
        case 186: art.scorpion()
        case 187: art.ammonite()
        case 188: art.trilobite()
        default: assertionFailure("Missing arthropod drawing")
        }
    }
}

private struct Brush {
    typealias Point = (CGFloat, CGFloat)

    let ink: CrayonCanvas
    let asleep: Bool

    private let black: UInt32 = 0x382A31
    private let milk: UInt32 = 0xFFEFCE
    private let coral: UInt32 = 0xE27659
    private let chestnut: UInt32 = 0x905947
    private let gold: UInt32 = 0xF2BC55
    private let purple: UInt32 = 0x865DB0
    private let sage: UInt32 = 0x759F58
    private let blue: UInt32 = 0x78B5C6

    private func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                      _ color: UInt32, edge: Bool = true) {
        ink.oval(x, y, w, h, fill: CrayonCanvas.color(color), border: edge ? CrayonCanvas.color(black) : nil)
    }

    private func shape(_ points: [Point], _ color: UInt32, weight: CGFloat = 4) {
        ink.polygon(points, fill: CrayonCanvas.color(color), border: CrayonCanvas.color(black), weight: weight)
    }

    private func line(_ points: [Point], _ color: UInt32? = nil, _ width: CGFloat = 3) {
        ink.line(points, color: CrayonCanvas.color(color ?? black), weight: width)
    }

    private func limb(_ points: [Point], _ color: UInt32, _ width: CGFloat) {
        line(points, black, width + 3)
        line(points, color, width)
    }

    private func eye(_ x: CGFloat, _ y: CGFloat, size: CGFloat = 8) {
        if asleep {
            line([(x - 4, y), (x + size, y - 1), (x - 3, y + size), (x + size + 1, y + size - 1)], black, 2.7)
        } else {
            oval(x, y, size, size * 1.1, black, edge: false)
            oval(x + size * 0.22, y + 1, size * 0.27, size * 0.31, milk, edge: false)
        }
    }

    private func mirror(_ points: [Point], around x: CGFloat = 120) -> [Point] {
        points.map { (x * 2 - $0.0, $0.1) }
    }

    func horseshoeCrab() {
        shape([(105, 144), (122, 217), (133, 146)], 0x836A58, weight: 3)
        shape([(70, 104), (169, 106), (160, 128), (166, 145), (148, 142), (146, 157),
               (131, 151), (119, 163), (103, 152), (89, 156), (87, 140), (71, 143)], 0x92704E)
        shape([(56, 109), (56, 83), (71, 53), (94, 34), (123, 30), (153, 37),
               (179, 59), (188, 84), (184, 112), (168, 124), (157, 109),
               (134, 103), (108, 104), (83, 111), (69, 125)], 0xA6905B, weight: 5)
        line([(96, 47), (90, 72), (94, 96)], 0xD5B77C, 4)
        line([(141, 47), (148, 74), (145, 97)], 0xD5B77C, 4)
        eye(87, 70); eye(145, 69)
        line([(103, 124), (118, 137), (138, 123)], chestnut, 4)
    }

    func kingCrab() {
        let legs: [[Point]] = [
            [(83, 109), (49, 92), (31, 102), (17, 125)],
            [(79, 121), (41, 123), (26, 146), (17, 158)],
            [(84, 139), (53, 153), (43, 183), (29, 195)],
            [(91, 145), (69, 172), (69, 190)]
        ]
        for points in legs { limb(points, coral, 7); limb(mirror(points), 0xD45343, 7) }
        let pincer: [Point] = [(72, 108), (52, 94), (40, 66), (48, 46), (61, 40), (70, 48),
                               (61, 65), (71, 72), (82, 51), (93, 55), (98, 73), (86, 93)]
        shape(pincer, 0xE57552); shape(mirror(pincer), 0xCF5144)
        shape([(73, 114), (83, 97), (89, 101), (95, 88), (104, 96), (118, 86),
               (126, 95), (140, 90), (145, 101), (156, 99), (170, 121),
               (165, 142), (148, 155), (116, 159), (85, 152)], coral, weight: 5)
        eye(103, 106); eye(130, 104)
        line([(108, 128), (120, 134), (133, 127)], chestnut, 3.6)
        for point: Point in [(94, 137), (137, 141), (151, 126), (111, 145)] {
            oval(point.0, point.1, 4, 4, milk, edge: false)
        }
    }

    func spiderCrab() {
        let legs: [[Point]] = [
            [(104, 107), (69, 58), (41, 48), (18, 69)],
            [(102, 118), (63, 85), (36, 91), (12, 124)],
            [(103, 131), (55, 129), (35, 154), (18, 187)],
            [(107, 139), (63, 162), (51, 188), (32, 209)]
        ]
        for (offset, leg) in legs.enumerated() {
            limb(leg, 0xE3A572, 4.8)
            limb(mirror(leg).enumerated().map { ($0.element.0, $0.element.1 + CGFloat($0.offset * (offset + 1))) },
                 0xE3A572, 4.8)
        }
        limb([(111, 104), (93, 78), (89, 50)], coral, 4)
        limb([(132, 103), (145, 78), (153, 56)], coral, 4)
        shape([(87, 58), (77, 44), (80, 31), (88, 41), (94, 30), (100, 38), (97, 51)], coral, weight: 3)
        shape([(149, 62), (143, 50), (145, 38), (155, 47), (163, 36), (168, 44), (161, 55)], coral, weight: 3)
        shape([(98, 108), (104, 97), (114, 102), (122, 93), (129, 101),
               (142, 105), (143, 127), (134, 151), (116, 158), (102, 142)], 0xF1AD81)
        eye(109, 110, size: 7); eye(128, 108, size: 7)
        line([(112, 138), (120, 141), (127, 137)], chestnut, 2.7)
    }

    func spinyLobster() {
        line([(123, 72), (94, 39), (64, 24), (37, 27), (24, 39)], coral, 4)
        line([(138, 72), (162, 43), (192, 28), (220, 32), (225, 45)], chestnut, 4.2)
        let legs: [[Point]] = [[(100, 109), (74, 115), (51, 131)], [(103, 125), (77, 135), (66, 155)],
                                [(110, 143), (86, 158), (75, 174)], [(117, 154), (102, 172), (100, 184)]]
        for leg in legs { limb(leg, 0xD4774F, 4); limb(mirror(leg, around: 124), coral, 4) }
        shape([(111, 174), (94, 190), (104, 209), (124, 202), (145, 211), (162, 192), (139, 174)], 0xC85243)
        for i in (0..<5).reversed() {
            let step = CGFloat(i)
            oval(102 + step * 2, 109 + step * 13, 48 - step * 4, 31, i.isMultiple(of: 2) ? coral : 0xDB6849)
        }
        shape([(96, 115), (94, 91), (102, 78), (103, 66), (111, 75), (122, 70), (130, 57),
               (139, 74), (150, 70), (156, 86), (164, 93), (156, 118), (130, 134), (111, 124)], coral)
        eye(107, 88, size: 10); eye(142, 85, size: 10)
        line([(114, 111), (127, 116), (142, 109)], chestnut, 3.6)
        line([(118, 97), (124, 93), (131, 98)], milk, 3)
    }

    func mantisShrimp() {
        shape([(48, 140), (32, 130), (22, 147), (34, 158), (20, 171), (30, 184),
               (53, 175), (65, 154)], 0xDA7E4E)
        for i in 0..<6 {
            let dx = CGFloat(i) * 18
            let dy = CGFloat((i - 4) * (i - 4)) * 1.2
            oval(42 + dx, 112 + dy, 40, 38, i.isMultiple(of: 2) ? 0x8DA678 : blue)
            if i > 0 { line([(53 + dx, 138 + dy), (48 + dx, 166 + dy), (63 + dx, 172 + dy)], chestnut, 3.3) }
        }
        shape([(148, 108), (163, 87), (188, 89), (208, 107), (198, 126), (163, 143)], 0x7FAD7F)
        limb([(169, 99), (165, 74), (159, 62)], sage, 5.5)
        limb([(190, 96), (197, 69), (206, 56)], blue, 5.5)
        oval(150, 53, 20, 17, gold); oval(199, 46, 20, 17, coral)
        eye(157, 55, size: 8); eye(206, 48, size: 8)
        shape([(178, 124), (195, 128), (214, 147), (206, 162), (185, 157), (174, 167),
               (167, 155), (183, 145), (179, 137)], 0xE2A45C, weight: 3.6)
        line([(193, 106), (209, 99), (227, 100)], chestnut, 3)
    }

    func hermitCrab() {
        for (y, x): (CGFloat, CGFloat) in [(131, 130), (144, 119), (156, 104)] {
            limb([(x, y), (x - 14, y + 18), (x - 23, y + 21)], coral, 7)
            limb([(x + 32, y - 2), (x + 46, y + 18), (x + 62, y + 21)], coral, 6)
        }
        oval(51, 55, 127, 124, 0xDAA86A)
        line([(164, 121), (156, 88), (133, 69), (101, 73), (80, 90), (77, 115), (90, 135),
              (112, 144), (133, 136), (141, 116), (129, 99), (113, 96), (104, 106), (112, 117)], chestnut, 5.8)
        oval(146, 124, 51, 36, coral)
        limb([(163, 134), (160, 113), (158, 105)], coral, 5)
        limb([(184, 132), (190, 108), (194, 101)], coral, 5)
        eye(154, 101); eye(190, 96)
        shape([(184, 153), (203, 139), (223, 142), (224, 157), (211, 157),
               (218, 169), (207, 173), (188, 166)], 0xE3674F)
    }

    func rhinocerosBeetle() {
        let legs: [[Point]] = [[(95, 108), (63, 89), (51, 66)], [(89, 132), (57, 132), (39, 152)],
                                [(92, 156), (65, 174), (63, 202)]]
        for leg in legs { limb(leg, chestnut, 5.5); limb(mirror(leg), chestnut, 5.5) }
        oval(74, 97, 94, 106, 0x6A3B35)
        line([(119, 111), (117, 144), (121, 193)], black, 4.5)
        line([(97, 130), (91, 152), (95, 174)], 0xAF7655, 5.2)
        line([(145, 129), (151, 153), (147, 179)], 0xAF7655, 4.5)
        oval(86, 78, 68, 41, 0x7B4A3B)
        oval(97, 61, 48, 33, 0x513439)
        shape([(114, 88), (111, 68), (108, 46), (94, 34), (89, 23), (100, 25),
               (111, 35), (116, 22), (122, 20), (126, 35), (143, 26), (149, 28),
               (139, 41), (125, 48), (128, 73), (130, 87)], 0x593632, weight: 3.8)
        eye(99, 73, size: 6); eye(138, 73, size: 6)
    }

    func stagBeetle() {
        let legs: [[Point]] = [[(93, 101), (64, 100), (49, 72)], [(86, 130), (58, 141), (39, 144)],
                                [(92, 150), (71, 169), (47, 184)]]
        for leg in legs { limb(leg, 0x67423F, 4.8); limb(mirror(leg), 0x67423F, 4.8) }
        shape([(88, 112), (105, 104), (136, 103), (152, 117), (156, 154),
               (146, 190), (122, 207), (97, 199), (83, 172), (82, 139)], 0x6B403C)
        line([(121, 117), (121, 161), (123, 199)], black, 3.6)
        line([(101, 142), (103, 172), (111, 190)], 0xA46A5C, 4.3)
        oval(90, 83, 60, 42, 0x764642)
        oval(93, 64, 56, 30, 0x54353A)
        let jaw: [Point] = [(98, 83), (78, 69), (67, 50), (69, 34), (77, 18), (82, 22),
                            (79, 38), (87, 34), (90, 38), (81, 48), (87, 57), (95, 52),
                            (99, 57), (92, 64), (108, 76)]
        shape(jaw, 0x513436); shape(mirror(jaw), 0x513436)
        eye(99, 69, size: 6); eye(136, 69, size: 6)
    }

    func mantis() {
        limb([(113, 126), (62, 133), (46, 184), (24, 196)], sage, 5)
        limb([(122, 133), (158, 148), (201, 196), (218, 203)], 0x74AA52, 5)
        limb([(124, 142), (114, 170), (142, 207)], 0xA6B66B, 4)
        shape([(116, 115), (145, 126), (169, 166), (173, 201), (148, 185), (124, 157), (109, 132)], sage)
        line([(125, 127), (147, 152), (163, 190)], 0xC5CF83, 4)
        limb([(116, 126), (106, 94), (116, 74)], sage, 11)
        limb([(114, 105), (124, 101), (137, 91)], sage, 5.2)
        let claw: [Point] = [(110, 95), (82, 105), (60, 85), (51, 56), (60, 45), (69, 62),
                             (73, 77), (80, 76), (86, 83), (92, 78), (98, 87), (112, 84)]
        shape(claw, 0xA0B963, weight: 3.4)
        shape([(121, 96), (146, 83), (160, 60), (170, 50), (176, 58), (168, 76), (164, 88),
               (150, 103), (126, 108)], sage, weight: 3.5)
        shape([(92, 58), (123, 44), (140, 64), (123, 85), (112, 86)], 0xB3C77B)
        eye(97, 58, size: 10); eye(125, 55, size: 9)
        line([(104, 52), (93, 35), (87, 25)], black, 2.8)
        line([(126, 48), (133, 31), (146, 21)], black, 2.8)
    }

    func dragonfly() {
        let upper: [Point] = [(116, 91), (78, 52), (34, 37), (15, 47), (34, 66), (82, 88)]
        let lower: [Point] = [(117, 102), (71, 91), (24, 108), (15, 128), (37, 135), (83, 118)]
        shape(upper, 0xB4DBDC, weight: 3)
        shape(lower, 0xD0E8D9, weight: 3)
        shape(mirror(upper), 0xC3E2DD, weight: 3)
        shape(mirror(lower), 0xBBD9CB, weight: 3)
        for points: [Point] in [[(109, 91), (68, 64), (27, 49)], [(107, 104), (64, 106), (25, 124)]] {
            line(points, blue, 3); line(mirror(points), blue, 3)
        }
        shape([(104, 103), (133, 100), (133, 156), (128, 202), (119, 221),
               (110, 202), (106, 157)], 0x6E594C, weight: 4)
        for y in stride(from: 125, through: 199, by: 15) {
            line([(110, CGFloat(y)), (129, CGFloat(y) - 2)], gold, 4)
        }
        oval(101, 76, 38, 42, 0x81694F)
        oval(98, 59, 24, 31, 0x75A782); oval(119, 57, 24, 31, 0x75A782)
        eye(103, 65); eye(129, 63)
    }

    func orchidMantis() {
        let pink: UInt32 = 0xEEB5C0
        let mauve: UInt32 = 0xBB779E
        let leg: [Point] = [(107, 130), (77, 144), (58, 174), (39, 184)]
        limb(leg, pink, 5); limb(mirror(leg), pink, 5)
        limb([(110, 149), (86, 176), (84, 200)], mauve, 5)
        limb([(128, 145), (151, 180), (153, 207)], mauve, 5)
        shape([(103, 115), (88, 138), (97, 165), (125, 183), (148, 161), (151, 134),
               (134, 114)], 0xF0D1C8)
        shape([(83, 143), (69, 127), (60, 131), (57, 148), (64, 163), (82, 167), (94, 158)], pink, weight: 3)
        shape([(152, 135), (174, 132), (182, 144), (178, 161), (161, 171), (146, 161)], pink, weight: 3)
        limb([(118, 140), (120, 104), (119, 77)], milk, 10)
        shape([(110, 97), (91, 108), (70, 99), (62, 77), (69, 64), (79, 71), (83, 85),
               (95, 87), (106, 84)], 0xF2D0D0, weight: 3.4)
        shape([(123, 95), (140, 87), (151, 68), (163, 60), (170, 67), (164, 87), (147, 104), (127, 108)], pink, weight: 3.3)
        shape([(100, 62), (115, 48), (132, 57), (139, 66), (125, 82), (114, 83)], milk)
        eye(106, 60, size: 7); eye(127, 60, size: 7)
        line([(107, 54), (101, 34), (88, 29)], mauve, 2.8)
        line([(129, 55), (136, 33), (149, 25)], mauve, 2.8)
        line([(104, 151), (120, 162), (138, 150)], mauve, 4)
    }

    func firefly() {
        oval(39, 126, 70, 65, 0xFFF0A0, edge: false)
        oval(46, 132, 55, 48, 0xFFD758)
        let legs: [[Point]] = [[(106, 118), (91, 93), (65, 91)], [(126, 123), (141, 151), (129, 179)],
                                [(149, 109), (165, 138), (166, 164)]]
        for leg in legs { limb(leg, chestnut, 4) }
        shape([(62, 132), (69, 99), (96, 80), (139, 73), (167, 90), (166, 119),
               (141, 145), (110, 157), (80, 157)], 0x53484C)
        line([(71, 139), (100, 111), (139, 91)], 0x81707F, 4)
        oval(138, 72, 54, 52, 0xD66D58)
        oval(171, 80, 36, 36, 0x63525E)
        eye(188, 87, size: 8)
        line([(189, 84), (198, 62), (208, 56)], black, 3.3)
        line([(197, 88), (213, 73), (225, 73)], black, 3)
        for mark: [Point] in [[(35, 148), (23, 143)], [(37, 171), (26, 180)], [(56, 188), (49, 201)]] {
            line(mark, gold, 3.7)
        }
    }

    func honeybee() {
        let wing: [Point] = [(126, 111), (105, 89), (96, 64), (107, 47), (129, 52), (141, 74), (139, 108)]
        shape(wing, 0xC8E6EA, weight: 3)
        shape([(117, 115), (83, 107), (55, 88), (51, 69), (64, 60), (87, 68),
               (104, 88), (126, 109)], 0xE2F0E6, weight: 3.5)
        line([(63, 74), (91, 90), (113, 108)], blue, 2.7)
        shape([(57, 133), (37, 151), (63, 155)], chestnut, weight: 3)
        oval(54, 102, 107, 70, gold)
        shape([(77, 107), (95, 104), (92, 124), (94, 144), (102, 168), (86, 166), (75, 149), (72, 128)],
              0x664340, weight: 2.2)
        shape([(116, 104), (132, 108), (126, 126), (129, 143), (138, 161),
               (121, 168), (112, 149), (108, 131)], 0x664340, weight: 2.1)
        oval(140, 98, 54, 53, 0xF4BA51)
        line([(155, 106), (148, 84), (139, 82)], black, 3)
        line([(173, 101), (183, 82), (193, 78)], black, 3)
        oval(135, 78, 8, 8, black, edge: false)
        oval(190, 74, 8, 8, black, edge: false)
        eye(176, 111, size: 9)
        line([(174, 133), (182, 135), (188, 130)], chestnut, 2.6)
        line([(117, 158), (110, 179), (122, 185)], chestnut, 4.4)
        line([(143, 150), (146, 175), (162, 172)], chestnut, 4.4)
    }

    func purpleEmperor() {
        let upper: [Point] = [(114, 122), (86, 103), (40, 92), (19, 69), (21, 44), (42, 38),
                              (67, 45), (90, 64), (106, 86), (120, 109)]
        let lower: [Point] = [(112, 128), (84, 118), (49, 110), (31, 132), (35, 155),
                              (50, 177), (78, 179), (100, 155)]
        shape(upper, purple, weight: 5)
        shape(mirror(upper).enumerated().map { ($0.element.0, $0.element.1 + CGFloat($0.offset % 3) * 2) },
              0x7056A4, weight: 5)
        shape(lower, 0x7660AD); shape(mirror(lower), 0x6859A6)
        for points: [Point] in [[(29, 63), (46, 61), (57, 66), (72, 67), (94, 85)], [(41, 140), (62, 141), (85, 134)]] {
            line(points, milk, 6); line(mirror(points), milk, 6)
        }
        oval(62, 157, 12, 10, coral); oval(165, 155, 13, 10, coral)
        oval(113, 78, 16, 88, 0x634556)
        oval(108, 70, 25, 24, 0x634556)
        line([(114, 75), (106, 54), (92, 42)], black, 2.8)
        line([(129, 75), (137, 51), (148, 40)], black, 2.8)
        eye(113, 76, size: 6); eye(123, 77, size: 6)
    }

    func tarantula() {
        let legs: [[Point]] = [[(98, 105), (73, 77), (53, 62), (29, 66)],
                               [(91, 114), (65, 99), (39, 97), (22, 114)],
                               [(89, 130), (65, 132), (41, 149), (23, 166)],
                               [(95, 148), (77, 168), (57, 176), (44, 201)]]
        for (i, leg) in legs.enumerated() {
            let tone: UInt32 = i.isMultiple(of: 2) ? 0xA47763 : 0xB48362
            limb(leg, tone, 9)
            limb(mirror(leg).enumerated().map { ($0.element.0, $0.element.1 - CGFloat($0.offset)) }, tone, 9)
            let knee = leg[1]
            line([(knee.0 - 6, knee.1 + 5), (knee.0 + 3, knee.1 - 4)], 0xD28D57, 5)
            line(mirror([(knee.0 - 6, knee.1 + 5), (knee.0 + 3, knee.1 - 4)]), 0xD28D57, 5)
        }
        oval(76, 102, 88, 75, 0x795751)
        for i in 0..<9 {
            let x = CGFloat(87 + i * 8)
            line([(x, 142), (x - 3, 150), (x + 3, 158)], 0xBC8C6C, 2.8)
        }
        oval(85, 68, 71, 63, 0x9E7159)
        for x: CGFloat in [105, 116, 126, 136] { eye(x, 83, size: 5.5) }
        eye(114, 94, size: 6); eye(129, 94, size: 6)
        limb([(106, 100), (97, 85), (99, 76)], chestnut, 4)
        limb([(137, 103), (147, 84), (143, 76)], chestnut, 4)
    }

    func scorpion() {
        let tail: [Point] = [(148, 135), (176, 128), (196, 113), (204, 90), (198, 66), (177, 49), (158, 51)]
        limb(tail, 0xD3A061, 13)
        for pair: (Point, Point) in [((176,121),(181,134)), ((194,107),(203,115)),
                                    ((198,85),(210,85)), ((191,67),(202,60)), ((175,55),(179,44))] {
            line([pair.0, pair.1], chestnut, 2.7)
        }
        shape([(162, 45), (148, 47), (136, 59), (141, 68), (146, 56), (161, 56)], coral, weight: 3.4)
        for i in 0..<4 {
            let x = CGFloat(89 + i * 14)
            limb([(x, 149), (x - 9, 175), (x - 21, 189)], 0xBA8E59, 4.2)
            limb([(x, 129), (x + 1, 110), (x - 14, 102)], 0xBA8E59, 4.2)
        }
        oval(72, 119, 92, 45, 0xBC8B54)
        for x: CGFloat in [113, 129, 144] { line([(x, 124), (x + 2, 140), (x, 157)], chestnut, 2.9) }
        limb([(85, 128), (57, 109), (43, 105)], gold, 9)
        limb([(85, 148), (56, 163), (39, 164)], gold, 9)
        shape([(50, 106), (35, 88), (18, 89), (17, 104), (30, 103), (34, 112),
               (19, 114), (24, 122), (41, 121)], gold)
        shape([(49, 165), (36, 148), (22, 150), (20, 159), (33, 160), (33, 169),
               (16, 173), (21, 184), (37, 181)], 0xE3AD62)
        oval(67, 123, 40, 38, 0xDBA765)
        eye(76, 132, size: 6); eye(77, 145, size: 6)
    }

    func ammonite() {
        for i in 0..<7 {
            let y = CGFloat(130 + i * 7)
            let curve = CGFloat((i * 13) % 11)
            line([(166, 149), (187, y), (205, y - curve + 2), (219, y - curve)], 0x8C6B79, 5.5)
        }
        oval(140, 120, 56, 61, 0xCA9FA8)
        eye(180, 138, size: 8)
        oval(34, 47, 142, 146, 0xDDB485)
        for i in 0..<19 {
            let angle = Double(i) * .pi / 9.5
            let x = cos(angle)
            let y = sin(angle)
            line([(105 + 55 * x, 119 + 57 * y), (105 + 65 * x, 119 + 67 * y)], 0xA7765F, 3)
        }
        line([(165, 141), (168, 112), (156, 84), (134, 69), (102, 68), (80, 82),
              (66, 105), (68, 130), (82, 152), (107, 161), (130, 149), (142, 129),
              (138, 109), (125, 96), (107, 95), (93, 109), (94, 124), (104, 135),
              (116, 132), (122, 121), (114, 114)], chestnut, 5.2)
    }

    func trilobite() {
        shape([(61, 84), (66, 64), (84, 43), (113, 32), (146, 35), (173, 55),
               (181, 81), (173, 105), (163, 130), (155, 153), (144, 174), (135, 195),
               (122, 209), (106, 205), (92, 192), (82, 168), (72, 146), (63, 117)], 0xB28758, weight: 5)
        shape([(60, 84), (67, 60), (87, 44), (114, 37), (144, 40), (170, 57), (181, 82),
               (164, 96), (140, 89), (121, 97), (99, 89), (76, 97)], 0xD0A374, weight: 3.6)
        line([(99, 91), (103, 125), (109, 152), (113, 181), (122, 202)], chestnut, 4)
        line([(140, 90), (136, 121), (133, 149), (127, 182), (122, 202)], chestnut, 4)
        for i in 0..<8 {
            let y = CGFloat(101 + i * 11)
            let inset = CGFloat(i * i) * 0.79
            line([(64 + inset, y), (98 + inset * 0.22, y + 4), (119, y + 1),
                  (139 - inset * 0.15, y + 4), (174 - inset, y - 1)], 0x875C4D, 3.1)
        }
        oval(78, 64, 17, 13, 0xE5C199); oval(149, 65, 18, 13, 0xE5C199)
        eye(82, 67, size: 7); eye(154, 67, size: 7)
        line([(112, 59), (120, 52), (132, 58)], 0xEDD1A3, 3.5)
    }
}
