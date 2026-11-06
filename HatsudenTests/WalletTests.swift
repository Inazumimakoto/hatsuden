import Foundation
import XCTest
@testable import Hatsuden

final class WalletTests: XCTestCase {
    func testOfflineCountUpStartsAtTheOldBalanceAndEndsAtTheCreditedBalance() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let earned = try XCTUnwrap(Yen("2" + String(repeating: "0", count: 190)))
        let prior = earned + 17
        let actual = prior + earned
        let credit = OfflineCredit(amount: earned, startedAt: start)

        XCTAssertEqual(credit.displayedBalance(actual: actual, at: start), prior)
        XCTAssertEqual(credit.displayedBalance(actual: actual + 1, at: start + 0.685),
                       prior + earned.divided(by: 2).whole + 1)
        XCTAssertEqual(credit.displayedBalance(actual: actual + 1, at: start + OfflineCredit.duration), actual + 1)
    }

    func testWalletKeepsSmallValuesAndUsesStandardSIPrefixesForLargerOnes() throws {
        XCTAssertEqual(Currency.wallet(999_999), "999,999")
        XCTAssertEqual(Currency.wallet(1_025_001), "1.02M")
        XCTAssertEqual(Currency.compact(1_920), "1.92k")
        XCTAssertEqual(Currency.compact(1_000_000_000), "1G")
        XCTAssertEqual(Currency.compact(try XCTUnwrap(Yen("125" + String(repeating: "0", count: 28)))), "1.25Q")
        XCTAssertEqual(Currency.wallet(try XCTUnwrap(Yen("123" + String(repeating: "0", count: 188)))), "1.23e190")
    }
}
