import Testing
@testable import SyncMyPod

struct IPodModelCatalogTests {
    @Test(arguments: [
        ("MA146", IPodGeneration.video5G),
        ("xA147", .video5G),
        ("MA450LL/A", .video5_5G),
        ("xB029", .classic6G),
        ("MB565", .classic6_5G),
        ("MC297", .classic7G)
    ])
    func mapsModelNumberToGeneration(modelNumber: String, generation: IPodGeneration) {
        #expect(IPodModelCatalog.generation(forModelNumber: modelNumber) == generation)
    }

    @Test(arguments: ["", "M", "MA999", "MC031"])
    func returnsNilForUnsupportedModels(modelNumber: String) {
        #expect(IPodModelCatalog.generation(forModelNumber: modelNumber) == nil)
    }

    @Test func onlyClassicModelsRequireDatabaseHash() {
        let hashed = IPodGeneration.allCases.filter(\.requiresDatabaseHash)
        #expect(hashed == [.classic6G, .classic6_5G, .classic7G])
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
}
