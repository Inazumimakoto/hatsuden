import CoreGraphics

/// Each case is a drawing for one original artwork ID. The helpers are the
/// crayons and joints, while each species supplies its own outline and marks.
enum LandAnimalDrawings {
    static func draw(id: Int, ink: CrayonCanvas, runFrame: Int? = nil, asleep: Bool = false) {
        let motion: CGFloat
        switch runFrame {
        case 0: motion = 7
        case 2: motion = -7
        default: motion = 0
        }
        let b = Brush(ink: ink, motion: motion, asleep: asleep)
        switch id {
        case 1...24: small(id, b)
        case 25...39: woodland(id, b)
        case 40...57: carnivores(id, b)
        case 58...74: oddMammals(id, b)
        default: preconditionFailure("Unknown land artwork ID: \(id)")
        }
    }

    private typealias Point = (CGFloat, CGFloat)
    private typealias Box = (CGFloat, CGFloat, CGFloat, CGFloat)
    private typealias Color = UInt32
    private static let black: Color = 0x382D37
    private static let cream: Color = 0xFFF1D0
    private static let white: Color = 0xFFF9E8
    private static let brown: Color = 0x945E49
    private static let darkBrown: Color = 0x603B39
    private static let tan: Color = 0xCD9B67
    private static let gold: Color = 0xEAB853
    private static let orange: Color = 0xE98144
    private static let peach: Color = 0xEDA893
    private static let pink: Color = 0xE892A3
    private static let red: Color = 0xCC5751
    private static let gray: Color = 0x8594A1
    private static let slate: Color = 0x586A81
    private static let blue: Color = 0x5C99D5
    private static let green: Color = 0x78A95F
    private static let violet: Color = 0xA485BA

    private struct Brush {
        let ink: CrayonCanvas
        let motion: CGFloat
        let asleep: Bool

        func o(_ box: Box, _ fill: Color, _ outline: Bool = true, _ width: CGFloat = 4) {
            ink.oval(box.0, box.1, box.2, box.3, fill: CrayonCanvas.color(fill),
                     border: outline ? CrayonCanvas.color(black) : nil, weight: width)
        }

        func p(_ points: [Point], _ fill: Color, _ outline: Bool = true, _ width: CGFloat = 4) {
            ink.polygon(points, fill: CrayonCanvas.color(fill),
                        border: outline ? CrayonCanvas.color(black) : nil, weight: width)
        }

        func l(_ points: [Point], _ color: Color = black, _ width: CGFloat = 4) {
            ink.line(points, color: CrayonCanvas.color(color), weight: width)
        }

        func eye(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 9) {
            if asleep {
                l([(x, y), (x + size, y - 0.6), (x + 1, y + size), (x + size, y + size - 1)], slate, 2.4)
            } else {
                o((x, y, size, size * 1.19), black, false)
                if size >= 10 {
                    o((x + size * 0.19, y + size * 0.16, size * 0.29, size * 0.29), white, false)
                }
            }
        }

        func whiskers(_ x: CGFloat, _ y: CGFloat, spread: CGFloat = 17) {
            for index in -1...1 {
                let d = CGFloat(index)
                l([(x, y + d * 3), (x + spread, y + d * 7 - 1)], darkBrown, 2.4)
            }
        }

        func step(_ x: CGFloat, _ y: CGFloat, _ length: CGFloat, _ coat: Color, back: Bool = false,
                  hoof: Bool = false, thickness: CGFloat = 10) {
            let d = (back ? -motion : motion)
            let end = x + d
            l([(x, y), (x - length * 0.10 + d * 0.4, y + length * 0.54),
               (end, y + length - abs(d) * 0.18), (end + thickness * 0.85, y + length - 1)],
              black, thickness + 5)
            l([(x, y), (x - length * 0.10 + d * 0.4, y + length * 0.54),
               (end, y + length - abs(d) * 0.18), (end + thickness * 0.85, y + length - 1)],
              coat, thickness)
            if hoof { l([(end - 3, y + length - 0.9), (end + thickness, y + length - 1)], black, thickness * 0.82) }
        }

        func tail(_ curve: [Point], _ coat: Color, _ width: CGFloat) {
            l(curve, black, width + 5)
            l(curve, coat, width)
        }

        func spot(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ coat: Color = black) {
            o((x, y, size, size * 0.82), coat, false)
        }

        func smile(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 16) {
            l([(x, y), (x + width * 0.36, y + 4), (x + width * 0.75, y + 3), (x + width, y - 2)], black, 2.9)
        }
    }

