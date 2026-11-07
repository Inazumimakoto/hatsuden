import UIKit

enum CanvasEarthDetails {
    static func draw(_ subject: CanvasSubject, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        var brush = Brush(context: context, seed: UInt64(subject.rawValue))
        brush.draw(subject)
    }
}

/// A few fast, irregular wax strokes per shape keep the smaller marks readable.
private struct Brush {
    typealias Point = (CGFloat, CGFloat)

    let context: CGContext
    var state: UInt64

    let ink = UIColor(red: 0.29, green: 0.22, blue: 0.23, alpha: 1)
    let green = UIColor(red: 0.38, green: 0.61, blue: 0.38, alpha: 1)
    let lime = UIColor(red: 0.64, green: 0.73, blue: 0.37, alpha: 1)
    let blue = UIColor(red: 0.33, green: 0.62, blue: 0.77, alpha: 1)
    let teal = UIColor(red: 0.34, green: 0.66, blue: 0.58, alpha: 1)
    let brick = UIColor(red: 0.79, green: 0.34, blue: 0.36, alpha: 1)
    let pink = UIColor(red: 0.87, green: 0.52, blue: 0.65, alpha: 1)
    let peach = UIColor(red: 0.93, green: 0.60, blue: 0.35, alpha: 1)
    let sun = UIColor(red: 0.95, green: 0.77, blue: 0.40, alpha: 1)
    let violet = UIColor(red: 0.61, green: 0.49, blue: 0.73, alpha: 1)
    let wood = UIColor(red: 0.55, green: 0.37, blue: 0.30, alpha: 1)
    let stone = UIColor(red: 0.60, green: 0.59, blue: 0.63, alpha: 1)
    let chalk = UIColor(red: 1, green: 0.96, blue: 0.85, alpha: 1)

    init(context: CGContext, seed: UInt64) {
        self.context = context
        state = seed &* 0xD134_2543_DE82_EF95 &+ 0xAC56_528B_180D_94CB
        context.setLineCap(.round)
        context.setLineJoin(.round)
    }

