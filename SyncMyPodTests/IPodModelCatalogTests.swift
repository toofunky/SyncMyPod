import Foundation
import Testing
@testable import SyncMyPod

struct IPodModelCatalogTests {
    @Test(arguments: [
        ("MA146", IPodGeneration.video5G),
        ("xA147", .video5G),
        ("MA450LL/A", .video5_5G),
        ("xB029", .classic6G),
        ("MB565", .classic6_5G),
        ("MC297", .classic7G),
        ("xD480", .nano7G),
        ("MKN52LL/A", .nano7G)
    ])
    func mapsModelNumberToGeneration(modelNumber: String, generation: IPodGeneration) {
        #expect(IPodModelCatalog.generation(forModelNumber: modelNumber) == generation)
    }

    @Test(arguments: ["", "M", "MA999", "MC031"])
    func returnsNilForUnsupportedModels(modelNumber: String) {
        #expect(IPodModelCatalog.generation(forModelNumber: modelNumber) == nil)
    }

    @Test func signsDatabasesByFamily() {
        let hash58 = IPodGeneration.allCases.filter { $0.databaseSigning == .hash58 }
        #expect(hash58 == [.classic6G, .classic6_5G, .classic7G])
        #expect(IPodGeneration.allCases.filter { $0.databaseSigning == .hashAB } == [.nano7G])
    }

    @Test(arguments: [
        ("8K203FK59ZU", "MC297"),
        ("8K2000009ZS", "MC293"),
        ("XX00000A2C5", "MB562")
    ])
    func mapsSerialSuffixToModelNumber(serialNumber: String, modelNumber: String) {
        #expect(IPodModelCatalog.modelNumber(forSerialNumber: serialNumber) == modelNumber)
    }

    @Test(arguments: [
        ("1.1.2", IPodGeneration.classic6G),
        ("2.0", .classic6_5G),
        ("2.0.1", .classic6_5G),
        ("2.0.2", .classic7G),
        ("2.0.4", .classic7G)
    ])
    func infersClassicGenerationFromFirmware(version: String, generation: IPodGeneration) {
        #expect(IPodModelCatalog.classicGeneration(forFirmwareVersion: version) == generation)
    }

    @Test func decidesDatabaseSigningFromProductID() {
        #expect(IPodModelCatalog.databaseSigning(forProductID: 0x1209) == .unsigned)
        #expect(IPodModelCatalog.databaseSigning(forProductID: 0x1261) == .hash58)
        #expect(IPodModelCatalog.databaseSigning(forProductID: 0x1267) == .hashAB)
        #expect(IPodModelCatalog.databaseSigning(forProductID: 0x1234) == nil)
    }

    @Test func videoIPodWithEmptySysInfoDoesNotRequireHash() {
        let device = IPodDevice(id: "1", volumeURL: URL(filePath: "/Volumes/iPod"), volumeName: "iPod",
                                capacityBytes: nil, availableBytes: nil, sysInfo: .empty,
                                usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                             serialNumber: "000A27001234ABCD",
                                                             vendorID: 0x05AC, productID: 0x1209))
        #expect(device.generation == nil)
        #expect(device.databaseSigning == .unsigned)
    }

    @Test func identifiesNano7GFromProductIDAlone() {
        let device = IPodDevice(id: "1", volumeURL: URL(filePath: "/Volumes/NANO"), volumeName: "NANO",
                                capacityBytes: nil, availableBytes: nil, sysInfo: .empty,
                                usbIdentity: IPodUSBIdentity(vendorString: "Apple", productString: "iPod",
                                                             serialNumber: "000A27002138B5C1",
                                                             vendorID: 0x05AC, productID: 0x1267))
        #expect(device.generation == .nano7G)
        #expect(device.databaseSigning == .hashAB)
        #expect(throws: IPodSyncError.missingLibraryCommands) {
            _ = try IPodTrackSyncer(device: device)
        }
    }

    @Test func namesFamilyFromProductID() {
        #expect(IPodModelCatalog.familyName(forProductID: 0x1209) == "iPod (5th or 5.5th Generation)")
        #expect(IPodModelCatalog.familyName(forProductID: 0x1261) == "iPod classic")
        #expect(IPodModelCatalog.familyName(forProductID: 0x1234) == nil)
    }
}
