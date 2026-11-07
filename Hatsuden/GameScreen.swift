import SpriteKit
import SwiftUI

struct GameScreen: View {
    let session: PlaySession
    @Environment(\.scenePhase) private var scenePhase
    @State private var shopOpen = false
    @State private var showingGameBanner = true
    @State private var offlineCredit: OfflineCredit?

    private var model: GameModel { session.model }

    var body: some View {
        VStack(spacing: 0) {
            playArea
            BannerAdFooter(surface: .game, isVisible: showingGameBanner)
        }
        .padding(.bottom, 5)
        .background {
            NotebookPaper(asset: "ui_paper", ruled: true).ignoresSafeArea()
        }
        .foregroundStyle(ConsoleInk.ink)
        .accessibilityHidden(shopOpen)
        .fullScreenCover(isPresented: $shopOpen, onDismiss: closeShop) {
            ShopView(model: model, offlineCredit: $offlineCredit, onPurchase: session.scene.synchronizeShopAdditions)
        }
        .task(id: scenePhase) {
            if scenePhase == .active { await AdsPrivacy.shared.refreshIfConfigured() }
        }
        .onChange(of: model.offlineEarnings, initial: true) { _, earnings in
            if let earnings, earnings > 0 {
                offlineCredit = OfflineCredit(amount: earnings, startedAt: .now)
                AccessibilityNotification.Announcement("留守中に\(Currency.full(earnings))円発電しました").post()
                model.dismissOfflineEarnings()
            }
        }
        .task(id: offlineCredit?.startedAt) {
            guard offlineCredit != nil else { return }
            do {
                try await Task.sleep(for: .seconds(OfflineCredit.duration))
                offlineCredit = nil
            } catch {}
        }
    }

    private var playArea: some View {
        VStack(spacing: 8) {
            topBar
            HStack(alignment: .top, spacing: 7) {
                PowerColumn(model: model, tap: session.scene.registerTap, openShop: openShop)
                    .frame(width: 56)
                SpriteView(scene: session.scene, preferredFramesPerSecond: 120, options: [.ignoresSiblingOrder])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding(3)
                    .paperCard()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("発電フロア")
                    .accessibilityHint("続けてダブルタップして出力を溜める")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { session.scene.registerTap() }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: session.scene.registerTap)
        }
    }

    private func openShop() {
        session.scene.setShopPresented(true)
        showingGameBanner = false
        shopOpen = true
    }

    private func closeShop() {
        showingGameBanner = true
        session.scene.setShopPresented(false)
    }

    private var topBar: some View {
        HStack(spacing: 6) {
            WalletReadout(model: model, offlineCredit: offlineCredit)
                .frame(height: 51)
                .padding(.horizontal, 10)
                .paperCard(ConsoleInk.lightPaper, line: ConsoleInk.orange)
                .contentShape(Rectangle())
                .onTapGesture(perform: session.scene.registerTap)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("所持金、\(Currency.full(model.balance))円")
                .accessibilityIdentifier("balance")

            Button(action: session.scene.resetZoom) {
                SketchIcon(symbol: .zoom, size: 29)
                    .frame(width: 51, height: 51)
                    .paperCard(ConsoleInk.blue.opacity(0.17), line: ConsoleInk.blue)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("全景に戻す")
            .accessibilityIdentifier("zoom-reset")

            Button(action: session.scene.shake) {
                SketchIcon(symbol: .shake, size: 30)
                    .frame(width: 51, height: 51)
                    .paperCard(ConsoleInk.gold.opacity(0.40), line: ConsoleInk.rust)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("発電箱を揺らす")
            .accessibilityHint("続けて押すと車輪が混ざります")
            .accessibilityIdentifier("field-shake")
        }
    }
}

struct OfflineCredit {
    static let duration = 1.55
    let amount: Yen
    let startedAt: Date

    func displayedBalance(actual: Yen, at date: Date) -> Yen {
        let progress = min(1, max(0, (date.timeIntervalSince(startedAt) - 0.16) / 1.05))
        let eased = progress * progress * (3 - 2 * progress)
        let steps = UInt64((eased * 1_000).rounded())
        let pending = amount - (amount * steps).divided(by: 1_000).whole
        return actual >= pending ? actual - pending : 0
    }
}

struct WalletReadout: View {
    let model: GameModel
    let offlineCredit: OfflineCredit?
    var fontSize: CGFloat = 34

    var body: some View {
        let balance = model.balance
        if let waiting = model.offlineEarnings, balance >= waiting {
            BalanceInk(amount: Currency.wallet(balance - waiting), fontSize: fontSize)
        } else if let offlineCredit {
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(offlineCredit.startedAt)
                let fade = min(1, max(0, (OfflineCredit.duration - elapsed) / 0.25))
                HStack(spacing: 5) {
                    Text("+¥\(Currency.compact(offlineCredit.amount))")
                        .font(ConsoleInk.pencil(fontSize > 20 ? 13 : 10))
                        .foregroundStyle(ConsoleInk.rust)
                        .lineLimit(1)
                        .fixedSize()
                        .opacity(fade)
                        .offset(y: -3 * (1 - fade))
                    BalanceInk(amount: Currency.wallet(offlineCredit.displayedBalance(actual: balance, at: timeline.date)),
                               fontSize: fontSize)
                }
            }
            .accessibilityHidden(true)
        } else {
            BalanceInk(amount: Currency.wallet(balance), fontSize: fontSize)
        }
    }
}

private struct BalanceInk: View {
    let amount: String
    var fontSize: CGFloat = 34

