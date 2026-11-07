#!/usr/bin/env swift
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// swift Release/screenshots/render.swift <raw-directory> <output-directory> [--size=all]
// --size also accepts 1206x2622 or 1320x2868. The source screenshots stay untouched.

struct Caption {
    let filename: String
    let title: [String]
    let subtitle: String
}

let captions = [
    Caption(filename: "01-room-generation.png", title: ["タップで、", "どうぶつ発電。"],
            subtitle: "回し車の仲間たちと、こつこつ発電。"),
    Caption(filename: "02-shop.png", title: ["仲間をふやして、", "にぎやかな発電所へ。"],
            subtitle: "同じどうぶつは、8体まで迎えられます。"),
    Caption(filename: "03-city.png", title: ["小さな部屋から、", "街の外へ。"],
            subtitle: "新しい仲間と、一枚絵の続きを探そう。"),
    Caption(filename: "04-volcano.png", title: ["引くたびに、", "見つかる絵の続き。"],
            subtitle: "机のパソコンから、山や火山まで。"),
    Caption(filename: "05-space.png", title: ["200種類の仲間と、", "宇宙まで。"],
            subtitle: "小さくなった仲間も、ピンチで会いに。"),
    Caption(filename: "06-deep-zoom.png", title: ["小さくなっても、", "ここにいる。"],
            subtitle: "ピンチで、最初の仲間までズーム。")
]

struct CanvasSize {
    let width: Int
    let height: Int
    var name: String { "\(width)x\(height)" }
}

enum RenderError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let value): value }
    }
}

let paper = CGColor(red: 0.99, green: 0.96, blue: 0.87, alpha: 1)
let ink = CGColor(red: 0.21, green: 0.17, blue: 0.19, alpha: 1)
let orange = CGColor(red: 0.88, green: 0.39, blue: 0.17, alpha: 1)
let muted = CGColor(red: 0.43, green: 0.37, blue: 0.36, alpha: 1)

func registerGameFont() throws {
    let repository = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let font = repository.appendingPathComponent("Hatsuden/Fonts/KleeOne-SemiBold.ttf")
    guard FileManager.default.fileExists(atPath: font.path) else {
        throw RenderError.message("Game font missing at \(font.path)")
    }
    var error: Unmanaged<CFError>?
    CTFontManagerRegisterFontsForURL(font as CFURL, .process, &error)
    guard NSFont(name: "KleeOne-SemiBold", size: 12) != nil else {
        throw RenderError.message("Could not register the game's Klee One font.")
    }
}

func loadScreenshot(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw RenderError.message("Could not read \(url.path)")
    }
    let ratio = Double(image.width) / Double(image.height)
    guard image.width >= 1_179, image.height >= 2_556, abs(ratio - 0.46) < 0.012 else {
        throw RenderError.message("Use a full-resolution portrait iPhone screenshot for \(url.lastPathComponent).")
    }
    return image
}

func drawText(_ text: String, atTop y: CGFloat, x: CGFloat, size: CGFloat,
              color: CGColor, canvasHeight: CGFloat, context: CGContext) {
    let font = CTFontCreateWithName("KleeOne-SemiBold" as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    var ascent: CGFloat = 0
    CTLineGetTypographicBounds(line, &ascent, nil, nil)
    context.textMatrix = .identity
    context.textPosition = CGPoint(x: x, y: canvasHeight - y - ascent)
    CTLineDraw(line, context)
}

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvasHeight: CGFloat) -> CGRect {
    CGRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func drawPaper(in context: CGContext, size: CGSize) {
    context.setFillColor(paper)
    context.fill(CGRect(origin: .zero, size: size))
    context.setLineCap(.round)
    for index in 0..<420 {
        let x = CGFloat((index * 337 + 73) % 997) / 997 * size.width
        let y = CGFloat((index * 683 + 29) % 991) / 991 * size.height
        let length = CGFloat(index % 7 + 1) * 1.7
        context.setStrokeColor(CGColor(red: 0.63, green: 0.49, blue: 0.64,
                                       alpha: index % 5 == 0 ? 0.10 : 0.045))
        context.setLineWidth(index % 4 == 0 ? 1.1 : 0.65)
        context.move(to: CGPoint(x: x, y: y))
        context.addQuadCurve(to: CGPoint(x: x + length, y: y + 0.55),
                             control: CGPoint(x: x + length * 0.4, y: y - 0.65))
        context.strokePath()
    }
}

func drawFrame(around rect: CGRect, in context: CGContext, scale: CGFloat) {
    context.setLineCap(.round)
    context.setLineJoin(.round)
    for pass in 0..<3 {
        let drift = CGFloat(pass - 1) * scale
        context.setStrokeColor(CGColor(red: 0.63, green: 0.49, blue: 0.64, alpha: pass == 1 ? 0.65 : 0.18))
        context.setLineWidth(scale * (pass == 1 ? 2.1 : 1.0))
        let bounds = rect.insetBy(dx: -5 * scale - drift, dy: -5 * scale - drift)
        context.move(to: CGPoint(x: bounds.minX, y: bounds.minY + 2 * scale))
        context.addLine(to: CGPoint(x: bounds.maxX - 2 * scale, y: bounds.minY))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - 2 * scale))
        context.addLine(to: CGPoint(x: bounds.minX + scale, y: bounds.maxY))
        context.closePath()
        context.strokePath()
    }
}