    mutating func draw(_ subject: CanvasSubject) {
        switch subject {
        case .greenhouse:
            shape([(50, 194), (51, 100), (92, 50), (223, 51), (270, 96), (268, 193)], blue.withAlphaComponent(0.54))
            for x: CGFloat in [81, 118, 158, 198, 238] {
                flower(x, 181, 28, sun)
                line([(x, 188), (x, 99), (x + (157 - x) * 0.32, 54)], teal, 5)
            }
            line([(53, 99), (156, 95), (267, 99)], teal, 7)
            shape([(135, 193), (135, 112), (180, 112), (179, 193)], chalk.withAlphaComponent(0.40))
            oval(170, 152, 4, 4, wood)
        case .gardenWell:
            oval(158, 181, 68, 32, stone)
            shape([(91, 155), (92, 192), (119, 207), (181, 208), (223, 189), (226, 152)], stone)
            oval(158, 151, 67, 20, wood)
            oval(159, 152, 51, 11, blue)
            line([(112, 153), (111, 70), (203, 68), (204, 153)], wood, 8)
            shape([(87, 78), (151, 30), (224, 77), (204, 90), (106, 89)], brick)
            line([(157, 92), (158, 125)], wood, 3)
            shape([(144, 122), (172, 121), (166, 144), (148, 144)], peach)
            for x: CGFloat in [111, 137, 174, 199] {
                line([(x, 182), (x + 6, 198)], chalk, 3)
            }
        case .roseArch:
            line([(91, 206), (86, 111), (93, 73), (117, 49), (155, 35), (190, 45), (220, 73), (230, 113), (229, 204)], wood, 12)
            line([(111, 204), (109, 110), (120, 77), (155, 58), (185, 64), (207, 94), (208, 201)], peach, 7)
            for (x, y) in [(90.0, 171.0), (98, 129), (98, 86), (124, 59), (169, 47), (207, 73), (220, 112), (224, 153), (220, 183)] {
                oval(x - 8, y + 8, 13, 7, green, outlined: false)
                oval(x + 7, y, 14, 11, pink)
                oval(x + 7, y, 5, 5, brick, outlined: false)
            }
        case .vegetableRows:
            for row in 0..<3 {
                let x = 55 + CGFloat(row) * 72
                line([(x, 205), (x + 8, 151), (x + 39, 72)], wood, 19)
                for plant in 0..<3 {
                    let px = x + CGFloat(plant) * 10
                    let py = 190 - CGFloat(plant) * 36
                    if row == 0 {
                        shape([(px - 8, py), (px + 10, py), (px - 4, py + 24)], peach)
                        reeds(px, py)
                    } else {
                        oval(px, py, 13, 8, row == 1 ? lime : violet)
                        line([(px, py), (px + 1, py - 12)], green, 4)
                    }
                }
            }
        case .wheelbarrow:
            oval(90, 170, 28, 28, stone)
            oval(90, 170, 8, 8, chalk)
            line([(90, 169), (189, 158), (258, 119), (288, 110)], wood, 10)
            line([(145, 153), (160, 200), (196, 200), (199, 147)], stone, 8)
            shape([(78, 101), (219, 101), (184, 152), (113, 154)], teal)
            shape([(98, 101), (130, 65), (179, 70), (195, 102)], wood)
            reeds(142, 91)
            flower(172, 92, 37, sun)
        case .gardenShed:
            shape([(81, 187), (80, 88), (111, 65), (223, 81), (225, 187)], peach)
            shape([(67, 94), (102, 50), (207, 64), (237, 92)], wood)
            for x: CGFloat in [91, 115, 140, 165, 190, 215] {
                line([(x, 100), (x + 1, 186)], wood, 3)
            }
            shape([(137, 184), (138, 112), (191, 110), (193, 185)], teal)
            line([(142, 179), (185, 118)], wood, 5)
            oval(180, 148, 5, 5, sun)
            line([(243, 185), (259, 105), (273, 105)], wood, 5)
            line([(246, 151), (273, 151)], stone, 6)
        case .cherryTree:
            shape([(143, 207), (147, 148), (115, 123), (122, 113), (155, 134),
                   (168, 98), (180, 104), (173, 152), (187, 204)], wood)
            for (x, y, width, height): (CGFloat, CGFloat, CGFloat, CGFloat) in [
                (104, 100, 57, 36), (130, 65, 50, 36), (175, 62, 51, 35), (217, 96, 53, 32), (180, 118, 49, 28)
            ] { oval(x, y, width, height, pink, outlined: false) }
            for (x, y) in [(92.0, 94.0), (145, 63), (176, 89), (214, 76), (193, 113), (112, 119), (230, 147), (264, 173), (89, 182)] {
                oval(x, y, 7, 4, chalk, outlined: false)
            }
        case .fishPond:
            oval(156, 137, 122, 63, blue, outlined: false)
            for (x, y): Point in [(51, 152), (66, 178), (244, 162), (253, 112)] { reeds(x, y) }
            lily(98, 126)
            lily(192, 170)
            for (x, y, color): (CGFloat, CGFloat, UIColor) in [(151, 111, peach), (169, 142, chalk), (205, 129, brick)] {
                oval(x, y, 23, 10, color)
                shape([(x - 17, y), (x - 34, y - 9), (x - 32, y + 8)], color)
                oval(x + 13, y - 2, 3, 3, ink, outlined: false)
            }
        case .school:
            shape([(31, 178), (29, 106), (283, 106), (284, 178)], peach)
            shape([(106, 178), (107, 83), (155, 59), (202, 84), (201, 178)], sun)
            line([(97, 86), (154, 47), (211, 85)], brick, 10)
            clock(155, 95, 16)
            for x: CGFloat in [52, 81, 227, 256] { glass(x, 127, 17, 24) }
            glass(139, 136, 33, 43)
            line([(155, 47), (156, 24), (181, 25), (181, 36), (156, 34)], brick, 4)
            line([(30, 201), (137, 200), (205, 203), (287, 200)], chalk, 5)
        case .postOffice:
            shape([(70, 185), (71, 83), (220, 84), (223, 183)], brick)
            shape([(57, 87), (57, 66), (233, 67), (232, 88)], peach)
            shape([(120, 181), (120, 126), (146, 107), (171, 126), (172, 181)], chalk)
            envelope(145, 72, 28)
            glass(80, 118, 25, 30)
            glass(183, 118, 25, 30)
            mailbox(257, 190)
            line([(104, 194), (177, 194)], stone, 5)
        case .bakery:
            shape([(61, 184), (62, 87), (235, 86), (240, 184)], peach)
            shape([(51, 88), (76, 55), (217, 54), (245, 86)], wood)
            glass(75, 114, 104, 53)
            for x: CGFloat in [91, 124, 154] {
                oval(x, 143, 12, 8, sun)
                line([(x - 5, 139), (x + 3, 146)], chalk, 2)
            }
            shape([(54, 107), (239, 109), (246, 127), (50, 126)], brick)
            for x: CGFloat in [67, 98, 129, 160, 191, 223] {
                line([(x, 111), (x - 3, 125)], chalk, 8)
            }
            shape([(194, 143), (223, 144), (225, 184), (193, 185)], teal)
            oval(154, 72, 22, 10, sun)
        case .fireStation:
            shape([(37, 186), (37, 99), (209, 99), (213, 184)], brick)
            shape([(203, 188), (201, 48), (266, 47), (265, 188)], peach)
            shape([(197, 49), (232, 25), (273, 48)], brick)
            glass(219, 67, 27, 19)
            shape([(63, 187), (61, 121), (181, 121), (183, 186)], wood)
            vehicle(121, 166, 105, brick)
            line([(81, 135), (149, 131)], chalk, 7)
            line([(84, 143), (149, 138)], chalk, 5)
            for x: CGFloat in [89, 109, 129, 145] { line([(x, 133), (x, 139)], stone, 3) }
            oval(116, 133, 7, 4, sun)
        case .hospital:
            shape([(32, 181), (32, 109), (103, 108), (104, 64), (216, 64), (217, 108),
                   (283, 108), (287, 181)], chalk)
            line([(135, 89), (186, 89)], brick, 9)
            line([(160, 76), (160, 104)], brick, 9)
            for x: CGFloat in [45, 72, 114, 180, 224, 254] { glass(x, 124, 16, 21) }
            glass(137, 137, 43, 44)
            line([(33, 166), (130, 166)], teal, 6)
            line([(187, 166), (282, 165)], teal, 6)
        case .library:
            shape([(58, 183), (58, 92), (260, 91), (262, 183)], chalk)
            shape([(45, 97), (157, 44), (273, 93), (270, 105), (47, 105)], stone)
            for x: CGFloat in [75, 113, 200, 239] {
                line([(x, 113), (x + 1, 173)], peach, 12)
                line([(x - 8, 113), (x + 8, 113)], wood, 4)
            }
            glass(138, 121, 43, 58)
            line([(53, 182), (263, 183)], wood, 6)
            line([(44, 196), (271, 197)], stone, 8)
            shape([(140, 69), (158, 74), (176, 69), (176, 81), (158, 85), (140, 81)], blue)
        case .tramStop:
            line([(18, 187), (97, 172), (214, 172), (299, 186)], stone, 6)
            line([(21, 211), (116, 194), (209, 195), (292, 209)], stone, 6)
            glass(72, 94, 143, 66)
            line([(77, 83), (130, 67), (220, 76), (230, 91)], teal, 9)
            line([(78, 90), (78, 158), (215, 157), (214, 85)], wood, 7)
            bench(140, 140)
            line([(250, 154), (250, 77)], wood, 6)
            oval(251, 74, 13, 12, sun)
        case .cityBus:
            shape([(29, 156), (29, 103), (44, 82), (249, 79), (276, 91),
                   (290, 119), (292, 157), (278, 169), (42, 170)], teal)
            for x: CGFloat in [47, 84, 123, 161, 199] { glass(x, 95, 28, 31) }
            glass(238, 95, 27, 46)
            line([(35, 146), (235, 145)], chalk, 8)
            oval(78, 168, 19, 18, ink)
            oval(244, 168, 19, 18, ink)
            oval(78, 168, 8, 8, stone)
            oval(244, 168, 8, 8, stone)
            oval(281, 150, 6, 5, sun)
        case .deliveryVan:
            shape([(47, 157), (48, 95), (182, 94), (191, 112), (240, 112), (268, 139),
                   (270, 168), (46, 168)], peach)
            glass(203, 117, 37, 24)
            line([(181, 109), (180, 162)], wood, 4)
            shape([(90, 115), (118, 108), (146, 119), (146, 141), (116, 150), (88, 139)], sun)
            line([(89, 119), (117, 128), (145, 120)], wood, 3)
            line([(117, 128), (116, 147)], wood, 3)
            oval(91, 165, 18, 18, ink)
            oval(227, 166, 18, 18, ink)
            oval(91, 165, 8, 8, stone)
            oval(227, 166, 8, 8, stone)
        case .bicycle:
            for x: CGFloat in [80, 240] {
                oval(x, 148, 45, 46, chalk)
                oval(x, 148, 37, 38, blue.withAlphaComponent(0.40))
                line([(x - 32, 148), (x + 32, 148)], stone, 3)
                line([(x, 115), (x, 180)], stone, 3)
                line([(x - 23, 125), (x + 23, 171)], stone, 3)
            }
            line([(80, 148), (128, 92), (150, 151), (80, 148), (150, 151), (205, 90), (240, 148)], brick, 8)
            line([(127, 93), (205, 90), (195, 64), (218, 61)], brick, 7)
            line([(110, 87), (140, 86)], ink, 8)
            oval(150, 151, 10, 10, stone)
        case .constructionCrane:
            line([(93, 199), (95, 49), (116, 30), (136, 49), (137, 199)], peach, 8)
            line([(41, 64), (272, 64), (250, 47), (63, 48), (41, 64)], sun, 7)
            for y: CGFloat in [66, 88, 110, 132, 154, 176] {
                line([(96, y), (135, y + 20), (96, y + 20)], wood, 4)
            }
            line([(217, 65), (217, 139), (222, 149), (232, 143)], ink, 5)
            shape([(201, 161), (244, 160), (243, 193), (201, 193)], stone)
            line([(79, 202), (151, 201)], wood, 8)
        case .railStation:
            shape([(32, 168), (32, 107), (78, 107), (97, 77), (126, 62), (160, 57), (197, 63),
                   (225, 83), (240, 107), (287, 106), (287, 169)], brick)
            shape([(93, 166), (93, 110), (116, 86), (160, 74), (204, 87), (229, 110), (227, 166)], blue)
            for x: CGFloat in [113, 139, 166, 193, 217] { line([(x, 112), (x, 163)], chalk, 4) }
            line([(100, 116), (221, 116)], chalk, 5)
            clock(160, 63, 13)
            line([(29, 187), (286, 188)], stone, 6)
            line([(19, 207), (299, 207)], stone, 6)
            for x: CGFloat in [42, 85, 129, 171, 215, 258] { line([(x, 190), (x - 2, 206)], wood, 4) }
        case .waterfall:
            shape([(39, 180), (70, 89), (116, 61), (198, 56), (248, 88), (275, 181)], stone)
            shape([(125, 66), (175, 62), (166, 113), (181, 154), (179, 192), (119, 196),
                   (130, 150), (124, 114)], blue)
            line([(138, 72), (140, 114), (145, 153), (134, 186)], chalk, 6)
            line([(160, 77), (154, 117), (167, 156), (164, 186)], chalk, 5)
            oval(154, 197, 110, 20, teal, outlined: false)
            ripple(150, 197)
            tree(48, 185, 62, conifer: true)
            tree(270, 187, 76, conifer: true)
        case .campsite:
            tent(134, 169, 150)
            campfire(250, 183)
            tree(43, 170, 78, conifer: true)
            shape([(173, 175), (203, 171), (210, 185), (177, 191)], violet)
            line([(217, 142), (219, 91)], wood, 4)
            oval(220, 102, 9, 13, sun)
        case .cableCar:
            ridge(15, 168, 286, 100, color: teal)
            line([(13, 100), (306, 37)], ink, 4)
            line([(124, 76), (129, 106), (167, 103), (163, 68)], wood, 5)
            shape([(90, 112), (197, 107), (205, 124), (195, 172),
                   (96, 177), (86, 156)], brick)
            glass(100, 119, 40, 27)
            glass(149, 117, 40, 27)
            line([(124, 177), (123, 189), (179, 187), (180, 172)], wood, 5)
        case .hydroDam:
            patch([(14, 93), (135, 71), (305, 87), (302, 127), (221, 155), (48, 144)], blue)
            shape([(43, 92), (92, 111), (156, 120), (233, 105), (277, 91),
                   (253, 162), (209, 181), (139, 186), (72, 159)], stone)
            line([(47, 98), (95, 117), (157, 125), (231, 111), (273, 94)], chalk, 7)
            for x: CGFloat in [106, 151, 196] {
                shape([(x - 8, 143), (x + 8, 145), (x + 3, 169), (x - 9, 177)], blue)
                line([(x - 4, 173), (x - 16, 197), (x + 9, 207)], blue, 5)
            }
        case .volcano:
            shape([(14, 201), (65, 166), (99, 121), (131, 81), (146, 89),
                   (176, 84), (207, 126), (239, 164), (303, 203)], stone)
            shape([(113, 111), (132, 81), (148, 91), (173, 84), (191, 106), (173, 116),
                   (159, 104), (150, 126), (137, 117)], brick)
            line([(148, 102), (133, 135), (147, 160), (125, 185), (103, 199)], brick, 13)
            line([(177, 105), (188, 130), (181, 152), (205, 169), (222, 199)], peach, 9)
            for (x, y, w) in [(157.0, 66.0, 25.0), (177, 48, 29), (150, 26, 34)] {
                oval(x, y, w, 13, violet, outlined: false)
            }
            line([(120, 70), (107, 53)], peach, 5)
            line([(187, 70), (207, 55)], brick, 5)
        case .torii:
            line([(85, 200), (95, 78)], brick, 16)
            line([(232, 199), (219, 78)], brick, 16)
            line([(70, 115), (245, 113)], brick, 12)
            line([(53, 70), (103, 80), (211, 79), (261, 65)], brick, 17)
            line([(48, 62), (101, 72), (213, 72), (266, 56)], ink, 8)
            line([(156, 80), (157, 113)], wood, 9)
            line([(75, 198), (96, 199)], stone, 9)
            line([(223, 198), (243, 197)], stone, 9)
        case .observatory:
            shape([(74, 177), (74, 114), (233, 110), (237, 175)], stone)
            shape([(72, 120), (80, 90), (106, 67), (151, 54), (191, 63), (226, 91), (236, 116)], chalk)
            line([(149, 57), (145, 84), (153, 119)], violet, 8)
            shape([(146, 90), (186, 49), (206, 61), (160, 99)], blue)
            glass(94, 132, 25, 20)
            glass(187, 132, 25, 20)
            shape([(145, 174), (144, 145), (171, 146), (171, 174)], teal)
            line([(56, 187), (249, 187)], green, 7)
        case .skiLift:
            patch([(15, 181), (77, 93), (147, 155), (217, 106), (306, 174),
                   (277, 210), (39, 212)], chalk)
            line([(15, 120), (305, 42)], ink, 4)
            for (x, y): Point in [(73, 105), (162, 81), (250, 57)] {
                line([(x, y), (x + 2, y + 31), (x + 19, y + 30)], wood, 4)
                line([(x + 19, y + 30), (x + 20, y + 45), (x - 6, y + 45)], brick, 6)
            }
            line([(119, 163), (103, 199)], teal, 5)
            line([(128, 168), (112, 204)], violet, 5)
        case .lighthouse:
            shape([(44, 184), (76, 153), (131, 151), (155, 178), (184, 186), (166, 203), (64, 206)], stone)
            lighthouse(109, 180)
            line([(119, 64), (177, 46), (223, 53)], sun, 5)
            line([(119, 65), (170, 69), (219, 74)], sun, 4)
            ripple(222, 179)
            ripple(259, 201)
        case .cargoShip:
            shape([(24, 152), (296, 151), (260, 185), (69, 187), (46, 173)], teal)
            shape([(225, 151), (224, 96), (273, 96), (275, 149)], chalk)
            glass(230, 104, 32, 15)
            for (x, y, color): (CGFloat, CGFloat, UIColor) in [
                (70, 127, brick), (115, 126, sun), (159, 127, violet), (183, 104, blue),
                (96, 103, pink), (138, 103, teal)
            ] {
                shape([(x - 19, y), (x + 20, y), (x + 19, y + 21), (x - 20, y + 21)], color)
                line([(x - 10, y + 5), (x - 10, y + 16)], chalk, 2)
                line([(x + 11, y + 5), (x + 11, y + 16)], chalk, 2)
            }
            ripple(57, 196)
            ripple(227, 200)
        case .fishingPier:
            shape([(24, 185), (163, 130), (258, 127), (267, 148), (174, 151), (34, 209)], wood)
            for (x, y): Point in [(57, 192), (104, 172), (157, 151), (213, 145), (259, 144)] {
                line([(x, y - 11), (x, y + 24)], peach, 6)
            }
            oval(175, 98, 11, 11, peach)
            line([(174, 108), (175, 131), (191, 134)], teal, 8)
            line([(179, 112), (196, 116), (228, 79), (254, 96), (254, 165)], ink, 3)
            oval(255, 171, 6, 7, brick)
            ripple(255, 181)
        case .ferrisWheel:
            oval(157, 111, 75, 75, pink.withAlphaComponent(0.16))
            line([(104, 202), (157, 108), (207, 201)], teal, 9)
            for index in 0..<8 {
                let a = CGFloat(index) * .pi / 4
                let x = 157 + cos(a) * 75
                let y = 111 + sin(a) * 75
                line([(157, 111), (x, y)], violet, 4)
                oval(x, y + 8, 12, 10, index.isMultiple(of: 2) ? peach : blue)
            }
            oval(157, 111, 10, 10, sun)
            line([(84, 205), (228, 205)], wood, 7)
        case .suspensionBridge:
            line([(11, 156), (309, 156)], brick, 11)
            for x: CGFloat in [71, 244] {
                line([(x - 10, 188), (x - 10, 65), (x + 9, 65), (x + 9, 188)], brick, 8)
                line([(x - 12, 104), (x + 12, 104)], peach, 4)
            }
            line([(10, 151), (71, 65), (103, 105), (135, 123), (157, 125),
                  (184, 119), (220, 95), (244, 65), (311, 151)], wood, 6)
            for (x, y): Point in [(39, 112), (96, 99), (124, 120), (155, 125), (187, 119), (219, 96), (277, 112)] {
                line([(x, y), (x, 152)], wood, 3)
            }
            ripple(58, 206)
            ripple(154, 187)
            ripple(252, 204)
        case .seaplane:
            shape([(45, 133), (62, 112), (86, 111), (91, 80), (112, 78), (130, 108),
                   (235, 106), (268, 113), (283, 129), (261, 140), (93, 146)], chalk)
            shape([(127, 127), (180, 101), (231, 67), (255, 70), (223, 114), (171, 139)], teal)
            for x: CGFloat in [205, 226, 247] { glass(x, 112, 11, 13) }
            line([(133, 142), (136, 171), (230, 172), (235, 136)], wood, 5)
            shape([(102, 172), (251, 171), (274, 163), (253, 185), (112, 185)], teal)
            line([(280, 111), (281, 144)], stone, 5)
            ripple(114, 198)
            ripple(256, 203)
        case .pagoda:
            line([(160, 39), (159, 17)], wood, 6)
            for (y, w): (CGFloat, CGFloat) in [(66, 47), (103, 67), (144, 87), (190, 105)] {
                shape([(160 - w * 0.60, y - 20), (160 + w * 0.62, y - 18),
                       (160 + w * 0.59, y + 10), (160 - w * 0.57, y + 12)], peach)
                shape([(160 - w, y - 6), (160 - w * 0.53, y - 11), (158, y - 32),
                       (160 + w * 0.54, y - 12), (160 + w, y - 8), (160 + w * 0.71, y + 5),
                       (160 - w * 0.71, y + 7)], brick)
                line([(160 - w * 0.72, y + 6), (160 + w * 0.71, y + 5)], wood, 4)
            }
            line([(92, 210), (231, 211)], stone, 6)
        case .movieTheater:
            shape([(38, 196), (39, 85), (279, 86), (280, 196)], violet)
            shape([(77, 134), (76, 98), (111, 66), (210, 68), (246, 101), (247, 134)], sun)
            oval(159, 94, 25, 24, stone)
            for (x, y): Point in [(151, 82), (170, 85), (172, 103), (150, 106)] {
                oval(x, y, 4, 4, chalk, outlined: false)
            }
            shape([(114, 195), (113, 143), (207, 144), (207, 195)], teal)
            line([(160, 145), (159, 193)], wood, 5)
            for x: CGFloat in [64, 92, 119, 145, 172, 199, 225, 252] { oval(x, 133, 4, 4, chalk) }
            glass(50, 150, 42, 30)
            glass(228, 150, 39, 30)
        case .waterTower:
            line([(100, 200), (119, 119), (204, 118), (226, 201)], wood, 9)
            line([(101, 193), (198, 128), (219, 188), (116, 132)], stone, 5)
            line([(109, 167), (217, 165)], wood, 6)
            shape([(91, 82), (100, 52), (143, 39), (185, 41), (223, 53), (232, 80),
                   (223, 117), (183, 130), (138, 130), (100, 116)], teal)
            oval(161, 68, 67, 24, blue)
            line([(106, 91), (160, 102), (216, 92)], chalk, 6)
            line([(159, 132), (159, 202), (170, 202)], teal, 6)
        case .iceCreamTruck:
            shape([(37, 171), (37, 97), (213, 96), (234, 106), (269, 133), (282, 168),
                   (274, 178), (43, 177)], pink)
            glass(219, 110, 37, 33)
            shape([(72, 112), (173, 112), (173, 146), (72, 145)], chalk)
            line([(67, 109), (179, 108), (182, 117)], brick, 7)
            shape([(123, 82), (160, 81), (143, 119)], peach)
            oval(142, 67, 22, 20, sun)
            oval(143, 47, 16, 14, violet)
            oval(79, 177, 18, 17, ink)
            oval(241, 177, 18, 17, ink)
            oval(79, 177, 6, 6, stone)
            oval(241, 177, 6, 6, stone)
        case .orchardTractor:
            line([(78, 148), (177, 143), (217, 158), (277, 154)], wood, 10)
            shape([(73, 103), (101, 102), (107, 56), (175, 56), (193, 116),
                   (246, 117), (256, 146), (212, 161), (73, 154)], green)
            glass(113, 67, 49, 40)
            line([(208, 117), (207, 79), (218, 74)], wood, 6)
            oval(110, 155, 45, 44, ink)
            oval(110, 155, 23, 23, sun)
            oval(233, 161, 26, 24, ink)
            oval(233, 161, 11, 11, peach)
            for (x, y): Point in [(84, 143), (100, 124), (123, 125), (143, 143), (126, 181), (91, 180)] {
                line([(x, y), (x + 8, y + 4)], stone, 5)
            }
        case .stoneViaduct:
            line([(9, 89), (78, 87), (157, 92), (234, 88), (311, 90)], wood, 11)
            line([(15, 104), (306, 107)], stone, 17)
            for x: CGFloat in [63, 160, 257] {
                line([(x - 46, 188), (x - 44, 145), (x - 33, 127), (x - 15, 115),
                      (x, 111), (x + 17, 116), (x + 37, 129), (x + 44, 149), (x + 46, 188)], stone, 19)
                line([(x - 44, 151), (x - 33, 156)], chalk, 4)
                line([(x - 17, 118), (x - 14, 126)], chalk, 4)
                line([(x + 34, 128), (x + 29, 135)], chalk, 4)
            }
            line([(4, 80), (313, 80)], chalk, 5)
        case .castle:
            shape([(43, 202), (79, 155), (238, 152), (282, 199)], stone)
            shape([(93, 159), (93, 120), (225, 119), (229, 157)], chalk)
            shape([(126, 124), (124, 81), (198, 81), (201, 121)], chalk)
            shape([(138, 86), (140, 50), (183, 49), (186, 84)], chalk)
            for (x, y, w): (CGFloat, CGFloat, CGFloat) in [(160, 51, 48), (160, 84, 65), (159, 122, 90)] {
                shape([(x - w, y + 7), (x - w * 0.45, y - 1), (x, y - 26),
                       (x + w * 0.45, y - 3), (x + w, y + 4), (x + w * 0.72, y + 13),
                       (x - w * 0.72, y + 14)], teal)
            }
            for x: CGFloat in [112, 145, 177, 210] { line([(x, 140), (x, 150)], wood, 5) }
            for x: CGFloat in [85, 131, 181, 226] { line([(x, 173), (x - 8, 194)], chalk, 4) }
        case .hotSpring:
            oval(160, 161, 121, 50, stone, outlined: false)
            oval(159, 156, 102, 34, teal, outlined: false)
            for (x, y, w): (CGFloat, CGFloat, CGFloat) in [(43, 160, 16), (75, 188, 24), (219, 187, 23), (271, 154, 18)] {
                oval(x, y, w, 11, stone)
            }
            for x: CGFloat in [112, 161, 208] {
                line([(x, 131), (x - 10, 105), (x + 8, 81), (x + 1, 56)], chalk, 9)
            }
            ripple(153, 162)
            line([(31, 129), (38, 67), (51, 71), (50, 114)], wood, 6)
        case .alpineHut:
            shape([(49, 185), (73, 109), (162, 89), (253, 112), (271, 184)], wood)
            shape([(29, 119), (140, 49), (174, 56), (292, 123), (268, 134),
                   (212, 112), (156, 99), (53, 132)], chalk)
            shape([(84, 177), (84, 130), (151, 126), (151, 177)], peach)
            glass(94, 138, 36, 25)
            shape([(177, 184), (176, 136), (211, 135), (211, 185)], peach)
            oval(201, 164, 4, 4, sun)
            for x: CGFloat in [63, 123, 236] { line([(x, 172), (x, 190)], ink, 5) }
            patch([(36, 190), (102, 185), (245, 187), (285, 203), (179, 211), (56, 209)], chalk)
        case .craterLake:
            shape([(20, 154), (57, 105), (104, 70), (170, 52), (230, 70), (280, 108),
                   (304, 153), (265, 174), (158, 201), (69, 184)], stone)
            shape([(48, 132), (88, 105), (135, 91), (200, 94), (246, 114), (276, 137),
                   (245, 159), (163, 176), (82, 155)], teal)
            line([(32, 139), (57, 106), (107, 72), (165, 54), (225, 71), (277, 105)], chalk, 7)
            line([(98, 144), (135, 151), (178, 147), (213, 137)], chalk, 4)
            line([(125, 123), (170, 116), (209, 126)], blue, 5)
        case .islandVillage:
            patch([(18, 181), (57, 156), (113, 128), (199, 131), (258, 153), (303, 182),
                   (260, 201), (151, 212), (56, 201)], sun)
            patch([(43, 174), (76, 145), (129, 121), (195, 125), (242, 141), (273, 176),
                   (181, 193), (79, 190)], green)
            for (x, y, color): (CGFloat, CGFloat, UIColor) in [(87, 168, brick), (149, 152, teal), (213, 166, violet)] {
                shape([(x - 22, y), (x - 21, y - 38), (x + 21, y - 37), (x + 22, y)], peach)
                shape([(x - 30, y - 36), (x + 1, y - 61), (x + 29, y - 37)], color)
                line([(x, y), (x, y - 16)], wood, 6)
            }
            tree(264, 174, 46, conifer: false)
            ripple(42, 203)
            ripple(272, 209)
        case .coastGuardCutter:
            shape([(28, 147), (294, 140), (268, 177), (74, 181), (47, 168)], chalk)
            shape([(143, 146), (148, 104), (229, 100), (261, 127), (254, 142)], chalk)
            glass(165, 109, 57, 17)
            line([(123, 146), (139, 175)], brick, 11)
            line([(180, 105), (183, 56), (204, 62), (199, 72), (182, 68)], wood, 5)
            line([(170, 62), (195, 57)], stone, 5)
            oval(208, 155, 10, 10, brick)
            oval(208, 155, 4, 4, chalk)
            ripple(62, 193)
            ripple(233, 198)
        case .oilPlatform:
            for x: CGFloat in [79, 123, 205, 245] {
                line([(x, 111), (x - 11, 196)], wood, 8)
            }
            line([(74, 130), (120, 186), (200, 133), (236, 184)], peach, 6)
            shape([(47, 98), (260, 98), (271, 121), (42, 124)], stone)
            line([(121, 98), (142, 29), (163, 30), (190, 99)], sun, 7)
            line([(133, 64), (179, 85), (132, 84), (171, 61)], wood, 4)
            shape([(201, 98), (201, 67), (250, 65), (250, 98)], chalk)
            line([(61, 85), (113, 84)], teal, 9)
            oval(85, 81, 18, 6, chalk)
            ripple(49, 201)
            ripple(252, 208)
        case .drawbridge:
            shape([(41, 185), (43, 114), (80, 114), (80, 184)], stone)
            shape([(243, 185), (244, 111), (281, 112), (280, 184)], stone)
            line([(49, 113), (49, 67), (74, 66), (74, 111)], brick, 8)
            line([(251, 110), (251, 63), (275, 63), (275, 112)], brick, 8)
            line([(5, 143), (84, 142), (144, 92)], wood, 13)
            line([(177, 93), (240, 140), (314, 141)], wood, 13)
            line([(61, 68), (147, 95)], stone, 5)
            line([(266, 65), (177, 92)], stone, 5)
            line([(59, 130), (89, 129), (137, 88)], chalk, 4)
            line([(187, 88), (236, 129), (265, 128)], chalk, 4)
            ripple(147, 188)
            ripple(195, 206)
        default:
            break
        }
    }

