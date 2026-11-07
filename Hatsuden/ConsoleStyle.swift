import SwiftUI
import UIKit

enum ConsoleInk {
    static let ink = Color(red: 0.21, green: 0.17, blue: 0.19)
    static let muted = Color(red: 0.43, green: 0.37, blue: 0.36)
    static let paper = Color(red: 0.99, green: 0.96, blue: 0.87)
    static let lightPaper = Color(red: 1, green: 0.985, blue: 0.94)
    static let edge = Color(red: 0.63, green: 0.49, blue: 0.64)
    static let gold = Color(red: 0.98, green: 0.77, blue: 0.33)
    static let rust = Color(red: 0.73, green: 0.21, blue: 0.24)
    static let orange = Color(red: 0.88, green: 0.39, blue: 0.17)
    static let blue = Color(red: 0.22, green: 0.41, blue: 0.76)
    static func letter(_ size: CGFloat) -> Font { .custom("KleeOne-SemiBold", size: size) }
    static func pencil(_ size: CGFloat) -> Font { .custom("ChalkboardSE-Bold", size: size) }
}

@MainActor
enum ConsoleArtwork {
    private static var images: [String: UIImage] = [:]
    private static var missing: Set<String> = []

    static func image(_ key: String) -> UIImage? {
        if let image = images[key] { return image }
        guard !missing.contains(key) else { return nil }
        guard let image = UIImage(named: key) else {
            missing.insert(key)
            return nil
        }
        images[key] = image
        return image
    }
}

struct NotebookPaper: View {
    let asset: String
    var ruled = false

    var body: some View {
        ZStack {
            ConsoleInk.paper
            if let image = ConsoleArtwork.image(asset) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Canvas { context, size in
                    let wash = Path(ellipseIn: CGRect(x: -size.width * 0.6, y: -size.height * 0.42,
                                                      width: size.width * 1.8, height: size.height * 1.2))
                    context.fill(wash, with: .radialGradient(
                        Gradient(colors: [ConsoleInk.gold.opacity(0.29), .clear]),
                        center: CGPoint(x: size.width * 0.28, y: size.height * 0.16),
                        startRadius: 5, endRadius: size.width * 0.76))
                    if ruled {
                        for row in 0..<Int(size.height / 27) {
                            let y = CGFloat(row) * 27 + 15
                            var line = Path()
                            line.move(to: CGPoint(x: 0, y: y))
                            line.addQuadCurve(to: CGPoint(x: size.width, y: y + 1.6),
                                              control: CGPoint(x: size.width * 0.58, y: y - 1.5))
                            context.stroke(line, with: .color(ConsoleInk.edge.opacity(0.12)), lineWidth: 0.6)
                        }
                    }
                    for index in 0..<340 {
                        let x = CGFloat((index * 337 + 73) % 997) / 997 * size.width
                        let y = CGFloat((index * 683 + 29) % 991) / 991 * size.height
                        let length = CGFloat(index % 7 + 1) * 1.25
                        var fiber = Path()
                        fiber.move(to: CGPoint(x: x, y: y))
                        fiber.addQuadCurve(to: CGPoint(x: x + length, y: y + 0.55),
                                           control: CGPoint(x: x + length * 0.4, y: y - 0.65))
                        let crayons = [ConsoleInk.gold, ConsoleInk.blue, ConsoleInk.orange, ConsoleInk.edge]
                        context.stroke(fiber, with: .color(crayons[index % 4].opacity(index % 5 == 0 ? 0.22 : 0.09)),
                                       lineWidth: index % 4 == 0 ? 1.1 : 0.6)
                    }
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct PaperOutline: Shape {
    var variation: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 1
        let right = rect.maxX - 1
        let top = rect.minY + 1
        let bottom = rect.maxY - 1
        let corner = min(8, rect.width / 8, rect.height / 5)
        let wobble = variation + 2.3
        var path = Path()
        path.move(to: CGPoint(x: left + corner, y: top + 1))
        path.addQuadCurve(to: CGPoint(x: right - corner, y: top),
                          control: CGPoint(x: rect.midX, y: top + wobble))
        path.addQuadCurve(to: CGPoint(x: right - 0.4, y: top + corner),
                          control: CGPoint(x: right + 0.1, y: top - 0.1))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom - corner),
                          control: CGPoint(x: right - wobble, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: right - corner, y: bottom - 1),
                          control: CGPoint(x: right + 0.3, y: bottom))
        path.addQuadCurve(to: CGPoint(x: left + corner, y: bottom),
                          control: CGPoint(x: rect.midX, y: bottom - wobble))
        path.addQuadCurve(to: CGPoint(x: left, y: bottom - corner),
                          control: CGPoint(x: left, y: bottom))
        path.addQuadCurve(to: CGPoint(x: left + 0.7, y: top + corner),
                          control: CGPoint(x: left + wobble, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: left + corner, y: top + 1),
                          control: CGPoint(x: left + 0.1, y: top + 0.4))
        path.closeSubpath()
        return path
    }
}

struct PencilRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + 0.4))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                      control1: CGPoint(x: rect.width * 0.29, y: rect.minY),
                      control2: CGPoint(x: rect.width * 0.69, y: rect.maxY))
        return path
    }
}