    private struct Glyph {
        let character: String
        let image: UIImage?
        let advance: CGFloat
    }

    var body: some View {
        let value = "¥" + amount
        let art = Dictionary(uniqueKeysWithValues: Set(value).compactMap { character in
            glyphImage(character).map { (character, $0) }
        })
        let glyphs = art.isEmpty ? [] : value.map { glyph($0, image: art[$0]) }
        Canvas { context, size in
            guard size.width > 2, size.height > 0 else { return }
            if glyphs.isEmpty {
                let text = context.resolve(inkText(value))
                let measured = text.measure(in: CGSize(width: 100_000, height: 1_000))
                guard measured.width > 0, measured.height > 0 else { return }
                let scale = min(1, (size.width - 2) / measured.width, size.height / measured.height)
                var drawing = context
                drawing.translateBy(x: size.width - 1, y: size.height / 2)
                drawing.scaleBy(x: scale, y: scale)
                drawing.draw(text, at: .zero, anchor: .trailing)
            } else {
                drawGlyphs(glyphs, in: context, size: size)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawGlyphs(_ glyphs: [Glyph], in context: GraphicsContext, size: CGSize) {
        let width = glyphs.reduce(0) { $0 + $1.advance }
        guard width > 0 else { return }
        let scale = min(1, (size.width - 2) / width, size.height / (fontSize * 1.15))
        var drawing = context
        drawing.translateBy(x: size.width - 1 - width * scale, y: size.height / 2)
        drawing.scaleBy(x: scale, y: scale)
        var x: CGFloat = 0
        for glyph in glyphs {
            if let image = glyph.image {
                let height = fontSize * 0.88
                drawing.draw(Image(uiImage: image), in: CGRect(x: x + 1, y: -height / 2,
                                                               width: glyph.advance - 2, height: height))
            } else {
                drawing.draw(inkText(glyph.character), at: CGPoint(x: x + glyph.advance / 2, y: 0))
            }
            x += glyph.advance
        }
    }

    private func inkText(_ value: String) -> Text {
        Text(verbatim: value).font(ConsoleInk.pencil(fontSize)).foregroundColor(ConsoleInk.ink)
    }

    private func glyphImage(_ character: Character) -> UIImage? {
        let key: String
        switch character {
        case "¥": key = "digit_yen"
        case ",": key = "digit_comma"
        case ".": return ConsoleArtwork.image("digit_dot") ?? ConsoleArtwork.image("digit_decimal")
        case "0"..."9": key = "digit_\(character)"
        default: return ConsoleArtwork.image("unit_\(character)") ?? ConsoleArtwork.image("digit_\(character)")
        }
        return ConsoleArtwork.image(key)
    }

    private func glyph(_ character: Character, image: UIImage?) -> Glyph {
        let string = String(character)
        if let image {
            let width = min(fontSize, fontSize * 0.88 * image.size.width / max(1, image.size.height))
            return Glyph(character: string, image: image, advance: width + 2)
        }
        let font = UIFont(name: "ChalkboardSE-Bold", size: fontSize) ?? .systemFont(ofSize: fontSize)
        let width = (string as NSString).size(withAttributes: [.font: font]).width
        return Glyph(character: string, image: nil, advance: width)
    }
}

private struct PowerColumn: View {
    let model: GameModel
    let tap: () -> Void
    let openShop: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            SketchIcon(symbol: model.isLit ? .bulbOn : .bulbOff, size: 46)
                .frame(width: 56, height: 49)
                .contentShape(Rectangle())
                .onTapGesture(perform: tap)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(model.isLit ? "電球、発電中" : "電球、待機中")

            MeterWell(level: model.meter, isLit: model.isLit)
                .contentShape(Rectangle())
                .onTapGesture(perform: tap)

            Button(action: openShop) {
                SketchIcon(symbol: .shop, size: 34)
                    .frame(width: 56, height: 57)
                    .paperCard(ConsoleInk.gold.opacity(0.45), line: ConsoleInk.orange)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("ショップを開く")
            .accessibilityIdentifier("shop-open")
        }
    }
}

private struct MeterWell: View {
    let level: Double
    let isLit: Bool

    var body: some View {
        let face = ConsoleArtwork.image("ui_gauge_face")
        let brush = ConsoleArtwork.image("ui_gauge_fill")
        Canvas { context, size in
            let tube = CGRect(x: 3, y: 2, width: max(0, size.width - 6), height: max(0, size.height - 4))
            let outline = PaperOutline(variation: 2).path(in: tube)
            context.fill(outline, with: .color(ConsoleInk.gold.opacity(0.13)))

            if level > 0 {
                let y = tube.maxY - tube.height * level
                let fill = Path { path in
                    path.move(to: CGPoint(x: tube.minX, y: y + 3))
                    path.addQuadCurve(to: CGPoint(x: tube.maxX, y: y - 1),
                                      control: CGPoint(x: tube.midX, y: y - 5))
                    path.addLine(to: CGPoint(x: tube.maxX, y: tube.maxY))
                    path.addLine(to: CGPoint(x: tube.minX, y: tube.maxY))
                    path.closeSubpath()
                }
                var paint = context
                paint.clip(to: outline)
                paint.clip(to: fill)
                if let brush {
                    paint.draw(Image(uiImage: brush), in: tube)
                } else {
                    paint.fill(fill, with: .color(isLit ? ConsoleInk.gold.opacity(0.78) : ConsoleInk.blue.opacity(0.30)))
                    let crayon = isLit ? ConsoleInk.orange : ConsoleInk.blue
                    for row in stride(from: 0, to: Int(tube.height), by: 4) {
                        let y = tube.minY + CGFloat(row)
                        let line = PencilRule().path(in: CGRect(x: tube.minX - 1, y: y, width: tube.width + 2, height: 5))
                        paint.stroke(line, with: .color(crayon.opacity(row.isMultiple(of: 12) ? 0.52 : 0.27)),
                                     style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    }
                }
            }

            if let face {
                context.draw(Image(uiImage: face), in: tube)
            } else {
                context.crayon(outline, color: ConsoleInk.blue, width: 2.2)
                for index in 1..<15 {
                    let y = tube.minY + tube.height * CGFloat(index) / 15
                    let length = tube.width * (index.isMultiple(of: 3) ? 0.45 : 0.24)
                    let mark = PencilRule().path(in: CGRect(x: tube.minX + 2, y: y, width: length, height: 2))
                    context.crayon(mark, color: ConsoleInk.blue.opacity(0.60), width: 1.1)
                }
                let y = tube.minY + tube.height * (1 - GameModel.ignitionLevel)
                let ignition = PencilRule().path(in: CGRect(x: 2, y: y - 2, width: max(0, size.width - 4), height: 4))
                context.crayon(ignition, color: ConsoleInk.rust, width: 2.3)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .paperCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("発電メーター")
        .accessibilityValue("\(Int((level * 100).rounded()))パーセント")
        .accessibilityIdentifier("power-meter")
    }
}
