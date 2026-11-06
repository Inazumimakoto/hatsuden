import CryptoKit
import UIKit
import XCTest
@testable import Hatsuden

final class ArtworkTests: XCTestCase {
    @MainActor
    func testEachAnimalUsesADistinctSilhouetteAndDrawing() async throws {
        var images: [SHA256.Digest: String] = [:]
        var silhouettes: [SHA256.Digest: String] = [:]
        for (index, name) in AnimalCatalog.legacyNames.enumerated() {
            try autoreleasepool {
                let image = ArtProvider.shared.animalImage(index: index)
                let png = try XCTUnwrap(image.pngData(), name)
                let signature = SHA256.hash(data: png)
                XCTAssertNil(images.updateValue(name, forKey: signature), "Reused art for \(name)")

                let stencil = try XCTUnwrap(ArtProvider.shared.silhouetteImage(index: index).cgImage, name)
                let mask = try alphaMask(stencil)
                XCTAssertTrue(mask.contains(1), "Empty illustration for \(name)")
                let shape = SHA256.hash(data: mask)
                let prior = silhouettes.updateValue(name, forKey: shape)
                XCTAssertNil(prior, "\(name) shares its silhouette with \(prior ?? "")")
            }
        }
        XCTAssertEqual(images.count, 200)
        XCTAssertEqual(silhouettes.count, 200)
    }

    private func alphaMask(_ image: CGImage) throws -> Data {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return Data(stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] >= 128 ? 1 : 0 })
    }
}