    mutating func glass(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        shape([(x, y + 1), (x + width, y), (x + width - 1, y + height),
               (x - 1, y + height)], blue)
        line([(x + width * 0.26, y + height * 0.63), (x + width * 0.61, y + height * 0.24)], chalk, 2)
    }

    mutating func clock(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
        oval(x, y, radius, radius, chalk)
        line([(x, y - radius * 0.66), (x, y), (x + radius * 0.47, y + radius * 0.28)], ink, 3)
    }

    mutating func envelope(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
        let h = width * 0.24
        shape([(x - width / 2, y - h), (x + width / 2, y - h), (x + width / 2, y + h),
               (x - width / 2, y + h)], chalk)
        line([(x - width / 2, y - h), (x, y + 1), (x + width / 2, y - h)], wood, 2)
    }

    mutating func random(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return lower + (upper - lower) * CGFloat(state >> 40) / 16_777_216
    }

    mutating func accent(_ offset: Int = 0) -> UIColor {
        [peach, pink, violet, brick, teal, sun][(offset + Int(random(0, 6))) % 6]
    }

    mutating func strokePath(_ points: [Point], closed: Bool) -> CGMutablePath {
        let path = CGMutablePath()
        let loosePoints = points.map {
            CGPoint(x: $0.0 + random(-1.5, 1.5), y: $0.1 + random(-1.5, 1.5))
        }
        guard let first = loosePoints.first else { return path }
        path.move(to: first)
        var start = first
        for index in 1..<(loosePoints.count + (closed ? 1 : 0)) {
            let end = index == loosePoints.count ? first : loosePoints[index]
            let dx = end.x - start.x
            let dy = end.y - start.y
            let length = hypot(dx, dy)
            if length > 12 {
                let sway = random(-1, 1) * min(6, length * 0.15)
                let control = CGPoint(x: (start.x + end.x) / 2 - dy / length * sway,
                                      y: (start.y + end.y) / 2 + dx / length * sway)
                path.addQuadCurve(to: end, control: control)
            } else {
                path.addLine(to: end)
            }
            start = end
        }
        if closed { path.closeSubpath() }
        return path
    }

