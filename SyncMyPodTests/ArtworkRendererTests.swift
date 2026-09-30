import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct ArtworkRendererTests {
    private let red = TestImage.color(1, 0, 0)
    private let blue = TestImage.color(0, 0, 1)
    private let small = ArtworkFormat.videoIPod[0]
    private let large = ArtworkFormat.videoIPod[1]

    private func pixel(_ artwork: RenderedArtwork, x: Int, y: Int) -> UInt16 {
        artwork.pixels.read(UInt16.self, at: (y * artwork.format.width + x) * 2)
    }

    @Test(arguments: [(UInt8(255), UInt8(0), UInt8(0), UInt16(0xF800)), (0, 255, 0, 0x07E0),
                      (0, 0, 255, 0x001F), (255, 255, 255, 0xFFFF), (0, 0, 0, 0x0000)])
    func packsPrimaryColors(red: UInt8, green: UInt8, blue: UInt8, expected: UInt16) {
        #expect(RGB565Packer.pack(red: red, green: green, blue: blue) == expected)
    }

    @Test func storesPixelsLittleEndian() {
        let bytes: [UInt8] = [255, 0, 0, 0]
        let packed = bytes.withUnsafeBytes { RGB565Packer.pack(rgbx: $0, pixelCount: 1) }
        #expect(packed == Data([0x00, 0xF8]))
    }

    @Test func scalesLargeSquareCoverToFillTheFormat() throws {
        let artwork = try #require(ArtworkRenderer.render(TestImage.make(width: 1_400, height: 1_400, top: red),
                                                          as: large))
        #expect(artwork.pixels.count == 80_000)
        #expect(artwork.horizontalPadding == 0 && artwork.verticalPadding == 0)
        #expect(pixel(artwork, x: 0, y: 0) == 0xF800)
        #expect(pixel(artwork, x: 199, y: 199) == 0xF800)
    }

    @Test func upscalesSmallCovers() throws {
        let artwork = try #require(ArtworkRenderer.render(TestImage.make(width: 50, height: 50, top: blue), as: large))
        #expect(artwork.pixels.count == 80_000)
        #expect(pixel(artwork, x: 100, y: 100) == 0x001F)
    }

    @Test func keepsImageUpright() throws {
        let image = TestImage.make(width: 300, height: 300, top: red, bottom: blue)
        let artwork = try #require(ArtworkRenderer.render(image, as: small))
        #expect(pixel(artwork, x: 50, y: 5) == 0xF800)
        #expect(pixel(artwork, x: 50, y: 94) == 0x001F)
    }

    @Test func letterboxesWideCoversOnWhite() throws {
        let artwork = try #require(ArtworkRenderer.render(TestImage.make(width: 400, height: 200, top: red), as: small))
        #expect(artwork.horizontalPadding == 0 && artwork.verticalPadding == 25)
        #expect(pixel(artwork, x: 50, y: 10) == 0xFFFF)
        #expect(pixel(artwork, x: 50, y: 50) == 0xF800)
        #expect(pixel(artwork, x: 50, y: 90) == 0xFFFF)
    }

    @Test func pillarboxesTallCovers() throws {
        let artwork = try #require(ArtworkRenderer.render(TestImage.make(width: 100, height: 400, top: red), as: small))
        #expect(artwork.horizontalPadding == 37 && artwork.verticalPadding == 0)
        #expect(pixel(artwork, x: 5, y: 50) == 0xFFFF)
        #expect(pixel(artwork, x: 50, y: 50) == 0xF800)
    }

    @Test func padsRowsToTheFormatsRowWidth() throws {
        let format = ArtworkFormat(id: 1016, width: 57, height: 57, rowPixels: 58)
        let image = TestImage.make(width: 57, height: 57, top: TestImage.color(1, 0, 0))
        let rendered = try #require(ArtworkRenderer.render(image, as: format))
        #expect(rendered.pixels.count == 58 * 57 * 2)
        #expect(rendered.pixels.read(UInt16.self, at: 56 * 2) == 0xF800)
        #expect(rendered.pixels.read(UInt16.self, at: 57 * 2) == 0)
        #expect(rendered.pixels.read(UInt16.self, at: 58 * 2) == 0xF800)
    }
}