    private static func small(_ id: Int, _ b: Brush) {
        switch id {
        case 1: // ハムスター — round cheeks and pocket paws
            b.o((55, 118, 49, 51), orange)
            b.step(92, 170, 16, tan, back: true)
            b.step(150, 172, 13, tan)
            b.o((59, 92, 126, 102), orange)
            b.o((80, 128, 86, 63), cream, false)
            b.o((109, 52, 42, 48), orange)
            b.o((153, 56, 44, 43), orange)
            b.o((119, 60, 22, 30), pink, false)
            b.o((165, 62, 21, 24), pink, false)
            b.o((111, 76, 93, 86), orange)
            b.o((155, 113, 45, 42), cream, false)
            b.o((124, 118, 35, 29), peach, false)
            b.eye(145, 98, 11)
            b.eye(174, 97, 8)
            b.o((184, 115, 14, 11), black, false)
            b.smile(173, 134, 18)
            b.l([(119, 157), (130, 166), (145, 155)], brown, 5)
        case 2: // リス — brush tail and a small acorn
            b.p([(81, 162), (46, 145), (31, 121), (24, 81), (36, 47), (61, 28),
                 (95, 28), (117, 49), (120, 76), (103, 98), (81, 109), (72, 130), (96, 152)], brown)
            b.l([(54, 49), (75, 44), (98, 60), (93, 77), (73, 89), (60, 106)], orange, 9)
            b.step(104, 175, 16, brown, back: true)
            b.step(150, 170, 20, tan)
            b.o((86, 101, 79, 84), tan)
            b.o((112, 127, 47, 53), cream, false)
            b.p([(132, 91), (132, 48), (151, 70), (168, 55), (174, 92)], brown)
            b.o((124, 76, 66, 64), brown)
            b.p([(166, 100), (196, 111), (178, 126), (158, 122)], tan, false)
            b.eye(159, 94, 10)
            b.spot(187, 108, 11)
            b.o((150, 144, 25, 29), gold)
            b.p([(148, 150), (152, 139), (170, 137), (178, 147)], darkBrown)
            b.l([(127, 144), (138, 155), (151, 150)], brown, 7)
        case 3: // ウサギ — leaning ears and two visibly springy hind feet
            b.o((29, 120, 31, 29), white)
            b.o((44, 109, 105, 64), 0xC4AACD)
            b.o((52, 141, 57, 52), violet)
            b.tail([(83, 171), (99 + b.motion, 188), (125 + b.motion, 187)], violet, 12)
            b.tail([(140, 154), (159 - b.motion, 172), (180 - b.motion, 175)], 0xC4AACD, 9)
            b.p([(132, 104), (112, 69), (107, 29), (121, 24), (136, 45), (148, 91)], violet)
            b.p([(152, 98), (148, 58), (153, 21), (170, 29), (175, 65), (169, 99)], 0xC4AACD)
            b.l([(161, 36), (162, 64), (159, 83)], pink, 8)
            b.o((126, 89, 78, 59), 0xC4AACD)
            b.o((170, 117, 35, 27), white, false)
            b.eye(165, 105, 10)
            b.spot(196, 116, 10, pink)
            b.whiskers(194, 128, spread: 25)
        case 4: // ネコ — ears, bent tail and tabby brow
            b.tail([(70, 133), (39, 117), (24, 91), (33, 67), (49, 70)], gold, 13)
            b.step(76, 149, 43, gold, back: true)
            b.step(140, 146, 39, gold)
            b.o((46, 100, 113, 70), gold)
            b.o((111, 132, 58, 37), cream, false)
            b.p([(125, 105), (122, 49), (155, 75), (181, 49), (194, 103), (176, 143), (145, 140)], gold)
            b.p([(128, 63), (132, 86), (147, 79)], pink, false)
            b.p([(175, 78), (181, 63), (185, 88)], pink, false)
            b.l([(149, 83), (154, 94), (160, 84), (168, 95), (173, 82)], brown, 3)
            b.eye(140, 99)
            b.eye(171, 98)
            b.o((149, 115, 36, 23), cream, false)
            b.p([(160, 114), (172, 114), (166, 122)], darkBrown, false)
            b.smile(157, 125, 17)
            b.whiskers(145, 123, spread: -24)
            b.whiskers(181, 121, spread: 24)
        case 5: // イヌ — floppy ears, bright chest and tongue
            b.tail([(65, 133), (38, 116), (31, 89)], brown, 15)
            b.step(67, 154, 36, cream, back: true)
            b.step(133, 151, 44, tan)
            b.o((46, 101, 108, 71), tan)
            b.o((103, 109, 48, 61), cream, false)
            b.o((118, 61, 77, 82), tan)
            b.p([(137, 71), (118, 63), (109, 84), (108, 115), (127, 133), (142, 109)], brown)
            b.o((174, 72, 32, 64), brown)
            b.o((147, 106, 68, 43), cream)
            b.eye(151, 94, 11)
            b.o((190, 105, 25, 16), black)
            b.o((173, 140, 15, 22), pink)
            b.smile(164, 135, 26)
        case 6: // フェレット — low sinuous body, dark little socks and a mask
            b.tail([(60, 142), (38, 138), (21, 119), (25, 100)], brown, 12)
            b.step(71, 156, 24, darkBrown, back: true)
            b.step(150, 150, 28, darkBrown)
            b.p([(46, 140), (61, 119), (85, 116), (110, 129), (137, 118), (152, 94),
                 (169, 101), (181, 125), (166, 153), (122, 169), (74, 166)], tan)
            b.o((137, 100, 74, 50), cream)
            b.o((148, 86, 25, 22), brown)
            b.p([(153, 116), (167, 107), (188, 114), (194, 130), (176, 133)], brown, false)
            b.eye(172, 115, 9)
            b.spot(201, 122, 12, darkBrown)
            b.whiskers(199, 136, spread: 20)
        case 7: // カワウソ — long tapered swimming tail and broad webbed paws
            b.p([(77, 140), (32, 139), (15, 158), (38, 162), (75, 159), (103, 166)], brown)
            b.o((56, 104, 116, 62), brown)
            b.p([(74, 153), (59, 183), (85, 185), (90, 173), (106, 172), (111, 155)], tan)
            b.o((119, 113, 53, 51), tan, false)
            b.o((146, 77, 25, 22), brown)
            b.o((146, 92, 65, 55), brown)
            b.o((166, 114, 47, 28), cream)
            b.eye(176, 102)
            b.o((198, 115, 17, 12), black, false)
            b.whiskers(204, 131, spread: 22)
            b.l([(147, 145), (156 + b.motion, 163), (178 + b.motion, 156)], darkBrown, 9)
        case 8: // タヌキ — shaggy winter ball, separate eye patches and unbanded tail
            b.p([(66, 121), (44, 118), (22, 142), (38, 160), (68, 154), (82, 136)], darkBrown)
            b.step(75, 154, 37, darkBrown, back: true)
            b.step(141, 158, 33, darkBrown)
            b.p([(41, 148), (43, 116), (58, 109), (65, 96), (93, 98), (116, 87), (146, 105),
                 (168, 120), (173, 145), (158, 161), (137, 171), (104, 176), (69, 170)], tan)
            b.o((128, 74, 27, 34), darkBrown)
            b.o((174, 70, 27, 37), darkBrown)
            b.p([(126, 107), (148, 91), (184, 91), (202, 109), (208, 133), (181, 149), (148, 141)], tan)
            b.o((139, 105, 30, 23), darkBrown, false)
            b.o((177, 102, 26, 22), darkBrown, false)
            b.eye(151, 108, 8)
            b.eye(187, 106, 8)
            b.o((161, 122, 45, 23), cream, false)
            b.spot(187, 120, 13)
        case 9: // キツネ — sharp white muzzle and a brush with a pale tip
            b.p([(87, 127), (68, 108), (46, 94), (25, 94), (11, 110), (28, 132),
                 (53, 149), (83, 151)], orange)
            b.p([(44, 96), (25, 94), (11, 110), (28, 132), (45, 140), (40, 122), (49, 113)], cream)
            b.step(86, 140, 45, darkBrown, back: true, thickness: 7)
            b.step(144, 137, 44, darkBrown, thickness: 7)
            b.o((68, 95, 106, 65), orange)
            b.p([(135, 89), (132, 42), (157, 72), (172, 46), (181, 86), (218, 116), (192, 139), (150, 132)], orange)
            b.p([(153, 109), (181, 111), (217, 116), (192, 139), (172, 135)], cream, false)
            b.eye(174, 96)
            b.spot(211, 112, 10)
        case 10: // 足つきサメ — pointed fins, three gills and an absurd pair of feet
            b.p([(60, 114), (20, 70), (30, 114), (18, 146), (61, 132)], blue)
            b.p([(104, 99), (120, 56), (144, 97)], slate)
            b.step(101, 150, 37, blue, back: true)
            b.step(161, 151, 32, blue)
            b.p([(53, 119), (80, 102), (124, 92), (167, 92), (199, 109), (220, 130),
                 (201, 148), (167, 159), (115, 155), (79, 143)], blue)
            b.p([(102, 136), (163, 134), (219, 130), (201, 148), (168, 159), (116, 155)], cream, false)
            b.p([(126, 119), (109, 150), (147, 142)], slate)
            for x: CGFloat in [151, 158, 165] { b.l([(x, 111), (x - 2, 120), (x, 129)], slate, 2.3) }
            b.eye(179, 106, 11)
            b.smile(187, 134, 20)
        case 11: // ダチョウ — black wings, bare high neck and long pink legs
            b.step(104, 139, 64, pink, back: true, thickness: 7)
            b.step(139, 139, 67, peach, thickness: 7)
            b.p([(64, 100), (41, 78), (29, 89), (40, 110), (29, 120), (73, 139)], white)
            b.o((57, 86, 112, 65), 0x4D4250)
            b.p([(92, 98), (115, 104), (151, 117), (135, 137), (109, 139), (87, 124)], white)
            b.tail([(149, 113), (166, 89), (174, 54), (173, 39)], peach, 13)
            b.o((160, 25, 38, 33), peach)
            b.p([(192, 38), (217, 42), (194, 52)], gold)
            b.eye(182, 33, 9)
        case 12: // ゾウ — giant ear, lowered trunk, tusk
            b.tail([(56, 114), (37, 128), (31, 151)], gray, 7)
            b.step(60, 149, 42, slate, back: true, thickness: 17)
            b.step(101, 150, 46, gray, thickness: 19)
            b.step(150, 144, 44, gray, back: true, thickness: 17)
            b.o((43, 75, 138, 99), gray)
            b.p([(163, 90), (200, 95), (203, 123), (202, 160), (215, 162), (219, 150),
                 (228, 155), (226, 176), (211, 183), (192, 176), (184, 145), (171, 145)], gray)
            b.p([(184, 132), (207, 130), (199, 142), (186, 146)], cream)
            b.o((111, 76, 59, 83), slate)
            b.o((121, 87, 40, 57), pink, false)
            b.eye(178, 110, 10)
            b.l([(191, 151), (198, 154), (200, 152)], slate, 2.7)
        case 13: // ティラノ — huge toothed jaw, small arms and muscular hind leg
            b.p([(113, 144), (67, 139), (34, 125), (11, 104), (23, 137), (53, 158),
                 (106, 168), (140, 160)], green)
            b.o((72, 102, 100, 71), green)
            b.o((92, 135, 50, 45), 0x57875B)
            b.tail([(112, 166), (125 + b.motion, 190), (151 + b.motion, 191)], 0x57875B, 15)
            b.tail([(149, 122), (159, 138), (171, 134)], green, 8)
            b.p([(140, 119), (128, 87), (139, 54), (167, 43), (207, 44), (225, 66),
                 (220, 87), (184, 91), (215, 100), (206, 111), (171, 115), (158, 127)], green)
            b.p([(188, 89), (199, 88), (195, 99)], cream, false)
            b.p([(204, 88), (214, 87), (210, 99)], cream, false)
            b.l([(163, 61), (176, 57), (184, 62)], darkBrown, 5)
            b.eye(170, 66, 13)
            b.spot(211, 66, 7)
        case 14: // ダイオウイカ — narrow spear mantle, side fins, paired long clubs
            b.p([(120, 17), (79, 65), (80, 104), (102, 102), (121, 85), (148, 109),
                 (165, 95), (160, 62)], red)
            b.p([(120, 20), (104, 57), (100, 114), (110, 137), (132, 136), (144, 110), (136, 61)], 0xDF7664)
            for index in 0..<8 {
                let x = CGFloat(101 + index * 6)
                let bend = CGFloat(index * 7 - 23)
                b.tail([(x, 129), (x + bend * 0.3, 157), (x + bend, 181), (x + bend + 6 + b.motion, 191)], red, 5)
            }
            b.tail([(105, 131), (76, 159), (61, 196), (40, 210 + b.motion)], red, 7)
            b.tail([(139, 132), (167, 157), (177, 196), (196, 210 - b.motion)], red, 7)
            b.o((35, 200, 16, 22), red)
            b.o((191, 201, 16, 22), red)
            b.o((103, 111, 37, 25), white)
            b.eye(114, 115, 13)
            b.l([(117, 48), (116, 75), (118, 103)], peach, 4)
        case 15: // 発電怪獣 — horn crown, neon plates and a zigzag chest
            b.p([(92, 141), (55, 160), (21, 145), (36, 172), (65, 182), (108, 168)], violet)
            for (x, y): Point in [(60, 148), (78, 124), (84, 102), (91, 83)] {
                b.p([(x - 8, y + 11), (x - 14, y - 17), (x + 9, y + 1)], blue)
            }
            b.step(100, 158, 32, violet, back: true, thickness: 17)
            b.step(146, 156, 37, violet, thickness: 17)
            b.o((86, 83, 84, 96), violet)
            b.p([(143, 111), (121, 77), (125, 42), (140, 30), (156, 47), (171, 26),
                 (182, 49), (200, 61), (193, 90), (173, 103)], violet)
            b.eye(167, 62, 13)
            b.p([(136, 116), (154, 116), (146, 133), (160, 134), (132, 161), (137, 141), (123, 141)], gold)
            b.l([(170, 84), (183, 88), (194, 80)], black, 3)
        case 16: // モモンガ — broad four-corner gliding membrane, head-on
            b.p([(115, 135), (92, 163), (103, 187), (122, 205), (142, 199), (141, 180), (130, 167), (142, 130)], brown)
            b.p([(91, 69), (48, 61), (20, 75), (39, 115), (29, 155), (76, 154), (119, 178),
                 (161, 156), (213, 160), (200, 113), (219, 78), (193, 61), (150, 71)], tan)
            b.p([(89, 93), (61, 86), (42, 84), (58, 130), (89, 147), (119, 158),
                 (155, 144), (185, 126), (197, 85), (170, 90), (148, 96)], cream, false)
            b.o((86, 49, 25, 31), brown)
            b.o((139, 50, 24, 30), brown)
            b.o((80, 63, 88, 74), tan)
            b.o((100, 92, 52, 36), cream, false)
            b.eye(94, 81, 15)
            b.eye(137, 81, 15)
            b.spot(119, 105, 11)
        case 17: // ハリネズミ — deliberately uneven rows of spines
            b.step(91, 157, 22, tan, back: true, thickness: 7)
            b.step(148, 157, 25, tan, thickness: 7)
            b.p([(36, 146), (25, 128), (34, 119), (24, 105), (42, 103), (33, 78),
                 (55, 85), (59, 60), (78, 75), (92, 54), (106, 72), (128, 58), (135, 79),
                 (157, 70), (158, 89), (178, 91), (181, 108), (165, 146), (126, 169), (69, 167)], darkBrown)
            for (x, y): Point in [(54, 114), (76, 96), (89, 133), (102, 97), (122, 118), (74, 145), (112, 148)] {
                b.l([(x - 8, y - 11), (x, y), (x + 5, y - 8)], tan, 3.6)
            }
            b.p([(140, 108), (166, 102), (182, 114), (212, 143), (184, 159), (152, 153)], cream)
            b.o((145, 100, 24, 27), tan)
            b.eye(174, 123, 9)
            b.spot(205, 139, 12)
        case 18: // モルモット — squat tricolour cavy, no tail
            b.o((39, 100, 153, 79), cream)
            b.p([(46, 115), (67, 103), (96, 101), (102, 123), (86, 161), (61, 169), (45, 149)], orange, false)
            b.o((117, 92, 76, 70), darkBrown)
            b.o((129, 89, 30, 22), pink)
            b.p([(164, 94), (168, 113), (184, 121), (191, 145), (177, 158), (157, 143), (155, 115)], white, false)
            b.o((75 + b.motion, 163, 23, 18), peach)
            b.o((151 - b.motion, 164, 24, 18), peach)
            b.eye(157, 113)
            b.spot(185, 134, 9, pink)
            b.whiskers(182, 140)
        case 19: // デグー — sand-coloured sitter with dark brush on a wiry tail
            b.tail([(105, 169), (76, 175), (48, 164), (30, 139), (34, 110)], tan, 6)
            b.p([(27, 115), (19, 94), (28, 78), (41, 99), (37, 114)], darkBrown)
            b.o((88, 103, 66, 84), tan)
            b.o((114, 122, 40, 59), cream, false)
            b.o((105, 61, 32, 38), tan)
            b.o((112, 67, 16, 25), peach, false)
            b.p([(105, 101), (126, 83), (152, 81), (169, 97), (188, 112), (177, 128), (141, 132), (116, 120)], tan)
            b.eye(151, 98, 9)
            b.spot(180, 109, 9)
            b.o((174, 124, 8, 8), orange, false)
            b.l([(135, 133), (148, 143), (163, 141)], brown, 6)
            b.o((95 + b.motion, 174, 50, 16), tan)
        case 20: // チンチラ — plush silver body, enormous round ears
            b.p([(94, 160), (59, 157), (37, 139), (31, 115), (47, 93), (57, 102),
                 (51, 124), (69, 139), (102, 142)], slate)
            b.o((72, 98, 108, 87), gray)
            b.o((103, 128, 70, 51), white, false)
            b.o((105, 43, 48, 53), gray)
            b.o((157, 41, 48, 51), gray)
            b.o((114, 54, 28, 31), pink, false)
            b.o((167, 52, 26, 29), pink, false)
            b.o((110, 78, 92, 71), gray)
            b.o((156, 117, 51, 27), white, false)
            b.eye(138, 101, 12)
            b.eye(175, 97, 12)
            b.spot(192, 115, 10, pink)
            b.whiskers(191, 129, spread: 32)
            b.o((108 + b.motion, 172, 29, 14), slate)
        case 21: // ヤマネ — tiny curled tail wrapped over a russet back
            b.tail([(80, 147), (50, 140), (33, 118), (40, 94), (61, 90), (78, 105)], orange, 19)
            b.o((62, 112, 100, 63), orange)
            b.o((108, 141, 50, 31), cream, false)
            b.o((132, 87, 25, 26), brown)
            b.o((168, 86, 23, 26), orange)
            b.p([(125, 111), (143, 98), (174, 100), (194, 122), (177, 138), (144, 139)], orange)
            b.eye(158, 110, 13)
            b.spot(184, 119, 10)
            b.o((101 + b.motion, 166, 29, 12), peach, false)
        case 22: // ハツカネズミ — thin bare tail and wide pink ears
            b.tail([(70, 148), (48, 162), (23, 161), (15, 145), (29, 137)], pink, 5)
            b.o((61, 106, 114, 61), 0xB7A5A9)
            b.o((119, 133, 46, 30), cream, false)
            b.o((131, 64, 37, 46), gray)
            b.o((139, 72, 22, 29), pink, false)
            b.o((170, 75, 30, 35), 0xB7A5A9)
            b.p([(133, 105), (161, 91), (181, 99), (213, 128), (188, 142), (160, 143)], 0xB7A5A9)
            b.eye(174, 110, 10)
            b.spot(207, 124, 11, pink)
            b.whiskers(201, 135, spread: 22)
            b.o((115 + b.motion, 160, 28, 13), pink)
        case 23: // プレーリードッグ — upright on its hindquarters, stubby black tip
            b.tail([(100, 171), (71, 173), (48, 161), (41, 154)], tan, 12)
            b.l([(42, 154), (49, 161)], darkBrown, 11)
            b.o((86, 83, 72, 105), tan)
            b.o((118, 111, 39, 64), cream, false)
            b.o((101, 53, 24, 22), brown)
            b.p([(100, 88), (109, 69), (137, 64), (159, 75), (177, 96), (164, 114), (126, 112)], tan)
            b.o((150, 90, 30, 18), cream, false)
            b.eye(141, 81)
            b.spot(169, 92, 11)
            b.l([(119, 119), (132, 132), (150, 124)], brown, 7)
            b.l([(117, 132), (131, 140), (146, 127)], tan, 6)
            b.o((96 + b.motion, 177, 41, 16), brown)
        case 24: // ミーアキャット — slim sentry with black eye patches and back bands
            b.tail([(110, 175), (82, 185), (56, 186), (35, 174)], tan, 8)
            b.l([(34, 174), (43, 180)], darkBrown, 7)
            b.p([(93, 167), (97, 133), (112, 103), (127, 77), (154, 84), (151, 110),
                 (143, 148), (150, 183), (118, 197), (97, 183)], gold)
            for y: CGFloat in [128, 139, 151, 162] { b.l([(101, y), (117, y + 5)], brown, 5) }
            b.o((119, 51, 22, 26), brown)
            b.p([(120, 74), (137, 58), (160, 60), (173, 72), (190, 85), (173, 99), (141, 99)], gold)
            b.o((149, 68, 24, 20), darkBrown, false)
            b.eye(156, 73, 8)
            b.spot(182, 82, 10)
            b.l([(133, 112), (144, 126), (157, 121)], brown, 6)
            b.o((107 + b.motion, 185, 40, 14), brown)
        default: break
        }
    }

