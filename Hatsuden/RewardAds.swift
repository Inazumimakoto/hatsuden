import GoogleMobileAds
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class RewardAds: NSObject, FullScreenContentDelegate {
    private static let logger = Logger(subsystem: "jp.hatsuden.works", category: "RewardAds")
    private(set) var pending: BoostKind?
    private(set) var message: String?
    @ObservationIgnored private var ad: RewardedAd?
    @ObservationIgnored private var loading: Task<Void, Never>?

    func watch(_ kind: BoostKind, model: GameModel) {
        guard pending == nil, model.boostRemaining(kind) <= 0 else { return }
        let placement: AdPlacement = kind == .tap ? .tapReward : .backgroundReward
        guard let adUnit = placement.unitID else {
            message = "広告は準備中です。"
            return
        }
        pending = kind
        message = nil
        loading = Task {
            defer { loading = nil }
            do {
                let isReady = await AdsPrivacy.shared.prepare()
                try Task.checkCancellation()
                guard isReady else {
                    finish(message: "広告を準備できませんでした。少し待ってからお試しください。")
                    return
                }
                let loaded = try await RewardedAd.load(with: adUnit, request: Request())
                try Task.checkCancellation()
                guard AdsPrivacy.shared.canRequestAds, let presenter = AdsPrivacy.activePresenter else {
                    finish(message: "売店で広告ボタンをもう一度押してください。")
                    return
                }
                try loaded.canPresent(from: presenter)
                loaded.fullScreenContentDelegate = self
                ad = loaded
                GameMusic.shared.setShowingReward(true)
                loaded.present(from: presenter) {
                    _ = model.activateBoost(kind)
                }
            } catch is CancellationError {
                finish()
            } catch {
                Self.logFailure(error)
                finish(message: "広告を読み込めませんでした。少し待ってからお試しください。")
            }
        }
    }

    func cancelLoading() {
        loading?.cancel()
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        finish()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Self.logFailure(error)
        finish(message: "広告を表示できませんでした。もう一度お試しください。")
    }

    private static func logFailure(_ error: any Error) {
        let error = error as NSError
        logger.error("Reward ad error: \(error.domain, privacy: .public) \(error.code)")
    }

    private func finish(message: String? = nil) {
        let wasShowingReward = ad != nil
        ad = nil
        if wasShowingReward { GameMusic.shared.setShowingReward(false) }
        pending = nil
        self.message = message
    }
}