func render(_ screenshot: CGImage, caption: Caption, size: CanvasSize, to destination: URL) throws {
    let width = CGFloat(size.width)
    let height = CGFloat(size.height)
    let scale = width / 1_206
    let canvas = CGSize(width: width, height: height)
    guard let context = CGContext(data: nil, width: size.width, height: size.height,
                                  bitsPerComponent: 8, bytesPerRow: size.width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw RenderError.message("Could not create RGB canvas \(size.name).")
    }
    drawPaper(in: context, size: canvas)

    let margin = width * 0.065
    drawText("発電どうぶつ", atTop: height * 0.022, x: margin, size: 31 * scale,
             color: orange, canvasHeight: height, context: context)
    for (index, line) in caption.title.enumerated() {
        drawText(line, atTop: height * 0.045 + CGFloat(index) * 77 * scale,
                 x: margin, size: 65 * scale, color: ink, canvasHeight: height, context: context)
    }
    drawText(caption.subtitle, atTop: height * 0.111, x: margin, size: 31 * scale,
             color: muted, canvasHeight: height, context: context)

    let available = CGSize(width: width * 0.89, height: height * 0.824)
    let imageScale = min(available.width / CGFloat(screenshot.width), available.height / CGFloat(screenshot.height))
    let imageSize = CGSize(width: CGFloat(screenshot.width) * imageScale,
                           height: CGFloat(screenshot.height) * imageScale)
    let imageRect = topRect(x: (width - imageSize.width) / 2, y: height * 0.15,
                            width: imageSize.width, height: imageSize.height, canvasHeight: height)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -5 * scale), blur: 15 * scale,
                      color: CGColor(gray: 0.25, alpha: 0.12))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(imageRect)
    context.restoreGState()
    context.interpolationQuality = .high
    context.draw(screenshot, in: imageRect)
    drawFrame(around: imageRect, in: context, scale: scale)

    guard let image = context.makeImage(),
          let writer = CGImageDestinationCreateWithURL(destination as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw RenderError.message("Could not write \(destination.path)")
    }
    CGImageDestinationAddImage(writer, image, nil)
    guard CGImageDestinationFinalize(writer) else {
        throw RenderError.message("Could not finish \(destination.path)")
    }
}

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    guard arguments.count >= 2 else {
        throw RenderError.message("Usage: swift render.swift <raw-directory> <output-directory> [--size=all|1206x2622|1320x2868]")
    }
    let input = URL(fileURLWithPath: arguments[0], isDirectory: true).standardizedFileURL
    let output = URL(fileURLWithPath: arguments[1], isDirectory: true).standardizedFileURL
    guard input != output else { throw RenderError.message("Use separate raw and output directories.") }
    let requestedSize = arguments.first(where: { $0.hasPrefix("--size=") }).map { String($0.dropFirst(7)) } ?? "all"
    let sizes = [CanvasSize(width: 1_206, height: 2_622), CanvasSize(width: 1_320, height: 2_868)]
        .filter { requestedSize == "all" || requestedSize == $0.name }
    guard !sizes.isEmpty else { throw RenderError.message("Unsupported output size \(requestedSize)") }
    try registerGameFont()
    let present = captions.filter { FileManager.default.fileExists(atPath: input.appendingPathComponent($0.filename).path) }
    guard !present.isEmpty else { throw RenderError.message("No named raw screenshots found in \(input.path)") }
    for size in sizes {
        let directory = output.appendingPathComponent(size.name, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for caption in present {
            let screenshot = try loadScreenshot(input.appendingPathComponent(caption.filename))
            let destination = directory.appendingPathComponent(caption.filename)
            try render(screenshot, caption: caption, size: size, to: destination)
            print(destination.path)
        }
    }
} catch {
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
    exit(1)
}
