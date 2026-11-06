import GoogleMobileAds
import Observation
import OSLog
import UIKit
import UserMessagingPlatform

@MainActor
@Observable
final class AdsPrivacy {
    static let shared = AdsPrivacy()

    private(set) var optionsRequired = false
    @ObservationIgnored private var sdkStartup: Task<Void, Never>?
    @ObservationIgnored private var consentRefresh: Task<Void, Never>?
    @ObservationIgnored private var didUpdateConsent = false
    @ObservationIgnored private var didPresentRequiredForm = false
    @ObservationIgnored private var isPresentingOptions = false

    private let logger = Logger(subsystem: "jp.hatsuden.works", category: "AdsPrivacy")

    private init() {}

    func refreshIfConfigured() async {
        #if !DEBUG
        guard RewardAds.hasConfiguredUnits else { return }
        await gatherConsent()
        #endif
    }

    func prepare() async -> Bool {
        #if !DEBUG
        guard RewardAds.hasConfiguredUnits else { return false }
        await gatherConsent()
        #endif
        guard canRequestAds else { return false }
        if sdkStartup == nil {
            sdkStartup = Task { _ = await MobileAds.shared.start() }
        }
        await sdkStartup?.value
        return canRequestAds
    }

    var canRequestAds: Bool {
        #if DEBUG
        true
        #else
        !isPresentingOptions && ConsentInformation.shared.canRequestAds
        #endif
    }

    func presentOptions() async throws {
        guard optionsRequired, consentRefresh == nil, !isPresentingOptions,
              let presenter = Self.activePresenter else {
            throw OptionsError.unavailable
        }
        isPresentingOptions = true
        defer {
            optionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            isPresentingOptions = false
        }
        try await ConsentForm.presentPrivacyOptionsForm(from: presenter)
    }

    private func gatherConsent() async {
        guard !didPresentRequiredForm, !isPresentingOptions else { return }
        if let consentRefresh {
            await consentRefresh.value
            return
        }
        let task = Task {
            defer {
                optionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                consentRefresh = nil
            }
            do {
                if !didUpdateConsent {
                    try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
                    didUpdateConsent = true
                }
                guard let presenter = Self.activePresenter else { return }
                try await ConsentForm.loadAndPresentIfRequired(from: presenter)
                didPresentRequiredForm = true
            } catch {
                let error = error as NSError
                logger.error("Consent refresh failed: \(error.domain, privacy: .public) \(error.code)")
            }
        }
        consentRefresh = task
        await task.value
    }

    static var activePresenter: UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?.keyWindow
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController, !presented.isBeingDismissed {
            controller = presented
        }
        guard controller?.viewIfLoaded?.window != nil else { return nil }
        return controller
    }

    private enum OptionsError: Error {
        case unavailable
    }
}