    mutating func line(_ points: [Point], _ color: UIColor, _ width: CGFloat) {
        context.addPath(strokePath(points, closed: false))
        context.setStrokeColor(color.withAlphaComponent(0.86).cgColor)
        context.setLineWidth(width)
        context.strokePath()
        context.addPath(strokePath(points, closed: false))
        context.setStrokeColor(color.withAlphaComponent(0.31).cgColor)
        context.setLineWidth(width * 0.48)
        context.strokePath()
    }

    mutating func shape(_ points: [Point], _ color: UIColor, outlined: Bool = true) {
        let path = strokePath(points, closed: true)
        context.setFillColor(color.withAlphaComponent(outlined ? 0.75 : 0.46).cgColor)
        context.addPath(path)
        context.fillPath()

        context.saveGState()
        context.addPath(path)
        context.clip()
        let bounds = path.boundingBoxOfPath
        let scratches = CGMutablePath()
        for index in 0..<9 {
            let y = bounds.minY + bounds.height * CGFloat(index) / 8 + random(-3, 3)
            let x = bounds.minX + bounds.width * random(-0.15, 0.21)
            let endX = bounds.maxX + bounds.width * random(-0.19, 0.12)
            let endY = y + bounds.width * random(-0.14, -0.03)
            let midpoint = CGPoint(x: (x + endX) / 2, y: (y + endY) / 2 + random(-4, 4))
            scratches.move(to: CGPoint(x: x, y: y))
            scratches.addQuadCurve(to: CGPoint(x: endX, y: endY), control: midpoint)
        }
        context.addPath(scratches)
        context.setStrokeColor(chalk.withAlphaComponent(outlined ? 0.40 : 0.28).cgColor)
        context.setLineWidth(min(4.7, max(1.1, bounds.height * 0.075)))
        context.strokePath()
        context.restoreGState()

        if outlined {
            context.addPath(path)
            context.setStrokeColor(ink.withAlphaComponent(0.76).cgColor)
            context.setLineWidth(3.5)
            context.strokePath()
        }
    }