    private static func woodland(_ id: Int, _ b: Brush) {
        switch id {
        case 25: // アルマジロ — arch and armour bands over a pointed face
            b.p([(82, 144), (58, 150), (39, 161), (18, 161), (40, 146), (71, 131)], gray)
            b.step(78, 156, 24, brown, back: true, thickness: 8)
            b.step(147, 152, 28, tan, thickness: 8)
            b.p([(42, 146), (49, 104), (67, 78), (94, 63), (119, 66), (147, 75),
                 (172, 100), (178, 143), (148, 165), (79, 165)], gray)
            for (x, y): Point in [(76, 77), (91, 68), (110, 66), (129, 71), (148, 83)] {
                b.l([(x, y), (x - 9, y + 29), (x - 9, y + 53), (x, 157)], slate, 5)
            }
            b.p([(153, 112), (172, 95), (177, 70), (190, 95), (195, 117), (220, 141),
                 (202, 153), (173, 153)], tan)
            b.eye(185, 117)
            b.spot(210, 138, 10)
        case 26: // ウォンバット — square rear, flat nose, short feet
            b.step(66, 156, 29, brown, back: true, thickness: 14)
            b.step(160, 152, 31, tan, thickness: 16)
            b.p([(39, 144), (41, 104), (60, 86), (101, 89), (132, 96), (166, 108),
                 (184, 136), (174, 158), (142, 171), (71, 174), (46, 162)], brown)
            b.o((141, 78, 22, 30), tan)
            b.o((177, 79, 23, 35), brown)
            b.p([(142, 109), (159, 93), (183, 93), (202, 108), (211, 139), (185, 156),
                 (160, 149), (143, 132)], tan)
            b.o((172, 117, 37, 25), darkBrown)
            b.eye(159, 106, 8)
            b.eye(187, 104, 8)
            b.smile(179, 146, 17)
            b.l([(59, 105), (69, 105), (79, 100)], tan, 3)
        case 27: // クオッカ — smiling seated face, short ears and tiny bent arms
            b.tail([(90, 167), (64, 182), (44, 173)], brown, 12)
            b.o((71, 92, 99, 97), 0xAC7760)
            b.o((104, 122, 67, 61), tan, false)
            b.o((89, 56, 31, 37), brown)
            b.o((148, 53, 30, 35), brown)
            b.o((98, 68, 78, 72), 0xB88A6E)
            b.o((126, 101, 48, 34), cream, false)
            b.eye(114, 89, 10)
            b.eye(148, 86, 11)
            b.spot(144, 103, 10, darkBrown)
            b.smile(128, 118, 32)
            b.l([(113, 142), (128, 154), (143, 147)], brown, 8)
            b.o((88 + b.motion, 179, 39, 15), brown)
            b.o((142 - b.motion, 173, 39, 17), tan)
        case 28: // コアラ — fluffy wide ears, spoon nose and a eucalypt sprig
            b.tail([(163, 210), (151, 161), (147, 115), (140, 65), (146, 30)], brown, 13)
            b.p([(144, 55), (151, 35), (175, 24), (171, 45), (151, 59)], green)
            b.p([(145, 63), (127, 60), (108, 38), (130, 39)], green)
            b.o((68, 104, 89, 78), slate)
            b.o((104, 116, 40, 51), white, false)
            b.tail([(106, 141), (130, 149), (148, 137)], gray, 17)
            b.o((54, 55, 50, 54), slate)
            b.o((129, 45, 51, 59), slate)
            b.o((64, 64, 29, 36), white, false)
            b.o((140, 57, 28, 36), white, false)
            b.o((77, 65, 83, 73), gray)
            b.o((107, 93, 27, 39), black)
            b.eye(90, 88)
            b.eye(135, 86)
            b.smile(104, 130, 28)
            b.o((124, 161, 37, 27), slate)
        case 29: // カピバラ — sloping back, very blunt squared muzzle and tiny ears
            b.step(72, 146, 35, darkBrown, back: true, thickness: 12)
            b.step(157, 149, 33, brown, thickness: 13)
            b.p([(40, 139), (46, 106), (73, 91), (120, 92), (143, 84), (170, 94),
                 (192, 117), (192, 147), (174, 164), (123, 171), (74, 166), (49, 157)], tan)
            b.o((145, 70, 20, 28), brown)
            b.p([(157, 101), (173, 87), (196, 88), (207, 105), (216, 119),
                 (216, 141), (188, 145), (160, 136)], tan)
            b.p([(193, 120), (217, 118), (215, 142), (189, 146)], brown, false)
            b.eye(187, 103, 8)
            b.spot(207, 120, 8)
            b.l([(59, 115), (71, 107), (89, 106), (102, 102)], brown, 4.5)
            b.l([(191, 139), (203, 137), (211, 134)], darkBrown, 2.6)
        case 30: // ナマケモノ — hooks on its feet, hanging under a branch
            b.tail([(26, 66), (69, 56), (118, 57), (168, 51), (214, 58)], brown, 16)
            b.p([(179, 55), (191, 35), (214, 33), (206, 49)], green)
            b.o((67, 99, 104, 77), 0x9A8077)
            b.tail([(85, 123), (54, 99), (57, 68)], tan, 17)
            b.tail([(135, 117), (175, 98), (171, 62)], 0x9A8077, 18)
            for x: CGFloat in [51, 57, 63, 165, 171, 177] { b.l([(x, 73), (x + 2, 61), (x + 6, 58)], cream, 2.8) }
            b.o((105, 125, 74, 60), 0x9A8077)
            b.o((114, 134, 60, 44), cream, false)
            b.o((119, 143, 19, 13), brown, false)
            b.o((151, 138, 17, 14), brown, false)
            b.eye(122, 144, 8)
            b.eye(155, 140, 8)
            b.spot(145, 153, 8)
            b.smile(135, 163, 24)
        case 31: // アライグマ — wide black glasses and a clearly ringed curled tail
            let stripes: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(49, 85, 15, 18), (43, 104, 17, 16), (45, 122, 18, 15), (55, 137, 21, 12)]
            b.tail([(98, 153), (70, 146), (52, 129), (49, 109), (55, 82)], gray, 22)
            for stripe in stripes { b.l([(stripe.0, stripe.1 + 2), (stripe.0 + stripe.2 - 6, stripe.1 + 8)], black, stripe.3 * 0.52) }
            b.step(90, 154, 31, slate, back: true)
            b.step(157, 153, 30, slate)
            b.o((65, 97, 113, 74), gray)
            b.p([(127, 110), (124, 67), (150, 86), (174, 67), (189, 107), (205, 127),
                 (178, 152), (143, 144)], gray)
            b.p([(129, 108), (148, 98), (166, 108), (184, 97), (196, 115),
                 (182, 129), (161, 121), (143, 129)], black, false)
            b.eye(143, 106, 8)
            b.eye(178, 105, 9)
            b.p([(151, 126), (165, 118), (185, 125), (201, 130), (184, 146), (164, 146)], white, false)
            b.spot(185, 126, 10)
        case 32: // アナグマ — shovel claws, white head and long black stripes
            b.tail([(49, 147), (28, 151), (20, 144)], gray, 9)
            b.step(61, 154, 28, black, back: true, thickness: 13)
            b.step(145, 152, 34, black, thickness: 15)
            b.p([(37, 133), (54, 105), (90, 94), (121, 95), (160, 115),
                 (167, 147), (134, 170), (75, 171), (46, 157)], 0x778287)
            b.p([(139, 114), (155, 91), (178, 92), (199, 109), (222, 142), (193, 154),
                 (165, 142)], white)
            b.o((149, 86, 19, 21), white)
            b.l([(153, 99), (176, 113), (197, 136)], black, 11)
            b.l([(178, 95), (188, 106), (207, 124)], black, 7)
            b.eye(175, 113, 8)
            b.spot(213, 138, 12)
            for x: CGFloat in [148, 155, 162] { b.l([(x, 183), (x + 3, 188)], cream, 2.6) }
        case 33: // スカンク — high white split stripe through a raised flag tail
            b.p([(90, 157), (62, 146), (39, 114), (37, 77), (50, 42), (75, 34),
                 (102, 53), (107, 85), (90, 113), (94, 132), (107, 144)], 0x4C404D)
            b.p([(57, 46), (69, 37), (81, 42), (78, 67), (68, 95), (74, 122),
                 (88, 143), (74, 136), (62, 117), (54, 95), (56, 71)], white, false)
            b.step(78, 154, 31, black, back: true)
            b.step(149, 158, 27, black)
            b.o((60, 109, 115, 65), 0x4C404D)
            b.p([(68, 118), (93, 112), (124, 108), (156, 119), (147, 131),
                 (116, 126), (89, 134)], white, false)
            b.o((151, 108, 54, 53), 0x4C404D)
            b.o((149, 100, 21, 21), 0x4C404D)
            b.p([(175, 115), (181, 129), (192, 139), (189, 147), (179, 139), (171, 126)], white, false)
            b.eye(182, 124)
            b.spot(198, 140, 10)
        case 34: // マングース — long tapered level body, thin head and bristly saddle
            b.p([(82, 134), (54, 126), (29, 122), (11, 129), (25, 139), (56, 149), (86, 151)], tan)
            b.step(73, 152, 25, tan, back: true, thickness: 8)
            b.step(147, 152, 29, tan, thickness: 9)
            b.p([(48, 139), (65, 116), (92, 108), (124, 113), (151, 109), (176, 114),
                 (176, 144), (152, 160), (114, 165), (74, 158)], tan)
            for (x, y): Point in [(74, 119), (91, 116), (112, 120), (127, 119)] {
                b.l([(x - 4, y + 9), (x, y), (x + 5, y + 5)], brown, 2.7)
            }
            b.p([(146, 124), (153, 107), (168, 103), (181, 110), (217, 123),
                 (198, 137), (174, 142)], tan)
            b.o((153, 97, 19, 21), brown)
            b.eye(174, 111, 9)
            b.spot(209, 119, 9)
        case 35: // ハクビシン — narrow white stripe and almost black feet and nose
            b.tail([(66, 125), (42, 130), (23, 149), (13, 169)], 0x8F8182, 13)
            b.step(68, 143, 40, black, back: true)
            b.step(154, 141, 42, black)
            b.p([(42, 131), (63, 109), (95, 96), (122, 104), (149, 111), (170, 130),
                 (156, 154), (118, 165), (70, 158), (53, 149)], gray)
            b.p([(145, 118), (158, 91), (178, 93), (195, 107), (217, 125),
                 (200, 143), (172, 142)], 0x5B5669)
            b.o((148, 79, 20, 26), slate)
            b.o((176, 79, 22, 24), slate)
            b.p([(170, 95), (180, 96), (186, 108), (203, 120), (215, 126),
                 (205, 132), (192, 122), (176, 114)], white, false)
            b.eye(181, 114, 8)
            b.spot(208, 122, 12)
        case 36: // レッサーパンダ — rust brush, white eyebrows and black belly
            b.tail([(93, 153), (70, 148), (46, 129), (28, 102), (31, 79)], orange, 30)
            for (x, y): Point in [(33, 83), (36, 105), (50, 124), (70, 141)] {
                b.l([(x - 8, y + 5), (x + 11, y - 3)], brown, 7.6)
            }
            b.o((58, 105, 118, 69), 0xA75343)
            b.p([(78, 139), (115, 141), (149, 127), (170, 132), (158, 164), (115, 172), (85, 166)], darkBrown)
            b.step(82, 158, 30, darkBrown, back: true)
            b.step(151, 153, 34, darkBrown)
            b.p([(128, 100), (123, 66), (148, 77), (174, 64), (195, 94), (204, 122),
                 (176, 147), (147, 138)], orange)
            b.p([(126, 73), (142, 79), (132, 93)], cream, false)
            b.p([(180, 69), (191, 86), (171, 83)], cream, false)
            b.o((139, 99, 24, 17), cream, false)
            b.o((172, 93, 24, 16), cream, false)
            b.eye(149, 103)
            b.eye(179, 100)
            b.o((158, 116, 41, 24), cream, false)
            b.spot(181, 115, 10)
        case 37: // ジャイアントパンダ — black limbs, thumb clasp and bamboo leaves
            b.o((61, 80, 107, 108), white)
            b.o((65, 111, 47, 53), black)
            b.o((63, 167, 50, 25), black)
            b.o((129, 160, 46, 28), black)
            b.o((89, 53, 32, 34), black)
            b.o((145, 49, 30, 31), black)
            b.o((91, 65, 88, 75), white)
            b.o((101, 84, 24, 30), black, false)
            b.o((144, 82, 25, 29), black, false)
            b.eye(111, 93, 8)
            b.eye(154, 91, 8)
            if !b.asleep {
                b.o((111, 93, 4, 5), white, false)
                b.o((154, 91, 4, 5), white, false)
            }
            b.spot(128, 109, 14)
            b.smile(122, 121, 25)
            b.tail([(146, 176), (168, 133), (183, 91)], green, 6)
            b.p([(178, 106), (190, 87), (214, 82), (198, 102)], green)
            b.p([(171, 120), (155, 112), (149, 92), (170, 103)], green)
            b.o((124, 133, 40, 30), black)
        case 38: // ビーバー — broad crosshatched paddle and two large front teeth
            b.p([(78, 143), (48, 144), (24, 157), (15, 179), (38, 188), (66, 171), (95, 152)], darkBrown)
            for x: CGFloat in [29, 42, 55] {
                b.l([(x, 175), (x + 8, 153)], tan, 2.7)
                b.l([(x, 162), (x + 12, 171)], tan, 2.7)
            }
            b.o((55, 93, 125, 91), brown)
            b.o((100, 123, 65, 58), tan, false)
            b.o((130, 62, 31, 32), darkBrown)
            b.o((128, 74, 73, 75), brown)
            b.o((152, 110, 62, 36), tan)
            b.eye(167, 93, 11)
            b.o((195, 109, 18, 13), black)
            b.p([(176, 136), (196, 134), (195, 155), (178, 157)], white)
            b.l([(187, 135), (186, 155)], darkBrown, 2.5)
            b.o((100 + b.motion, 173, 40, 14), darkBrown)
        case 39: // ラッコ — floating on its back with a scallop on the pale bib
            b.p([(61, 138), (24, 124), (33, 149), (23, 162), (59, 170), (78, 157)], darkBrown)
            b.p([(56, 138), (43, 115), (58, 107), (80, 132)], brown)
            b.o((45, 123, 119, 54), brown)
            b.o((67, 122, 86, 39), tan, false)
            b.o((133, 92, 27, 32), darkBrown)
            b.o((171, 75, 29, 34), darkBrown)
            b.o((135, 83, 70, 67), tan)
            b.o((149, 111, 52, 35), cream, false)
            b.eye(153, 102, 10)
            b.eye(179, 95, 9)
            b.spot(180, 112, 11)
            b.whiskers(186, 122, spread: 30)
            b.p([(110, 117), (117, 102), (130, 103), (141, 115), (128, 129), (114, 128)], pink)
            b.l([(121, 124), (120, 109), (128, 123), (133, 112)], red, 2.3)
            b.l([(86, 143), (99, 132), (113, 125)], darkBrown, 8)
        default: break
        }
    }

    private static func sideMammal(
        _ b: Brush, _ body: [Point], _ head: [Point], _ legs: [(CGFloat, CGFloat, CGFloat)],
        coat: Color, underside: Color? = nil, legColor: Color? = nil, legWidth: CGFloat = 10,
        tail: [Point] = [], tailWidth: CGFloat = 12, eye: Point, nose: Point,
        hoof: Bool = false, detail: (Brush) -> Void = { _ in }
    ) {
        if tail.count > 1 { b.tail(tail, coat, tailWidth) }
        for (index, leg) in legs.enumerated() {
            b.step(leg.0, leg.1, leg.2, legColor ?? coat, back: index.isMultiple(of: 2),
                   hoof: hoof, thickness: legWidth)
        }
        b.p(body, coat)
        if let underside {
            let xs = body.map(\.0)
            let ys = body.map(\.1)
            let left = xs.min() ?? 40
            let top = ys.min() ?? 100
            let width = (xs.max() ?? 170) - left
            let height = (ys.max() ?? 170) - top
            b.o((left + width * 0.27, top + height * 0.58, width * 0.54, height * 0.29), underside, false)
        }
        b.p(head, coat)
        detail(b)
        b.eye(eye.0, eye.1)
        b.spot(nose.0, nose.1, 10)
    }

    private static func carnivores(_ id: Int, _ b: Brush) {
        switch id {
        case 40: // マヌルネコ — flat set ears and long grizzled cheeks
            sideMammal(b, [(43, 134), (56, 111), (77, 101), (115, 94), (148, 108), (163, 137),
                           (149, 163), (98, 176), (57, 166)],
                       [(136, 113), (135, 92), (152, 90), (159, 103), (184, 101), (201, 91), (208, 103),
                        (204, 116), (217, 137), (203, 153), (181, 161), (149, 151)],
                       [(73, 157, 26), (143, 158, 27)], coat: 0xA7A2A0, legColor: slate, legWidth: 13,
                       tail: [(55, 148), (37, 157), (21, 151)], tailWidth: 18, eye: (173, 115), nose: (202, 135)) { b in
                b.p([(142, 119), (160, 123), (167, 139), (158, 151), (142, 145)], white, false)
                b.l([(151, 115), (162, 122), (173, 123)], slate, 4)
                b.l([(146, 126), (154, 135), (169, 138)], slate, 4)
                b.l([(189, 114), (198, 121), (208, 121)], slate, 3.5)
            }
        case 41: // オオヤマネコ — tall legs, pointed ear tufts, bobbed black tail
            sideMammal(b, [(57, 123), (74, 98), (114, 95), (153, 88), (176, 104), (161, 132),
                           (131, 153), (93, 148), (64, 144)],
                       [(151, 110), (145, 76), (145, 49), (163, 77), (185, 76), (193, 46),
                        (198, 86), (216, 107), (201, 128), (176, 126)],
                       [(70, 135, 57), (89, 138, 48), (145, 131, 59), (163, 126, 53)],
                       coat: tan, underside: cream, legColor: brown, legWidth: 9, tail: [(65, 120), (45, 110), (40, 102)],
                       tailWidth: 13, eye: (181, 94), nose: (207, 106)) { b in
                b.l([(146, 56), (143, 40)], black, 4)
                b.l([(194, 55), (196, 37)], black, 4)
                b.l([(43, 104), (48, 110)], black, 10)
                for (x, y): Point in [(79, 114), (100, 109), (118, 123), (84, 132), (133, 111)] { b.spot(x, y, 7, brown) }
                b.p([(175, 110), (195, 115), (203, 123), (184, 126)], cream, false)
            }
        case 42: // サーバル — bat-like high ears and a lean African cat's shoulders
            sideMammal(b, [(53, 124), (77, 104), (110, 111), (135, 97), (156, 90), (177, 103),
                           (169, 129), (150, 148), (125, 146), (105, 137), (69, 147)],
                       [(156, 107), (152, 82), (150, 51), (157, 36), (169, 47), (174, 77),
                        (190, 75), (190, 37), (204, 36), (210, 51), (202, 81), (215, 101), (197, 122), (176, 121)],
                       [(65, 139, 52), (86, 140, 44), (154, 130, 67), (169, 127, 62)],
                       coat: gold, underside: cream, legWidth: 6,
                       tail: [(61, 128), (43, 139), (22, 145)], tailWidth: 11,
                       eye: (183, 92), nose: (208, 100)) { b in
                b.l([(159, 48), (164, 72)], peach, 8)
                b.l([(200, 46), (199, 70)], peach, 8)
                for (x, y): Point in [(70, 118), (92, 116), (101, 128), (123, 113), (139, 101), (151, 115), (132, 133)] { b.spot(x, y, 7) }
                b.l([(24, 145), (31, 143)], black, 8)
            }
        case 43: // チーター — sprint silhouette, solid spots and tear lines
            sideMammal(b, [(49, 115), (78, 93), (106, 92), (133, 99), (160, 94), (176, 108),
                           (166, 128), (148, 140), (115, 128), (94, 133), (62, 143)],
                       [(154, 110), (156, 83), (168, 68), (181, 68), (185, 75), (200, 71),
                        (207, 83), (213, 97), (201, 112), (181, 119)],
                       [(55, 136, 48), (82, 132, 43), (147, 128, 51), (171, 122, 63)], coat: 0xE6B361,
                       underside: cream, legWidth: 7, tail: [(57, 121), (36, 105), (22, 83), (26, 70)],
                       tailWidth: 10, eye: (187, 87), nose: (206, 96)) { b in
                for (x, y): Point in [(64, 118), (79, 107), (89, 119), (104, 105), (115, 118), (128, 110),
                                       (146, 107), (150, 121), (76, 130), (169, 90)] { b.spot(x, y, 5) }
                b.l([(192, 96), (193, 105), (201, 108)], black, 3.6)
                b.l([(25, 72), (24, 77)], black, 9)
            }
        case 44: // ヒョウ — olive-gold climber with open rosettes and hooked tail
            sideMammal(b, [(52, 128), (65, 102), (94, 92), (139, 93), (159, 102), (175, 121),
                           (158, 145), (125, 154), (86, 147), (57, 144)],
                       [(146, 118), (153, 93), (154, 71), (167, 69), (176, 88), (191, 84),
                        (205, 97), (222, 111), (208, 133), (184, 143), (155, 135)],
                       [(65, 139, 43), (86, 140, 36), (145, 137, 49), (161, 133, 42)],
                       coat: 0xC89642, underside: cream, legWidth: 11,
                       tail: [(55, 129), (35, 135), (16, 120), (18, 98), (32, 93)],
                       tailWidth: 13, eye: (184, 105), nose: (213, 110)) { b in
                rosettes(b, [(73, 118), (91, 105), (112, 114), (131, 104), (147, 124), (105, 134), (127, 134)], size: 11, centers: false)
            }
        case 45: // ジャガー — thick shoulders, square jaw and dots inside rosettes
            sideMammal(b, [(46, 137), (61, 104), (93, 89), (128, 92), (154, 85), (181, 104),
                           (184, 137), (161, 155), (110, 163), (71, 158), (48, 151)],
                       [(151, 120), (153, 89), (155, 66), (171, 67), (178, 81), (190, 79),
                        (206, 90), (220, 103), (222, 128), (202, 147), (175, 145)],
                       [(63, 148, 38), (87, 150, 31), (149, 148, 40), (168, 141, 39)],
                       coat: 0xCF9252, underside: cream, legWidth: 15,
                       tail: [(52, 135), (34, 148), (16, 145)], tailWidth: 16, eye: (185, 100), nose: (210, 115)) { b in
                rosettes(b, [(68, 117), (88, 107), (112, 115), (134, 107), (151, 125), (95, 136), (119, 141)], size: 13, centers: true)
                b.o((187, 123, 29, 18), cream, false)
                b.smile(195, 132, 17)
            }
        case 46: // ユキヒョウ — high snowy back, ringed blanket of a tail and grey rosettes
            sideMammal(b, [(59, 134), (63, 109), (91, 88), (123, 91), (152, 106), (170, 133),
                           (154, 155), (109, 172), (77, 164), (61, 153)],
                       [(140, 121), (149, 91), (155, 75), (170, 79), (179, 88), (195, 82),
                        (209, 102), (219, 127), (205, 143), (174, 150), (153, 141)],
                       [(72, 148, 37), (102, 154, 34), (151, 145, 43), (170, 141, 36)],
                       coat: 0xC1C8CA, underside: white, legColor: gray, legWidth: 13,
                       tail: [(66, 146), (40, 148), (21, 137), (20, 110), (38, 92)],
                       tailWidth: 20, eye: (183, 107), nose: (211, 124)) { b in
                rosettes(b, [(76, 117), (97, 102), (117, 119), (137, 114), (148, 135), (103, 139)], size: 13, centers: false, color: slate)
                b.l([(33, 99), (40, 104)], slate, 8)
                b.l([(17, 119), (27, 119)], slate, 8)
                b.l([(31, 141), (38, 135)], slate, 8)
            }
        case 47: // トラ — bold tapered stripes and white eye, cheek and chest
            sideMammal(b, [(50, 128), (70, 97), (103, 86), (142, 91), (162, 92), (185, 117),
                           (176, 151), (147, 165), (91, 164), (61, 151)],
                       [(151, 118), (151, 86), (149, 64), (165, 60), (173, 77), (190, 74),
                        (200, 60), (214, 76), (212, 92), (225, 117), (209, 141), (180, 151), (156, 140)],
                       [(68, 144, 48), (91, 148, 36), (151, 146, 45), (172, 137, 54)],
                       coat: orange, underside: cream, legWidth: 14,
                       tail: [(54, 126), (33, 114), (20, 89), (27, 70)], tailWidth: 14,
                       eye: (195, 100), nose: (214, 119)) { b in
                for (x, y): Point in [(70, 99), (88, 91), (107, 88), (127, 91), (143, 92), (163, 95)] {
                    b.p([(x - 3, y + 3), (x + 5, y + 2), (x + 9, y + 21), (x + 5, y + 35), (x + 2, y + 21)], black, false)
                }
                b.p([(178, 114), (194, 116), (217, 120), (210, 140), (186, 148), (173, 136)], white, false)
                b.l([(178, 88), (182, 102), (192, 91), (198, 97), (205, 86)], black, 3.2)
                b.whiskers(213, 132, spread: 15)
            }
        case 48: // ライオン — rosette mane, paw span and tufted tail
            b.tail([(68, 139), (42, 130), (25, 102), (35, 82)], gold, 9)
            b.p([(31, 89), (24, 75), (32, 62), (42, 71), (44, 81)], darkBrown)
            b.step(70, 143, 51, gold, back: true, thickness: 13)
            b.step(111, 145, 43, tan, thickness: 13)
            b.step(167, 143, 50, gold, back: true, thickness: 15)
            b.o((53, 101, 132, 67), gold)
            b.p([(118, 124), (115, 103), (124, 87), (120, 72), (143, 72), (144, 53),
                 (164, 59), (180, 48), (195, 62), (217, 65), (214, 85), (228, 101),
                 (222, 122), (214, 141), (196, 153), (182, 173), (164, 164), (142, 162),
                 (139, 144), (125, 146)], brown)
            b.o((155, 77, 68, 68), gold)
            b.o((178, 110, 45, 30), cream, false)
            b.eye(181, 98, 11)
            b.eye(202, 94, 9)
            b.spot(204, 109, 13)
            b.smile(190, 127, 27)
        case 49: // オオカミ — raised shoulders, grey saddle, long brush and wedge nose
            sideMammal(b, [(49, 134), (60, 105), (81, 94), (110, 96), (142, 85), (164, 83),
                           (180, 111), (160, 145), (116, 151), (79, 146)],
                       [(149, 112), (151, 85), (147, 59), (166, 72), (182, 59), (191, 86),
                        (205, 96), (227, 111), (203, 128), (175, 135)],
                       [(64, 138, 42), (88, 141, 37), (145, 136, 51), (169, 127, 52)], coat: gray,
                       underside: white, legColor: slate, legWidth: 11,
                       tail: [(54, 133), (35, 147), (15, 151)], tailWidth: 21, eye: (185, 94), nose: (216, 105)) { b in
                b.p([(68, 104), (99, 98), (119, 99), (144, 89), (164, 86), (151, 111), (118, 118), (90, 112)], slate, false)
                b.p([(164, 114), (190, 110), (220, 112), (201, 125), (176, 132)], white, false)
            }
        case 50: // コヨーテ — pointed tall ears, wiry tan body and drooping black tail tip
            sideMammal(b, [(54, 125), (79, 101), (112, 107), (145, 93), (166, 100),
                           (175, 117), (153, 140), (124, 145), (91, 140), (62, 148)],
                       [(149, 107), (143, 75), (147, 48), (163, 73), (178, 61), (181, 43),
                        (193, 78), (203, 94), (222, 109), (204, 123), (170, 126)],
                       [(62, 140, 47), (82, 139, 39), (140, 135, 50), (160, 132, 52)],
                       coat: tan, underside: cream, legColor: brown, legWidth: 7,
                       tail: [(60, 128), (38, 139), (25, 164), (18, 171)], tailWidth: 14,
                       eye: (182, 92), nose: (213, 107)) { b in
                b.l([(19, 170), (25, 163)], black, 12)
                b.p([(72, 113), (89, 106), (108, 111), (133, 103), (143, 105), (122, 122), (88, 122)], brown, false)
                b.p([(156, 58), (159, 74), (152, 76)], peach, false)
            }
        case 51: // リカオン — round satellite ears, three-colour patches and white tail tip
            sideMammal(b, [(44, 131), (64, 107), (92, 101), (130, 106), (157, 97), (175, 121),
                           (165, 147), (125, 153), (88, 149), (58, 153)],
                       [(144, 114), (144, 84), (141, 72), (146, 51), (161, 49), (174, 65),
                        (172, 79), (184, 76), (191, 49), (211, 51), (218, 67), (208, 88),
                        (214, 110), (227, 126), (199, 140), (168, 134)],
                       [(56, 143, 46), (77, 142, 39), (148, 140, 51), (169, 134, 49)],
                       coat: tan, legColor: darkBrown, legWidth: 9, tail: [(50, 132), (31, 120), (17, 102)],
                       tailWidth: 12, eye: (188, 104), nose: (217, 123)) { b in
                b.p([(56, 128), (76, 107), (92, 109), (93, 127), (80, 149), (58, 149)], black, false)
                b.p([(94, 133), (110, 111), (128, 114), (141, 135), (128, 148), (102, 148)], white, false)
                b.p([(148, 107), (163, 108), (173, 121), (164, 145), (144, 139)], black, false)
                b.l([(17, 102), (24, 110)], white, 8)
                b.o((194, 119, 25, 15), darkBrown, false)
            }
        case 52: // ハイエナ — a steep hunched mane and short rear legs
            sideMammal(b, [(44, 141), (59, 116), (90, 108), (118, 94), (134, 80), (152, 74),
                           (178, 100), (176, 131), (152, 156), (110, 159), (74, 153)],
                       [(145, 111), (146, 80), (149, 65), (164, 66), (175, 85), (191, 77),
                        (207, 97), (216, 114), (216, 134), (198, 143), (174, 134)],
                       [(62, 145, 29), (82, 143, 27), (145, 140, 47), (166, 137, 54)],
                       coat: 0xC39F65, legColor: darkBrown, legWidth: 11, tail: [(49, 135), (28, 143), (16, 140)],
                       tailWidth: 13, eye: (184, 97), nose: (208, 115)) { b in
                b.p([(97, 110), (108, 91), (121, 91), (127, 74), (136, 80), (148, 65),
                     (158, 76), (152, 92), (134, 102), (113, 111)], brown, false)
                for (x, y): Point in [(69, 126), (89, 119), (103, 135), (119, 114), (137, 120), (123, 141), (82, 141)] { b.spot(x, y, 7, darkBrown) }
                b.o((192, 122, 24, 14), darkBrown, false)
            }
        case 53: // ディンゴ — sandy lean profile, pale socks and single curved tail
            sideMammal(b, [(48, 124), (73, 97), (110, 99), (145, 93), (169, 106), (172, 129),
                           (145, 147), (103, 154), (72, 145), (53, 143)],
                       [(141, 109), (143, 81), (143, 54), (163, 74), (180, 55), (191, 84),
                        (215, 101), (220, 114), (202, 127), (174, 130)],
                       [(63, 137, 51), (85, 140, 42), (144, 136, 53), (163, 130, 55)], coat: 0xD8934B,
                       underside: cream, legWidth: 8, tail: [(54, 122), (37, 102), (21, 75), (29, 54)],
                       tailWidth: 15, eye: (181, 90), nose: (211, 108)) { b in
                b.l([(30, 54), (27, 62)], cream, 10)
                b.p([(160, 109), (186, 105), (216, 114), (198, 127), (176, 129)], cream, false)
                b.l([(61, 179), (68, 185)], cream, 7)
                b.l([(142, 181), (151, 186)], cream, 7)
            }
        case 54: // マレーグマ — glossy small bear, orange U and a poking tongue
            b.o((64, 93, 104, 77), 0x504052)
            b.step(75, 151, 36, black, back: true, thickness: 16)
            b.step(143, 142, 47, black, thickness: 16)
            b.o((120, 81, 75, 69), 0x504052)
            b.o((128, 72, 21, 22), black)
            b.o((166, 71, 21, 22), black)
            b.o((152, 110, 52, 30), tan)
            b.eye(150, 101, 10)
            b.spot(191, 114, 11)
            b.l([(175, 134), (185, 145), (198, 143), (205, 132)], pink, 4.2)
            b.l([(117, 125), (120, 141), (132, 152), (147, 139), (150, 128)], orange, 9)
        case 55: // ツキノワグマ — thick dark coat, upright head and white crescent
            b.o((55, 91, 102, 97), black)
            b.o((93, 112, 67, 72), 0x4C4555)
            b.o((82, 54, 32, 32), black)
            b.o((135, 52, 35, 32), black)
            b.o((91, 66, 71, 75), black)
            b.p([(103, 130), (124, 146), (144, 126), (144, 139), (124, 156), (104, 142)], white, false)
            b.o((111, 104, 45, 22), slate, false)
            b.eye(106, 94)
            b.eye(138, 92)
            b.spot(133, 108, 11)
            b.o((70 + b.motion, 170, 51, 25), 0x4C4555)
            b.o((132 - b.motion, 170, 40, 23), black)
        case 56: // ヒグマ — shoulder hump, dish-shaped face and long claws
            sideMammal(b, [(34, 139), (48, 102), (75, 91), (104, 90), (131, 74), (156, 73),
                           (180, 101), (178, 144), (154, 164), (95, 168), (56, 160)],
                       [(145, 108), (143, 87), (146, 66), (165, 64), (175, 83), (190, 80),
                        (200, 91), (206, 105), (223, 116), (217, 133), (192, 144), (163, 134)],
                       [(57, 149, 38), (83, 150, 34), (148, 145, 45), (169, 138, 45)], coat: brown,
                       legColor: darkBrown, legWidth: 16, eye: (186, 102), nose: (213, 116)) { b in
                b.p([(121, 92), (139, 77), (155, 75), (167, 85), (154, 96), (139, 99)], tan, false)
                for x: CGFloat in [154, 161, 168] { b.l([(x, 188), (x + 4, 194)], cream, 2.5) }
                b.o((186, 119, 31, 20), tan, false)
            }
        case 57: // ホッキョクグマ — long ivory neck, black button nose and slab paws
            sideMammal(b, [(27, 139), (34, 110), (66, 89), (105, 88), (130, 96), (151, 91),
                           (181, 85), (195, 108), (176, 143), (149, 157), (83, 163), (48, 160)],
                       [(150, 115), (157, 83), (164, 69), (180, 71), (191, 87), (212, 93),
                        (228, 109), (222, 123), (196, 133), (172, 133)],
                       [(41, 149, 40), (71, 150, 33), (147, 146, 48), (170, 139, 47)], coat: white,
                       legColor: 0xE6DBCC, legWidth: 18, eye: (191, 97), nose: (218, 107)) { b in
                b.o((164, 73, 11, 14), gray, false)
                b.l([(164, 118), (176, 125), (195, 125)], 0xD5C1B5, 3)
            }
        default: break
        }
    }

    private static func rosettes(_ b: Brush, _ centersAt: [Point], size: CGFloat,
                                 centers: Bool, color: Color = darkBrown) {
        for (x, y) in centersAt {
            b.l([(x - size * 0.5, y + 2), (x - size * 0.3, y - size * 0.42),
                 (x + size * 0.2, y - size * 0.46), (x + size * 0.53, y - 1),
                 (x + size * 0.23, y + size * 0.34), (x - size * 0.25, y + size * 0.3)], color, 2.8)
            if centers { b.spot(x - 1.8, y - 1.3, 3.6, color) }
        }
    }

    private static func oddMammals(_ id: Int, _ b: Brush) {
        switch id {
        case 58: // キンカジュー — long grasping tail, round golden face and pink tongue
            b.tail([(88, 142), (54, 136), (31, 107), (35, 67), (60, 48), (79, 60), (69, 76)], tan, 15)
            b.o((70, 103, 106, 67), 0xBC8057)
            b.tail([(99, 146), (82, 169), (62, 167)], brown, 13)
            b.tail([(139, 141), (158, 161), (182, 152)], tan, 13)
            b.o((133, 73, 27, 26), brown)
            b.o((179, 72, 28, 27), brown)
            b.o((130, 86, 79, 68), tan)
            b.o((147, 109, 55, 37), gold, false)
            b.eye(146, 104, 14)
            b.eye(179, 102, 13)
            b.spot(174, 121, 13)
            b.l([(174, 140), (186, 152), (196, 151)], pink, 5)
        case 59: // オポッサム — pale pointed face, round naked ears and very long bare tail
            b.tail([(71, 135), (37, 142), (17, 160), (19, 176), (42, 180), (55, 172)], pink, 7)
            b.step(71, 156, 28, darkBrown, back: true, thickness: 9)
            b.step(156, 149, 37, slate, thickness: 8)
            b.p([(47, 137), (67, 112), (102, 103), (129, 103), (155, 115), (179, 135),
                 (158, 154), (109, 163), (75, 160)], gray)
            b.o((138, 75, 32, 38), black)
            b.o((147, 82, 16, 23), pink, false)
            b.o((171, 81, 25, 32), black)
            b.p([(138, 109), (165, 93), (188, 102), (221, 133), (202, 143), (169, 142)], cream)
            b.eye(181, 114, 8)
            b.spot(211, 129, 11, pink)
            b.whiskers(204, 141, spread: 23)
        case 60: // タスマニアデビル — bulky jaws, white bib and a dark tapered tail
            b.p([(63, 128), (39, 137), (16, 161), (38, 162), (70, 150)], black)
            b.step(71, 150, 36, 0x4B3D4B, back: true, thickness: 13)
            b.step(143, 155, 38, 0x4B3D4B, thickness: 13)
            b.p([(46, 141), (61, 112), (91, 100), (124, 101), (156, 112), (177, 132),
                 (162, 156), (122, 173), (85, 168), (55, 159)], 0x57475A)
            b.o((148, 80, 29, 29), 0x57475A)
            b.o((156, 86, 14, 15), red, false)
            b.p([(141, 123), (154, 100), (179, 94), (195, 100), (216, 117),
                 (212, 130), (184, 132), (208, 143), (185, 159), (163, 156)], 0x57475A)
            b.p([(180, 130), (210, 130), (206, 144), (187, 144)], red, false)
            b.p([(192, 129), (203, 130), (198, 137)], white, false)
            b.p([(141, 129), (153, 141), (170, 148), (160, 161), (146, 151), (133, 139)], white, false)
            b.eye(181, 110, 10)
            b.spot(207, 116, 9)
        case 61: // ワラビー — bent crouch, dark eye, pale cheeks and short slender forearms
            b.p([(103, 157), (71, 167), (38, 176), (19, 174), (46, 190), (81, 183), (119, 172)], brown)
            b.o((86, 101, 82, 82), 0xB58970)
            b.o((106, 139, 52, 52), brown)
            b.tail([(127, 174), (148 + b.motion, 191), (171 + b.motion, 189)], tan, 13)
            b.p([(135, 135), (139, 102), (139, 80), (157, 67), (171, 89), (162, 130)], cream)
            b.p([(136, 82), (117, 66), (112, 41), (121, 35), (137, 52), (145, 71),
                 (151, 48), (162, 37), (168, 52), (165, 79)], brown)
            b.p([(140, 77), (159, 67), (176, 74), (189, 93), (171, 111), (151, 102)], tan)
            b.eye(164, 85, 10)
            b.spot(182, 89, 10)
            b.o((170, 93, 16, 11), white, false)
            b.l([(156, 128), (172, 144), (185, 141)], brown, 6)
        case 62: // カンガルー — strong long tail, erect ears and enormous hind feet
            b.p([(119, 143), (91, 158), (57, 174), (18, 176), (34, 190), (70, 191),
                 (108, 177), (134, 157)], 0xC37A51)
            b.p([(98, 165), (104, 130), (133, 105), (152, 78), (172, 87),
                 (172, 113), (158, 145), (157, 170), (129, 191), (110, 188)], orange)
            b.o((109, 135, 51, 43), brown)
            b.tail([(131, 162), (151 + b.motion, 193), (186 + b.motion, 195)], orange, 15)
            b.o((145, 108, 28, 52), cream, false)
            b.tail([(165, 113), (181, 129), (195, 126)], orange, 8)
            b.p([(154, 81), (147, 54), (148, 19), (161, 27), (168, 58),
                 (172, 37), (186, 22), (187, 52), (179, 77)], orange)
            b.p([(152, 34), (157, 55), (164, 63), (161, 49)], pink, false)
            b.p([(158, 73), (177, 67), (194, 82), (204, 100), (185, 112), (164, 104)], orange)
            b.eye(181, 82, 9)
            b.spot(195, 97, 10)
        case 63: // ハナグマ — skyward ringtail and crooked probing snout
            b.tail([(61, 133), (45, 105), (40, 71), (42, 34)], tan, 15)
            for y: CGFloat in [42, 60, 80, 100, 119] { b.l([(36, y), (49, y - 3)], darkBrown, 7) }
            sideMammal(b, [(47, 138), (68, 110), (97, 105), (123, 110), (147, 113),
                           (165, 134), (146, 156), (107, 161), (70, 156)],
                       [(140, 131), (146, 108), (160, 95), (174, 101), (185, 111),
                        (203, 113), (221, 108), (224, 120), (204, 130), (178, 144), (159, 145)],
                       [(65, 151, 29), (138, 145, 37)], coat: tan, legColor: darkBrown, eye: (174, 111), nose: (214, 112)) { b in
                b.o((147, 89, 23, 24), tan)
                b.p([(163, 107), (180, 104), (198, 114), (181, 121), (169, 119)], cream, false)
            }
        case 64: // ツチブタ — twin donkey ears, cone-shaped muzzle and spade claws
            b.p([(65, 130), (42, 141), (19, 154), (40, 160), (83, 151)], gray)
            sideMammal(b, [(44, 130), (62, 108), (88, 96), (117, 91), (152, 98), (172, 123),
                           (166, 148), (143, 163), (108, 167), (66, 157)],
                       [(148, 120), (147, 85), (141, 55), (147, 28), (164, 38), (173, 70),
                        (174, 53), (191, 33), (199, 49), (190, 79), (182, 94), (212, 123),
                        (219, 149), (205, 162), (189, 155), (168, 141)],
                       [(72, 152, 29), (148, 145, 38)], coat: 0xAA8F8E, legColor: slate, legWidth: 13,
                       eye: (177, 108), nose: (208, 147)) { b in
                b.l([(151, 41), (161, 65), (165, 77)], pink, 8)
                b.l([(190, 47), (185, 73)], pink, 7)
                for x: CGFloat in [149, 156, 163] { b.l([(x, 180), (x + 4, 186)], cream, 3) }
            }
        case 65: // センザンコウ — long overlapping leaf scales all the way onto the tail
            b.p([(92, 135), (62, 133), (45, 146), (18, 155), (23, 172), (56, 177),
                 (88, 162), (114, 153)], tan)
            b.step(95, 152, 26, darkBrown, back: true, thickness: 8)
            b.step(153, 148, 32, brown, thickness: 8)
            b.p([(50, 132), (67, 102), (89, 84), (114, 80), (147, 90), (172, 108),
                 (184, 138), (167, 158), (133, 166), (94, 162), (63, 153)], 0xB1855F)
            for (row, count): (Int, Int) in [(0, 3), (1, 5), (2, 6), (3, 5)] {
                for column in 0..<count {
                    let x = CGFloat(57 + column * 16 + (row == 0 ? 38 : row == 1 ? 19 : 0))
                    let y = CGFloat(91 + row * 18)
                    b.l([(x - 5, y), (x + 5, y + 10), (x + 14, y + 13), (x + 11, y + 3)], darkBrown, 2.5)
                }
            }
            b.p([(158, 121), (176, 110), (191, 119), (218, 147), (207, 154), (180, 151)], tan)
            b.eye(184, 127, 8)
            b.spot(208, 143, 10)
            for x: CGFloat in [36, 50, 66] { b.l([(x - 5, 152), (x + 6, 160), (x + 12, 162)], darkBrown, 3) }
        case 66: // ハリモグラ — straw-coloured needles over a long, thin beak
            b.step(79, 152, 32, brown, back: true, thickness: 13)
            b.step(148, 158, 25, tan, thickness: 12)
            b.o((40, 88, 141, 78), darkBrown)
            for (x, y, tipX, tipY): (CGFloat, CGFloat, CGFloat, CGFloat) in [
                (49, 125, 28, 98), (56, 111, 40, 76), (69, 102, 56, 67), (83, 93, 78, 52),
                (98, 92, 99, 57), (116, 91, 125, 53), (134, 97, 150, 68), (147, 105, 166, 80),
                (161, 117, 185, 96), (67, 131, 51, 108), (89, 124, 83, 103), (109, 132, 108, 112),
                (130, 130, 141, 107), (148, 138, 168, 121)
            ] {
                b.p([(x - 5, y + 4), (tipX, tipY), (x + 7, y - 2)], gold, false)
                b.l([(x, y), (tipX, tipY)], cream, 2)
            }
            b.p([(151, 130), (168, 118), (183, 122), (199, 140), (227, 151),
                 (228, 162), (209, 162), (190, 152), (171, 154)], tan)
            b.eye(175, 129, 8)
            b.spot(220, 152, 8)
        case 67: // カモノハシ — rubbery flat bill, broad paddle tail and webbed toes
            b.p([(76, 130), (43, 113), (18, 119), (12, 137), (28, 154), (60, 154), (91, 144)], brown)
            b.l([(24, 130), (43, 136), (56, 140)], tan, 4.5)
            b.o((49, 100, 131, 72), 0x886C67)
            b.p([(74, 146), (56, 167), (57, 180), (69, 175), (76, 184), (86, 172), (105, 164), (105, 153)], orange)
            b.p([(154, 150), (147, 176), (156, 185), (166, 178), (178, 181), (182, 166), (175, 150)], orange)
            b.o((138, 87, 63, 62), brown)
            b.p([(179, 111), (205, 109), (227, 116), (232, 130), (213, 140),
                 (186, 138), (172, 128)], slate)
            b.l([(185, 123), (207, 127), (224, 125)], gray, 3)
            b.eye(170, 102, 10)
        case 68: // オオアリクイ — sweeping bristled tail, white-edged black shoulder stripe
            b.p([(80, 139), (49, 150), (28, 143), (17, 126), (10, 92), (21, 94), (16, 71),
                 (34, 86), (48, 87), (68, 110), (90, 126)], gray)
            b.l([(26, 88), (37, 108), (59, 125), (74, 132)], slate, 5)
            sideMammal(b, [(56, 142), (69, 109), (92, 91), (123, 91), (150, 108),
                           (164, 130), (151, 153), (118, 162), (74, 161)],
                       [(140, 119), (145, 96), (155, 91), (169, 103), (179, 116), (196, 133),
                        (224, 147), (228, 158), (208, 163), (183, 150), (159, 145)],
                       [(78, 152, 34), (146, 144, 41)], coat: gray, legColor: 0xDDD4C1, legWidth: 12,
                       eye: (167, 111), nose: (218, 150)) { b in
                b.p([(70, 140), (95, 121), (123, 112), (153, 115), (163, 130), (149, 150),
                     (124, 136), (96, 140)], white, false)
                b.p([(78, 140), (101, 126), (124, 117), (151, 121), (157, 131), (146, 143),
                     (125, 133), (103, 135)], black, false)
                b.l([(221, 163), (228, 172), (236, 169)], pink, 2.3)
            }
        case 69: // マレーバク — black front and rear around a wide white saddle
            sideMammal(b, [(38, 140), (46, 113), (63, 89), (94, 83), (126, 86), (155, 96),
                           (179, 119), (177, 144), (152, 164), (110, 170), (67, 164), (43, 156)],
                       [(148, 121), (147, 94), (146, 76), (155, 63), (167, 76), (169, 88),
                        (186, 87), (198, 99), (215, 113), (218, 136), (206, 150), (192, 138),
                        (176, 135), (161, 139)],
                       [(52, 153, 40), (83, 156, 31), (148, 156, 38), (172, 145, 46)],
                       coat: 0x514956, legColor: black, legWidth: 14,
                       tail: [(41, 144), (31, 148), (24, 145)], tailWidth: 7,
                       eye: (182, 109), nose: (209, 132), hoof: true) { b in
                b.p([(77, 90), (96, 85), (126, 87), (144, 94), (137, 114), (141, 136),
                     (138, 159), (110, 168), (82, 166), (77, 140), (82, 116)], white, false)
                b.l([(153, 70), (159, 76)], white, 4)
            }
        case 70: // イノシシ — ragged bristles, wedge skull and little lower tusk
            sideMammal(b, [(40, 142), (43, 116), (54, 104), (62, 91), (72, 98), (85, 80), (98, 92),
                           (117, 78), (131, 86), (152, 95), (167, 126), (149, 152), (104, 167), (62, 160)],
                       [(143, 122), (141, 96), (135, 74), (153, 81), (166, 101), (183, 111),
                        (214, 128), (222, 146), (204, 156), (180, 146), (161, 141)],
                       [(55, 153, 38), (77, 153, 29), (143, 149, 42), (163, 141, 45)],
                       coat: darkBrown, legColor: brown, legWidth: 10,
                       tail: [(45, 129), (27, 127), (19, 114)], tailWidth: 8,
                       eye: (177, 118), nose: (214, 138), hoof: true) { b in
                b.p([(191, 143), (205, 139), (204, 153), (199, 157), (188, 151)], cream)
                b.l([(70, 112), (88, 106), (97, 104)], tan, 3.6)
                b.l([(72, 124), (89, 119)], brown, 4)
            }
        case 71: // イボイノシシ — erect tassel tail, cheek warts and sweeping white tusks
            sideMammal(b, [(43, 141), (59, 108), (91, 100), (114, 92), (131, 80), (146, 91),
                           (164, 120), (155, 147), (128, 166), (77, 163), (47, 154)],
                       [(144, 115), (145, 87), (146, 68), (160, 74), (170, 95), (187, 102),
                        (211, 118), (225, 135), (220, 153), (196, 156), (170, 142)],
                       [(61, 151, 37), (142, 149, 42), (161, 142, 45)],
                       coat: 0xA0867E, legColor: darkBrown, legWidth: 9,
                       tail: [(52, 127), (37, 112), (36, 72), (29, 52)], tailWidth: 7,
                       eye: (183, 107), nose: (214, 134), hoof: true) { b in
                b.o((186, 115, 18, 12), brown)
                b.o((200, 123, 15, 12), brown)
                b.p([(188, 147), (185, 129), (171, 114), (175, 135), (177, 151), (195, 155)], white)
                b.p([(202, 151), (209, 139), (208, 115), (218, 129), (217, 147), (210, 157)], white)
                b.o((22, 45, 15, 22), black)
            }
        case 72: // バビルサ — long legs and two distinctive tusks curling up from the snout
            sideMammal(b, [(43, 124), (64, 100), (103, 99), (136, 92), (155, 102), (170, 126),
                           (152, 148), (115, 154), (72, 150), (49, 141)],
                       [(151, 114), (146, 90), (144, 67), (157, 72), (169, 89), (186, 94),
                        (204, 106), (227, 125), (219, 140), (196, 140), (171, 131)],
                       [(63, 138, 50), (86, 144, 46), (145, 139, 54), (168, 129, 58)],
                       coat: 0xB29C9A, legColor: slate, legWidth: 8,
                       tail: [(48, 122), (29, 122), (25, 112), (32, 106)], tailWidth: 5,
                       eye: (182, 104), nose: (217, 121), hoof: true) { b in
                b.p([(208, 122), (207, 105), (202, 86), (191, 74), (181, 72), (175, 78),
                     (187, 83), (195, 94), (196, 117)], white, true, 2.7)
                b.p([(219, 128), (224, 115), (224, 98), (216, 86), (213, 100), (214, 114), (206, 125)], cream, true, 2.5)
                b.l([(202, 131), (211, 135), (219, 133)], brown, 2.7)
            }
        case 73: // アルパカ — cloud of fleece and small spear ears
            b.step(64, 148, 43, tan, back: true, hoof: true, thickness: 10)
            b.step(92, 150, 38, tan, hoof: true, thickness: 10)
            b.step(141, 150, 45, cream, back: true, hoof: true, thickness: 10)
            b.step(163, 146, 45, cream, hoof: true, thickness: 10)
            for (x, y, w, h): Box in [(40, 109, 62, 56), (58, 96, 71, 65), (96, 108, 74, 63), (121, 90, 64, 72)] {
                b.o((x, y, w, h), cream)
            }
            b.tail([(155, 140), (164, 111), (167, 75), (164, 57)], cream, 27)
            b.p([(151, 59), (143, 28), (153, 24), (163, 44), (175, 39), (187, 25), (190, 34), (183, 60)], white)
            b.o((143, 48, 59, 55), cream)
            for x: CGFloat in [149, 160, 173] { b.o((x, 44 - (x == 160 ? 4 : 0), 18, 17), white) }
            b.o((168, 77, 39, 26), tan, false)
            b.eye(176, 71, 9)
            b.spot(195, 86, 10)
        case 74: // リャマ — longer angular neck, banana-shaped ears and two saddle patches
            b.tail([(55, 129), (35, 114), (29, 103)], brown, 10)
            b.step(54, 146, 47, brown, back: true, hoof: true, thickness: 9)
            b.step(79, 151, 41, tan, hoof: true, thickness: 9)
            b.step(145, 145, 55, brown, back: true, hoof: true, thickness: 9)
            b.step(169, 144, 50, tan, hoof: true, thickness: 9)
            b.p([(39, 138), (55, 111), (90, 107), (125, 105), (144, 97), (152, 67), (153, 42),
                 (175, 34), (185, 60), (177, 93), (181, 122), (162, 151), (132, 165), (85, 164), (51, 152)], tan)
            b.p([(56, 115), (83, 109), (100, 114), (104, 139), (89, 158), (66, 157), (54, 143)], brown, false)
            b.p([(131, 107), (149, 98), (158, 72), (160, 48), (175, 42), (183, 61),
                 (176, 95), (176, 120), (154, 137)], white, false)
            b.p([(155, 57), (141, 46), (133, 29), (139, 15), (151, 32), (164, 42),
                 (173, 36), (185, 16), (193, 20), (188, 45), (177, 60)], brown)
            b.p([(151, 54), (171, 43), (193, 51), (204, 65), (221, 76), (217, 92),
                 (195, 98), (178, 88), (158, 82)], white)
            b.eye(185, 65, 10)
            b.spot(212, 76, 11, darkBrown)
        default: break
        }
    }
}
