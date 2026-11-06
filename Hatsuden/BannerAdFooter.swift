import GoogleMobileAds
import SwiftUI

struct BannerAdFooter: View {
    enum Surface {
        case game, shop

        var separation: CGFloat { self == .game ? 32 : 22 }
        var accessibilityIdentifier: String { self == .game ? "game-banner-ad" : "shop-banner-ad" }
    }

    let surface: Surface
    let isVisible: Bool

    var body: some View {
        let unitID = AdPlacement.banner.unitID
        if unitID != nil || surface == .game {
            let adSize = cgSize(for: AdSizeBanner)
            ZStack {
                if surface == .game {
                    placeholder
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                if isVisible, let unitID {
                    PermittedBanner(unitID: unitID, accessibilityIdentifier: surface.accessibilityIdentifier)
                }
            }
            .frame(width: adSize.width, height: adSize.height)
            .padding(.top, unitID == nil ? 8 : surface.separation)
            .padding(.bottom, unitID == nil ? 0 : 4)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                if unitID != nil {
                    PencilRule()
                        .stroke(ConsoleInk.edge.opacity(0.55), lineWidth: 1)
                        .frame(height: 2)
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let art = ConsoleArtwork.image("ui_ad_frame") {
            Image(uiImage: art).resizable()
        } else {
            PaperOutline().fill(ConsoleInk.lightPaper.opacity(0.26))
                .overlay(PaperOutline(variation: 2).stroke(ConsoleInk.edge.opacity(0.43),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [6, 4, 2, 5])))
        }
    }
}

private struct PermittedBanner: View {
    let unitID: String
    let accessibilityIdentifier: String

    @Environment(\.scenePhase) private var scenePhase
    @State private var canShowBanner = false

    var body: some View {
        ZStack {
            if canShowBanner {
                BannerAdView(unitID: unitID)
                    .accessibilityIdentifier(accessibilityIdentifier)
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            let permitted = await AdsPrivacy.shared.prepare()
            guard !Task.isCancelled else { return }
            canShowBanner = permitted
        }
    }
}

private struct BannerAdView: UIViewRepresentable {
    let unitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = unitID
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {}
}