    mutating func patch(_ points: [Point], _ color: UIColor) { shape(points, color, outlined: false) }

    mutating func oval(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
                       _ color: UIColor, outlined: Bool = true) {
        let outline: [Point] = [
            (x - width, y), (x - width * 0.72, y - height * 0.70), (x, y - height),
            (x + width * 0.77, y - height * 0.67), (x + width, y + height * 0.14),
            (x + width * 0.68, y + height * 0.78), (x - width * 0.14, y + height),
            (x - width * 0.83, y + height * 0.59)
        ]
        shape(outline, color, outlined: outlined)
    }

    mutating func flower(_ x: CGFloat, _ ground: CGFloat, _ height: CGFloat, _ color: UIColor) {
        let y = ground - height
        line([(x, ground), (x + 3, ground - height * 0.48), (x - 1, y + 4)], green, 4)
        line([(x + 2, ground - 8), (x + 13, ground - 19)], green, 4)
        let petal = max(4, min(10, height * 0.17))
        for (dx, dy): Point in [(-0.82, -0.30), (-0.11, -0.87), (0.78, -0.25), (0.52, 0.58), (-0.48, 0.68)] {
            oval(x + dx * petal, y + dy * petal, petal * 0.63, petal * 0.60, color, outlined: false)
        }
        oval(x, y, petal * 0.47, petal * 0.44, sun)
    }