struct PaperCard: ViewModifier {
    var fill: Color = ConsoleInk.lightPaper
    var line: Color = ConsoleInk.edge

    func body(content: Content) -> some View {
        content.background {
            PaperOutline()
                .fill(fill.shadow(.drop(color: ConsoleInk.rust.opacity(0.14), radius: 0.8, x: 0.5, y: 1.2)))
                .overlay {
                    if let art = ConsoleArtwork.image("ui_panel_frame") {
                        let inset = min(6, art.size.width / 4, art.size.height / 4)
                        Image(uiImage: art).resizable(capInsets: EdgeInsets(
                            top: inset, leading: inset, bottom: inset, trailing: inset
                        ))
                    } else {
                        Canvas { context, size in
                            let border = PaperOutline(variation: 2).path(in: CGRect(origin: .zero, size: size))
                            context.crayon(border, color: line, width: 2.1)
                        }
                    }
                }
                .allowsHitTesting(false)
        }
    }
}

extension View {
    func paperCard(_ fill: Color = ConsoleInk.lightPaper, line: Color = ConsoleInk.edge) -> some View {
        modifier(PaperCard(fill: fill, line: line))
    }
}

enum SketchSymbol: String {
    case bulbOff = "bulb_off", bulbOn = "bulb_on", shop, zoom, shake, tap, close, lock, moon

    var key: String { "ui_" + rawValue }
}

struct SketchIcon: View {
    let symbol: SketchSymbol
    var size: CGFloat = 26

