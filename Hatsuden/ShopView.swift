import SwiftUI

struct ShopView: View {
    let model: GameModel
    @Binding var offlineCredit: OfflineCredit?
    let onPurchase: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var ads = RewardAds()
    @State private var showingAdPrivacy = false
    @State private var adPrivacyMessage: String?

    private var nextIndex: Int? {
        let index = model.highestOwned + 1
        return model.species.indices.contains(index) ? index : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            rewardPanel
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 9) {
                    if let nextIndex {
                        sectionTitle("次のどうぶつ", code: "NEW ARRIVAL")
                        ShopRow(species: model.species[nextIndex], model: model, onPurchase: onPurchase, isNew: true)
                    }

                    sectionTitle("仲間を増やす", code: "YOUR CREW")
                        .padding(.top, nextIndex == nil ? 0 : 7)
                    ForEach(model.species[0...model.highestOwned].reversed()) { species in
                        ShopRow(species: species, model: model, onPurchase: onPurchase)
                    }

                    if let nextIndex, nextIndex + 1 < model.species.count {
                        sectionTitle("未解放", code: "LOCKED")
                            .padding(.top, 7)
                        Text("ひとつ前のどうぶつを迎えると解放されます。")
                            .font(ConsoleInk.letter(11))
                            .foregroundStyle(ConsoleInk.muted)
                        ForEach(model.species[(nextIndex + 1)...]) { species in
                            lockedRow(species)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 13)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            HStack(spacing: 20) {
                Link("プライバシーポリシー", destination: URL(string: "https://hatsuden-animals.netlify.app/privacy.html")!)
                Link("お問い合わせ", destination: URL(string: "https://hatsuden-animals.netlify.app/support.html")!)
            }
            .font(ConsoleInk.letter(11))
            .foregroundStyle(ConsoleInk.blue)
            .frame(maxWidth: .infinity, minHeight: 44)
            BannerAdFooter(surface: .shop, isVisible: !showingAdPrivacy && ads.pending == nil)
        }
        .background { NotebookPaper(asset: "ui_shop_paper", ruled: true).ignoresSafeArea() }
        .foregroundStyle(ConsoleInk.ink)
        .onDisappear { ads.cancelLoading() }
    }

    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                SketchIcon(symbol: .shop, size: 34)
                    .frame(width: 43, height: 43)
                    .paperCard(ConsoleInk.gold.opacity(0.55))
                    .rotationEffect(.degrees(-7))
                VStack(alignment: .leading, spacing: 2) {
                    Text("発電所の売店")
                        .font(ConsoleInk.letter(21))
                        .accessibilityAddTraits(.isHeader)
                    Text("HATSUDEN SUPPLY")
                        .font(ConsoleInk.pencil(9))
                        .tracking(1.3)
                        .foregroundStyle(ConsoleInk.muted)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: 6)
                musicButton
                Button {
                    ads.cancelLoading()
                    dismiss()
                } label: {
                    SketchIcon(symbol: .close, size: 26)
                        .frame(width: 48, height: 48)
                        .paperCard(ConsoleInk.blue.opacity(0.14), line: ConsoleInk.blue)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("売店を閉じる")
                .accessibilityIdentifier("shop-close")
            }

            HStack {
                Text("所持金")
                    .font(ConsoleInk.letter(11))
                    .fixedSize()
                WalletReadout(model: model, offlineCredit: offlineCredit, fontSize: 17)
                    .frame(height: 22)
            }
            .foregroundStyle(ConsoleInk.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .paperCard(ConsoleInk.gold.opacity(0.24), line: ConsoleInk.rust)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("所持金、\(Currency.full(model.balance))円")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { PencilRule().stroke(ConsoleInk.edge.opacity(0.72), style: StrokeStyle(lineWidth: 1, lineCap: .round)).frame(height: 2) }
    }