    mutating func reeds(_ x: CGFloat, _ y: CGFloat) {
        line([(x - 12, y - 16), (x, y), (x - 1, y - 29), (x + 5, y), (x + 15, y - 19)], green, 5)
    }

    mutating func lily(_ x: CGFloat, _ y: CGFloat) {
        shape([(x - 15, y), (x - 9, y - 10), (x + 14, y - 8), (x + 5, y), (x + 15, y + 5),
               (x + 8, y + 12), (x - 12, y + 7)], lime)
    }

    mutating func mailbox(_ x: CGFloat, _ y: CGFloat) {
        line([(x, y), (x, y - 46)], wood, 6)
        shape([(x - 14, y - 48), (x - 10, y - 60), (x + 10, y - 62), (x + 16, y - 51),
               (x + 15, y - 37), (x - 14, y - 37)], brick)
        line([(x - 7, y - 47), (x + 7, y - 47)], chalk, 3)
    }

    mutating func vehicle(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ color: UIColor) {
        let left = x - width / 2, right = x + width / 2
        shape([(left, y), (left + 3, y - 15), (x - 23, y - 20), (x - 15, y - 37),
               (x + 19, y - 35), (x + 27, y - 20), (right - 4, y - 16), (right, y)], color)
        shape([(x - 11, y - 30), (x + 15, y - 30), (x + 21, y - 20), (x - 16, y - 20)], blue)
        oval(x - width * 0.28, y, 9, 8, stone)
        oval(x + width * 0.28, y, 9, 8, stone)
    }

