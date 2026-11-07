import GoogleMobileAds
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class AppOpenAds: NSObject, FullScreenContentDelegate {
    static let shared = AppOpenAds()

    private static let launchCountKey = "hatsuden.appOpenAd.launchCount"
    private static let launchesBeforeAds = 2
    private static let logger = Logger(subsystem: "jp.hatsuden.works", category: "AppOpenAds")

    private(set) var isShowingLaunchCover: Bool
    private let unitID: String?
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var ad: AppOpenAd?
    @ObservationIgnored private var loading: Task<Void, Never>?
    @ObservationIgnored private var timeout: Task<Void, Never>?

    private override init() {
        unitID = AdPlacement.appOpen.unitID
        #if DEBUG
        isShowingLaunchCover = unitID != nil &&
            !ProcessInfo.processInfo.arguments.contains("--stress-particles") &&
            !ProcessInfo.processInfo.arguments.contains("--pile-demo")
        #else
        isShowingLaunchCover = unitID != nil &&
            UserDefaults.standard.integer(forKey: Self.launchCountKey) >= Self.launchesBeforeAds
        #endif
        super.init()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        guard let unitID else { return }

        #if !DEBUG
        let launches = UserDefaults.standard.integer(forKey: Self.launchCountKey)
        if launches < Self.launchesBeforeAds {
            UserDefaults.standard.set(launches + 1, forKey: Self.launchCountKey)
        }
        #endif

        guard isShowingLaunchCover else { return }
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(4))
        timeout = Task {
            do {
                try await clock.sleep(until: deadline)
                finish()
            } catch {}
        }
        loading = Task {
            defer { loading = nil }
            do {
                let isReady = await AdsPrivacy.shared.prepare()
                try Task.checkCancellation()
                guard isReady, clock.now < deadline else {
                    finish()
                    return
                }
                let loaded = try await AppOpenAd.load(with: unitID, request: Request())
                try Task.checkCancellation()
                guard clock.now < deadline, AdsPrivacy.shared.canRequestAds,
                      let presenter = AdsPrivacy.activePresenter else {
                    finish()
                    return
                }
                try loaded.canPresent(from: presenter)
                loaded.fullScreenContentDelegate = self
                ad = loaded
                timeout?.cancel()
                timeout = nil
                loaded.present(from: presenter)
            } catch {
                guard !Task.isCancelled else { return }
                Self.logFailure(error)
                finish()
            }
        }
    }

    func skipIfLoading() {
        if isShowingLaunchCover, ad == nil { finish() }
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        finish()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Self.logFailure(error)
        finish()
    }

    private func finish() {
        timeout?.cancel()
        timeout = nil
        loading?.cancel()
        ad = nil
        isShowingLaunchCover = false
    }

    private static func logFailure(_ error: any Error) {
        let error = error as NSError
        logger.error("App open ad error: \(error.domain, privacy: .public) \(error.code)")
    }
}
