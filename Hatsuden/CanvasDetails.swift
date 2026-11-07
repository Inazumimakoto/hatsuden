import UIKit

enum CanvasDetails {
    static func draw(_ motif: FieldMotif, in context: CGContext) {
        let wax = WaxCrayon(context: context)
        switch motif {
        case .creek: creek(wax)
        case .windmill: windmill(wax)
        case .foothill: foothill(wax)
        case .sailboat: sailboat(wax)
        case .cloudBank: cloudBank(wax)
        case .satellite: satellite(wax)
        default: break
        }
    }

    private static let green = UIColor(red: 0.47, green: 0.67, blue: 0.42, alpha: 1)
    private static let leaf = UIColor(red: 0.29, green: 0.52, blue: 0.32, alpha: 1)
    private static let blue = UIColor(red: 0.36, green: 0.66, blue: 0.80, alpha: 1)
    private static let deepBlue = UIColor(red: 0.24, green: 0.42, blue: 0.63, alpha: 1)
    private static let red = UIColor(red: 0.77, green: 0.30, blue: 0.31, alpha: 1)
    private static let brown = UIColor(red: 0.52, green: 0.37, blue: 0.28, alpha: 1)
    private static let cream = FieldInk.paper

    private static func creek(_ wax: WaxCrayon) {
        let water: [(CGFloat, CGFloat)] = [
            (33, 67), (84, 50), (144, 56), (221, 98), (285, 124), (355, 115), (414, 101),
            (469, 120), (479, 165), (449, 198), (371, 225), (319, 269), (338, 305),
            (400, 326), (467, 320), (431, 344), (353, 354), (290, 334), (256, 292),
            (261, 244), (302, 201), (385, 163), (340, 168), (268, 186), (214, 163),
            (148, 112), (89, 84)
        ]
        wax.shape(water, color: blue, border: deepBlue, width: 6, opacity: 0.84)
        wax.stroke([(102, 76), (155, 90), (212, 127), (272, 150), (317, 149)],
                   color: cream, width: 5, opacity: 0.73)
        wax.stroke([(395, 185), (336, 206), (298, 242), (283, 275)],
                   color: cream, width: 6, opacity: 0.75)
        wax.stroke([(302, 311), (329, 330), (366, 339), (411, 334)],
                   color: cream, width: 5, opacity: 0.70)
        for (x, y): (CGFloat, CGFloat) in [(88, 112), (157, 139), (229, 204), (339, 87), (441, 95), (231, 300), (441, 309)] {
            wax.stroke([(x - 10, y - 13), (x, y), (x + 1, y - 22), (x + 5, y), (x + 17, y - 11)],
                       color: leaf, width: 4, opacity: 0.73)
        }
    }

    private static func windmill(_ wax: WaxCrayon) {
        wax.fill([(123, 320), (191, 299), (246, 304), (304, 296), (361, 321), (302, 349), (198, 344)],
                 color: green, opacity: 0.64)
        wax.shape([(210, 145), (281, 142), (300, 310), (270, 320), (189, 311)],
                  color: cream, border: brown, width: 7, opacity: 0.88)
        wax.shape([(194, 153), (220, 112), (242, 82), (267, 98), (301, 149), (277, 159), (230, 155)],
                  color: red, border: brown, width: 8, opacity: 0.91)
        wax.shape([(230, 316), (228, 273), (239, 258), (255, 259), (266, 274), (264, 317)],
                  color: brown, border: FieldInk.dark, width: 5, opacity: 0.83)
        wax.shape([(226, 193), (251, 190), (254, 218), (228, 220)],
                  color: blue, border: brown, width: 5, opacity: 0.87)
        wax.stroke([(132, 50), (247, 153), (365, 253)],
                   color: brown, width: 8, opacity: 0.93)
        wax.stroke([(145, 258), (245, 152), (345, 40)],
                   color: brown, width: 8, opacity: 0.93)
        for sail: [(CGFloat, CGFloat)] in [
            [(134, 48), (162, 56), (215, 107), (202, 125), (148, 78)],
            [(343, 38), (348, 66), (298, 123), (279, 109), (320, 60)],
            [(366, 252), (338, 248), (280, 198), (294, 180), (348, 222)],
            [(145, 258), (139, 230), (192, 178), (210, 190), (166, 240)]
        ] {
            wax.shape(sail, color: red, border: brown, width: 4, opacity: 0.85)
        }
        wax.shape([(236, 143), (246, 138), (256, 144), (255, 158), (242, 163), (234, 155)],
                  color: FieldInk.yellow, border: brown, width: 5, opacity: 0.89)
    }