    mutating func bench(_ x: CGFloat, _ y: CGFloat) {
        for dx: CGFloat in [-24, 24] { line([(x + dx, y + 10), (x + dx, y - 21)], ink, 5) }
        line([(x - 30, y - 19), (x + 30, y - 19)], wood, 9)
        line([(x - 30, y - 4), (x + 31, y - 4)], peach, 9)
    }

    mutating func tree(_ x: CGFloat, _ y: CGFloat, _ height: CGFloat, conifer: Bool) {
        line([(x - 1, y + 6), (x, y - height * 0.54)], wood, 7)
        if conifer {
            shape([(x - height * 0.40, y - 10), (x - height * 0.19, y - height * 0.58),
                   (x, y - height), (x + height * 0.20, y - height * 0.59), (x + height * 0.37, y - 12)], green)
            line([(x - height * 0.18, y - height * 0.45), (x + height * 0.12, y - height * 0.36)], lime, 4)
        } else {
            oval(x, y - height * 0.62, height * 0.39, height * 0.34, lime)
            oval(x - height * 0.13, y - height * 0.62, 4, 4, brick, outlined: false)
            oval(x + height * 0.16, y - height * 0.50, 5, 5, peach, outlined: false)
        }
    }

    mutating func ridge(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, color: UIColor) {
        patch([(x, y + 17), (x + width * 0.20, y - height * 0.39),
               (x + width * 0.41, y - height), (x + width * 0.62, y - height * 0.58),
               (x + width * 0.75, y - height * 0.67), (x + width, y + 2),
               (x + width * 0.90, y + 27), (x + width * 0.23, y + 37)], color)
    }