    var body: some View {
        Group {
            if let image = ConsoleArtwork.image(symbol.key) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Canvas { context, size in
                    var context = context
                    context.scaleBy(x: size.width / 48, y: size.height / 48)
                    draw(in: context)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(in context: GraphicsContext) {
        func stroke(_ path: Path, _ color: Color = ConsoleInk.ink, _ width: CGFloat = 2) {
            context.crayon(path, color: color, width: width)
        }

        func line(_ points: [(CGFloat, CGFloat)], _ color: Color = ConsoleInk.ink, _ width: CGFloat = 2) {
            guard let start = points.first else { return }
            var path = Path()
            path.move(to: CGPoint(x: start.0, y: start.1))
            for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
            stroke(path, color, width)
        }

        func fill(_ path: Path, _ color: Color) {
            context.fill(path, with: .color(color.opacity(0.78)))
            var marks = context
            marks.clip(to: path)
            for row in 0..<12 {
                let y = CGFloat(row) * 5
                let line = PencilRule().path(in: CGRect(x: -2, y: y, width: 53, height: 13))
                marks.stroke(line, with: .color(color.opacity(row.isMultiple(of: 3) ? 0.78 : 0.47)),
                             style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            stroke(path)
        }

        func poly(_ points: [(CGFloat, CGFloat)]) -> Path {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: first.0, y: first.1))
                for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
                path.closeSubpath()
            }
        }

        switch symbol {
        case .bulbOff, .bulbOn:
            let lit = symbol == .bulbOn
            if lit {
                context.fill(Path(ellipseIn: CGRect(x: 4, y: 1, width: 41, height: 43)),
                             with: .radialGradient(Gradient(colors: [ConsoleInk.gold, ConsoleInk.gold.opacity(0)]),
                                                   center: CGPoint(x: 24, y: 21), startRadius: 4, endRadius: 22))
            }
            let bulb = Path { path in
                path.move(to: CGPoint(x: 18, y: 32))
                path.addQuadCurve(to: CGPoint(x: 16, y: 27), control: CGPoint(x: 18, y: 29))
                path.addCurve(to: CGPoint(x: 23, y: 9), control1: CGPoint(x: 6, y: 15), control2: CGPoint(x: 16, y: 8))
                path.addCurve(to: CGPoint(x: 31, y: 27), control1: CGPoint(x: 34, y: 8), control2: CGPoint(x: 38, y: 19))
                path.addQuadCurve(to: CGPoint(x: 29, y: 32), control: CGPoint(x: 30, y: 30))
                path.closeSubpath()
            }
            fill(bulb, lit ? ConsoleInk.gold : ConsoleInk.lightPaper)
            line([(20, 32), (22, 24), (20, 21), (24, 23), (28, 20), (25, 26), (27, 32)],
                 lit ? ConsoleInk.rust : ConsoleInk.muted, 1.25)
            fill(poly([(18, 32), (30, 32), (29, 39), (26, 42), (22, 42), (19, 39)]), ConsoleInk.edge)
            line([(19, 35), (29, 34), (20, 38), (29, 37)], ConsoleInk.lightPaper, 1.2)
            if lit {
                let rays: [[(CGFloat, CGFloat)]] = [
                    [(23, 2), (24, 5)], [(8, 6), (11, 10)], [(36, 9), (40, 5)],
                    [(4, 19), (9, 18)], [(39, 19), (44, 20)], [(8, 31), (11, 28)], [(38, 30), (41, 33)]
                ]
                for ray in rays {
                    line(ray, ConsoleInk.rust, 1.65)
                }
            }
        case .shop:
            let handle = Path { path in
                path.move(to: CGPoint(x: 15, y: 20))
                path.addQuadCurve(to: CGPoint(x: 33, y: 20), control: CGPoint(x: 24, y: -2))
            }
            stroke(handle, ConsoleInk.ink, 2.4)
            fill(poly([(7, 20), (41, 19), (37, 38), (13, 40)]), ConsoleInk.gold)
            for x in stride(from: 15, through: 34, by: 6) {
                line([(CGFloat(x - 1), 23), (CGFloat(x + 1), 36)], ConsoleInk.rust.opacity(0.78), 1.4)
            }
            line([(11, 27), (38, 25)], ConsoleInk.ink, 1.2)
            line([(13, 33), (36, 31)], ConsoleInk.ink, 1.2)
            line([(6, 20), (42, 19)], ConsoleInk.ink, 3.4)
        case .zoom:
            line([(19, 8), (8, 7), (7, 18)], ConsoleInk.blue, 3.7)
            line([(8, 9), (20, 20)], ConsoleInk.blue, 3.2)
            line([(29, 40), (41, 41), (40, 29)], ConsoleInk.blue, 3.7)
            line([(39, 39), (28, 28)], ConsoleInk.blue, 3.2)
        case .shake:
            // A crooked box with loose wheels and a wobble on each side.
            let box = poly([(11, 14), (34, 10), (39, 35), (15, 39)])
            fill(box, ConsoleInk.gold.opacity(0.60))
            let firstWheel = Path(ellipseIn: CGRect(x: 17, y: 20, width: 9, height: 10))
            let secondWheel = Path(ellipseIn: CGRect(x: 27, y: 25, width: 8, height: 8))
            fill(firstWheel, ConsoleInk.lightPaper)
            fill(secondWheel, ConsoleInk.lightPaper)
            line([(20, 23), (23, 27)], ConsoleInk.orange, 1.4)
            line([(30, 27), (32, 30)], ConsoleInk.orange, 1.4)
            line([(5, 12), (2, 20), (7, 26), (4, 34)], ConsoleInk.blue, 2.5)
            line([(42, 12), (46, 19), (42, 26), (46, 34)], ConsoleInk.blue, 2.5)
        case .tap:
            let hand = Path { path in
                path.move(to: CGPoint(x: 17, y: 39))
                path.addQuadCurve(to: CGPoint(x: 12, y: 27), control: CGPoint(x: 12, y: 34))
                path.addQuadCurve(to: CGPoint(x: 19, y: 28), control: CGPoint(x: 13, y: 22))
                path.addLine(to: CGPoint(x: 21, y: 13))
                path.addQuadCurve(to: CGPoint(x: 27, y: 14), control: CGPoint(x: 25, y: 9))
                path.addLine(to: CGPoint(x: 26, y: 24))
                path.addQuadCurve(to: CGPoint(x: 39, y: 26), control: CGPoint(x: 38, y: 21))
                path.addQuadCurve(to: CGPoint(x: 34, y: 42), control: CGPoint(x: 40, y: 35))
                path.addLine(to: CGPoint(x: 18, y: 43))
                path.closeSubpath()
            }
            fill(hand, ConsoleInk.lightPaper)
            line([(10, 13), (15, 16)], ConsoleInk.rust, 2)
            line([(17, 4), (20, 8)], ConsoleInk.rust, 2)
            line([(31, 6), (29, 10)], ConsoleInk.rust, 2)
        case .close:
            line([(13, 12), (23, 24), (35, 35)], ConsoleInk.ink, 3.4)
            line([(34, 12), (23, 24), (13, 36)], ConsoleInk.ink, 3.1)
        case .moon:
            let moon = Path { path in
                path.move(to: CGPoint(x: 26, y: 5))
                path.addCurve(to: CGPoint(x: 38, y: 36), control1: CGPoint(x: 12, y: 22), control2: CGPoint(x: 22, y: 36))
                path.addCurve(to: CGPoint(x: 12, y: 40), control1: CGPoint(x: 35, y: 46), control2: CGPoint(x: 21, y: 47))
                path.addCurve(to: CGPoint(x: 26, y: 5), control1: CGPoint(x: 0, y: 31), control2: CGPoint(x: 6, y: 12))
                path.closeSubpath()
            }
            fill(moon, ConsoleInk.gold)
            line([(35, 10), (35, 20)], ConsoleInk.blue, 2)
            line([(30, 15), (40, 15)], ConsoleInk.blue, 2)
        case .lock:
            let shackle = Path { path in
                path.move(to: CGPoint(x: 16, y: 22))
                path.addCurve(to: CGPoint(x: 32, y: 22), control1: CGPoint(x: 13, y: 4), control2: CGPoint(x: 34, y: 4))
            }
            stroke(shackle, ConsoleInk.ink, 3)
            fill(poly([(10, 20), (38, 19), (37, 40), (11, 41)]), ConsoleInk.gold)
            line([(24, 28), (24, 34)], ConsoleInk.ink, 3.2)
        }
    }
}

extension GraphicsContext {
    func crayon(_ path: Path, color: Color, width: CGFloat) {
        let main = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round,
                               dash: [width * 6, width * 0.8, width * 3, width * 0.45])
        stroke(path, with: .color(color.opacity(0.87)), style: main)
        let scuff = path.applying(CGAffineTransform(translationX: width * 0.32, y: -width * 0.28))
        stroke(scuff, with: .color(color.opacity(0.38)), style: StrokeStyle(
            lineWidth: width * 0.76, lineCap: .round, lineJoin: .round, dash: [width * 2.2, width * 1.4]))
    }
}
