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
}