    mutating func tent(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
        shape([(x - width * 0.55, y), (x - 13, y - width * 0.64), (x + width * 0.22, y - width * 0.53),
               (x + width * 0.54, y), (x - 1, y + 3)], accent(4))
        shape([(x - width * 0.28, y), (x - 10, y - width * 0.51), (x + width * 0.17, y)], chalk)
        line([(x - width * 0.51, y - 1), (x - width * 0.67, y + 8)], wood, 4)
    }

    mutating func campfire(_ x: CGFloat, _ y: CGFloat) {
        line([(x - 14, y + 5), (x + 15, y - 1)], wood, 8)
        line([(x - 13, y - 1), (x + 12, y + 6)], wood, 8)
        shape([(x - 11, y - 3), (x - 14, y - 16), (x - 4, y - 26), (x + 1, y - 39),
               (x + 11, y - 17), (x + 15, y - 8), (x + 6, y - 2)], peach)
        line([(x, y - 9), (x + 3, y - 21)], sun, 4)
    }

    mutating func ripple(_ x: CGFloat, _ y: CGFloat) {
        line([(x - 18, y), (x - 6, y - 4), (x + 5, y + 1), (x + 18, y - 3)], chalk, 4)
    }

    mutating func lighthouse(_ x: CGFloat, _ y: CGFloat) {
        shape([(x - 21, y), (x - 14, y - 101), (x + 14, y - 101), (x + 21, y)], chalk)
        for step in 0..<3 {
            let stripe = y - 21 - CGFloat(step) * 28
            let half = 19 - CGFloat(step) * 2
            shape([(x - half, stripe), (x + half, stripe - 2), (x + half, stripe + 10),
                   (x - half, stripe + 12)], brick, outlined: false)
        }
        shape([(x - 22, y - 100), (x - 15, y - 121), (x + 16, y - 122), (x + 22, y - 101)], sun)
        shape([(x - 23, y - 120), (x + 1, y - 140), (x + 23, y - 121)], brick)
        oval(x, y - 13, 6, 9, wood)
    }
}
