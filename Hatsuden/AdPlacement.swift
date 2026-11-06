import Foundation

enum AdPlacement: CaseIterable {
    case tapReward
    case backgroundReward
    case appOpen
    case banner

    var unitID: String? {
        #if DEBUG
        switch self {
        case .tapReward, .backgroundReward: "ca-app-pub-3940256099942544/1712485313"
        case .appOpen: "ca-app-pub-3940256099942544/5575463023"
        case .banner: "ca-app-pub-3940256099942544/2934735716"
        }
        #else
        productionUnitID
        #endif
    }

    static var hasProductionUnits: Bool {
        allCases.contains { $0.productionUnitID != nil }
    }

    private var infoKey: String {
        switch self {
        case .tapReward: "HatsudenTapRewardAdUnit"
        case .backgroundReward: "HatsudenBackgroundRewardAdUnit"
        case .appOpen: "HatsudenAppOpenAdUnit"
        case .banner: "HatsudenBannerAdUnit"
        }
    }

    private var productionUnitID: String? {
        guard let appID = Self.productionID(for: "GADApplicationIdentifier", separator: "~"),
              let unitID = Self.productionID(for: infoKey, separator: "/") else { return nil }
        let publisher = appID.prefix { $0 != "~" }
        guard unitID.hasPrefix("\(publisher)/") else { return nil }
        return unitID
    }

    private static func productionID(for key: String, separator: Character) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let id = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "ca-app-pub-"
        let parts = id.split(separator: separator, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].hasPrefix(prefix) else { return nil }
        let publisher = parts[0].dropFirst(prefix.count)
        guard publisher != "3940256099942544",
              publisher.count == 16, publisher.allSatisfy({ $0.isASCII && $0.isNumber }),
              parts[1].count == 10, parts[1].allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return id
    }
}