    private var musicButton: some View {
        let music = GameMusic.shared
        return Button(action: music.toggleMute) {
            Text("♪")
                .font(ConsoleInk.pencil(25))
                .overlay {
                    if music.isMuted {
                        PencilRule()
                            .stroke(ConsoleInk.rust, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 24, height: 2)
                            .rotationEffect(.degrees(-40))
                    }
                }
                .frame(width: 44, height: 44)
                .paperCard(ConsoleInk.gold.opacity(0.18), line: ConsoleInk.edge)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("BGM")
        .accessibilityValue(music.isMuted ? "オフ" : "オン")
        .accessibilityIdentifier("shop-music-toggle")
    }

    private func sectionTitle(_ title: String, code: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(ConsoleInk.letter(13))
                .fixedSize()
            PencilRule().stroke(ConsoleInk.edge.opacity(0.72), style: StrokeStyle(lineWidth: 1, lineCap: .round)).frame(height: 2).accessibilityHidden(true)
            Text(code)
                .font(ConsoleInk.pencil(9))
                .tracking(1)
                .foregroundStyle(ConsoleInk.muted)
                .accessibilityHidden(true)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private var rewardPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("広告で5分間ブースト")
                .font(ConsoleInk.letter(13))
                .accessibilityAddTraits(.isHeader)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack(spacing: 7) {
                    rewardButton(.tap, title: "連打発電 2倍", icon: .tap, color: ConsoleInk.orange)
                    rewardButton(.background, title: "留守中の発電 2倍", icon: .moon, color: ConsoleInk.blue)
                }
            }
            if AdsPrivacy.shared.optionsRequired {
                Button(action: openAdPrivacyOptions) {
                    Text("広告のプライバシー設定")
                        .font(ConsoleInk.letter(12))
                        .foregroundStyle(ConsoleInk.blue)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(showingAdPrivacy || ads.pending != nil)
            }
            if let message = adPrivacyMessage ?? ads.message {
                Text(message)
                    .font(ConsoleInk.letter(11))
                    .foregroundStyle(ConsoleInk.rust)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            PencilRule().stroke(ConsoleInk.edge.opacity(0.55), lineWidth: 1).frame(height: 2)
        }
    }

    private func openAdPrivacyOptions() {
        guard !showingAdPrivacy else { return }
        showingAdPrivacy = true
        adPrivacyMessage = nil
        Task {
            defer { showingAdPrivacy = false }
            do {
                try await AdsPrivacy.shared.presentOptions()
            } catch {
                adPrivacyMessage = "広告のプライバシー設定を開けませんでした。"
            }
        }
    }

    private func rewardButton(_ kind: BoostKind, title: String, icon: SketchSymbol, color: Color) -> some View {
        let seconds = Int(model.boostRemaining(kind).rounded(.up))
        let active = seconds > 0
        let loading = ads.pending == kind
        let status = active ? String(format: "%d:%02d", seconds / 60, seconds % 60) :
            (loading ? "読込中…" : "広告を見る")

        return Button {
            adPrivacyMessage = nil
            ads.watch(kind, model: model)
        } label: {
            HStack(spacing: 5) {
                SketchIcon(symbol: icon, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(ConsoleInk.letter(12))
                    Text(status)
                        .font(active ? ConsoleInk.pencil(13) : ConsoleInk.letter(10))
                        .foregroundStyle(ConsoleInk.muted)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .paperCard(color.opacity(active ? 0.30 : 0.13), line: color)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(active || showingAdPrivacy || ads.pending != nil)
        .accessibilityLabel("\(title)、\(status)")
        .accessibilityHint(kind == .background ? "有効な間はプレイ中も動物が起きています" : "発電できるタップの収益が増えます")
        .accessibilityIdentifier(kind == .tap ? "reward-tap" : "reward-background")
    }

    private func lockedRow(_ species: AnimalSpecies) -> some View {
        let size = AnimalCatalog.sizeLabel(for: species.name)
        return HStack(spacing: 9) {
            Image(uiImage: ArtProvider.shared.silhouetteImage(index: species.artIndex))
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: 37, height: 37)
                .accessibilityHidden(true)
            Text("???").font(ConsoleInk.pencil(16))
            Spacer(minLength: 0)
            if let size {
                Text("約\(size)")
                    .font(ConsoleInk.letter(10))
                    .foregroundStyle(ConsoleInk.muted)
            }
            SketchIcon(symbol: .lock, size: 16)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .paperCard(ConsoleInk.edge.opacity(0.08), line: ConsoleInk.edge.opacity(0.55))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("未解放のどうぶつ")
        .accessibilityValue(size.map { "大きさ、約\($0)" } ?? "")
    }
}

private struct ShopRow: View {
    let species: AnimalSpecies
    let model: GameModel
    let onPurchase: () -> Void
    var isNew = false
    @State private var purchaseToken = 0

    private var owned: Int { model.counts[species.index] }
    private var price: Yen { model.price(for: species.index) }
    private var affordable: Bool { model.canAfford(species.index) }

    var body: some View {
        HStack(spacing: 10) {
            Image(uiImage: ArtProvider.shared.animalImage(index: species.artIndex))
                .resizable()
                .scaledToFit()
                .padding(3)
                .frame(width: 48, height: 48)
                .paperCard(ConsoleInk.paper)
                .rotationEffect(.degrees(-3))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: "NO. %03d", species.index + 1))
                    .font(ConsoleInk.pencil(8))
                    .tracking(0.6)
                    .foregroundStyle(ConsoleInk.muted)
                Text(species.name)
                    .font(ConsoleInk.letter(14))
                    .lineLimit(2)
                if let size = AnimalCatalog.sizeLabel(for: species.name) {
                    Text("大きさ 約\(size)")
                        .font(ConsoleInk.letter(10))
                        .foregroundStyle(ConsoleInk.muted)
                }
                Text("1回 +¥\(Currency.compact(species.income))")
                    .font(ConsoleInk.letter(10))
                    .foregroundStyle(ConsoleInk.muted)
                    .lineLimit(1)
                if !isNew {
                    Text("\(owned.formatted())体")
                        .font(ConsoleInk.letter(10))
                        .foregroundStyle(ConsoleInk.rust)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .accessibilityLabel("\(owned)体所有")
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 3)
            purchaseControl
        }
        .padding(8)
        .paperCard(isNew ? ConsoleInk.lightPaper : ConsoleInk.lightPaper.opacity(0.70),
                   line: isNew ? ConsoleInk.rust : ConsoleInk.edge)
        .sensoryFeedback(.success, trigger: purchaseToken)
    }

    private var purchaseControl: some View {
        Button {
            if model.purchase(species.index) {
                onPurchase()
                purchaseToken += 1
            }
        } label: {
            VStack(spacing: 2) {
                Text(isNew ? "迎える" : "追加する")
                    .font(ConsoleInk.letter(9))
                Text("¥\(Currency.compact(price))")
                    .font(ConsoleInk.pencil(12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .foregroundStyle(affordable ? ConsoleInk.ink : ConsoleInk.muted)
            .padding(.horizontal, 3)
            .frame(width: 88, height: 44)
            .paperCard(affordable ? ConsoleInk.gold.opacity(0.68) : ConsoleInk.edge.opacity(0.15),
                       line: affordable ? ConsoleInk.rust : ConsoleInk.edge)
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
        .accessibilityLabel("\(species.name)を\(isNew ? "迎える" : "追加する")、\(Currency.full(price))円")
        .accessibilityIdentifier("buy-\(species.id)")
    }
}