    private static func foothill(_ wax: WaxCrayon) {
        wax.shape([(27, 262), (83, 209), (129, 158), (177, 139), (224, 154), (269, 205),
                   (305, 242), (261, 289), (192, 313), (118, 315), (63, 295)],
                  color: blue, border: deepBlue, width: 6, opacity: 0.53)
        wax.shape([(161, 275), (208, 216), (249, 183), (299, 149), (348, 144), (401, 173),
                   (449, 214), (482, 269), (441, 309), (381, 321), (292, 320), (217, 300)],
                  color: green, border: leaf, width: 7, opacity: 0.82)
        wax.shape([(63, 289), (116, 269), (160, 233), (213, 225), (268, 248), (321, 293),
                   (379, 317), (304, 345), (215, 346), (127, 334), (81, 321)],
                  color: green, border: leaf, width: 6, opacity: 0.88)
        for (x, y, h): (CGFloat, CGFloat, CGFloat) in [
            (101, 281, 32), (127, 276, 38), (264, 302, 33), (290, 313, 46), (362, 254, 44), (398, 268, 36)
        ] {
            wax.stroke([(x - 1, y + 8), (x, y - h * 0.63)], color: brown, width: 4, opacity: 0.75)
            wax.shape([(x - 14, y), (x - 7, y - h * 0.53), (x + 1, y - h), (x + 8, y - h * 0.55), (x + 14, y - 2)],
                      color: leaf, border: leaf, width: 4, opacity: 0.84)
        }
    }

    private static func sailboat(_ wax: WaxCrayon) {
        wax.fill([(69, 277), (137, 257), (225, 261), (310, 247), (390, 253), (452, 277),
                  (412, 311), (338, 322), (236, 313), (138, 324), (85, 304)],
                 color: blue, opacity: 0.61)
        wax.stroke([(242, 72), (247, 160), (249, 259)], color: brown, width: 8, opacity: 0.90)
        wax.shape([(233, 82), (152, 224), (232, 222)], color: cream, border: deepBlue, width: 6, opacity: 0.96)
        wax.shape([(254, 111), (316, 203), (335, 228), (254, 226)],
                  color: FieldInk.yellow, border: brown, width: 6, opacity: 0.84)
        wax.shape([(145, 244), (207, 251), (289, 248), (356, 237), (329, 283), (269, 296), (185, 284)],
                  color: red, border: brown, width: 8, opacity: 0.93)
        wax.stroke([(180, 261), (236, 269), (297, 264), (331, 254)],
                   color: cream, width: 6, opacity: 0.76)
        wax.stroke([(103, 278), (124, 273), (150, 278), (172, 272)], color: cream, width: 6, opacity: 0.89)
        wax.stroke([(100, 298), (140, 291), (176, 298), (210, 292)], color: cream, width: 5, opacity: 0.81)
        wax.stroke([(304, 306), (335, 299), (368, 302), (403, 292), (434, 295)],
                   color: cream, width: 6, opacity: 0.82)
    }

    private static func cloudBank(_ wax: WaxCrayon) {
        let outlines: [[(CGFloat, CGFloat)]] = [
            [(72, 151), (91, 130), (129, 126), (150, 98), (193, 87), (231, 108), (258, 110),
             (283, 134), (323, 131), (345, 146), (336, 162), (263, 173), (178, 166), (107, 176), (68, 166)],
            [(27, 234), (52, 207), (85, 216), (120, 185), (155, 188), (174, 208), (222, 209),
             (246, 225), (224, 240), (161, 250), (85, 247), (46, 251)],
            [(212, 271), (240, 247), (283, 252), (308, 227), (341, 218), (370, 233), (394, 228),
             (419, 248), (461, 249), (486, 265), (470, 284), (400, 299), (321, 288), (250, 296)]
        ]
        for shape in outlines {
            wax.shape(shape, color: cream, border: blue, width: 6, opacity: 0.79)
        }
        wax.stroke([(152, 146), (181, 127), (203, 130), (224, 139)],
                   color: cream, width: 9, opacity: 0.91)
        wax.stroke([(311, 267), (338, 244), (365, 248), (389, 263)],
                   color: cream, width: 8, opacity: 0.89)
    }

    private static func satellite(_ wax: WaxCrayon) {
        wax.stroke([(96, 242), (231, 193), (404, 144)], color: cream, width: 7, opacity: 0.80)
        for panel: [(CGFloat, CGFloat)] in [
            [(44, 212), (157, 166), (185, 222), (65, 268)],
            [(327, 137), (448, 92), (472, 145), (349, 197)]
        ] {
            wax.shape(panel, color: deepBlue, border: blue, width: 8, opacity: 0.94)
        }
        for (x, y): (CGFloat, CGFloat) in [(80, 200), (116, 184), (362, 124), (403, 109)] {
            wax.stroke([(x, y), (x + 23, y + 55)], color: blue, width: 5, opacity: 0.88)
        }
        wax.stroke([(55, 237), (175, 191)], color: blue, width: 5, opacity: 0.86)
        wax.stroke([(338, 164), (459, 117)], color: blue, width: 5, opacity: 0.86)
        wax.shape([(178, 151), (252, 117), (298, 141), (324, 211), (252, 245), (205, 223)],
                  color: FieldInk.yellow, border: brown, width: 9, opacity: 0.91)
        wax.shape([(252, 117), (298, 141), (324, 211), (282, 194)],
                  color: FieldInk.orange, border: brown, width: 7, opacity: 0.87)
        wax.stroke([(249, 146), (244, 105), (215, 74)], color: cream, width: 7, opacity: 0.86)
        wax.shape([(168, 61), (192, 57), (226, 71), (244, 98), (232, 110), (201, 104), (176, 89)],
                  color: cream, border: blue, width: 7, opacity: 0.89)
        wax.stroke([(173, 62), (192, 85), (213, 98), (234, 105)], color: blue, width: 5, opacity: 0.71)
        wax.stroke([(284, 110), (298, 76), (315, 71)], color: red, width: 5, opacity: 0.82)
    }
}
