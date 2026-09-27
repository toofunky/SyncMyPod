import Foundation
import Testing
@testable import SyncMyPod

struct SortNameTests {
    @Test(arguments: [
        ("The Killers", "Killers"),
        ("the killers", "killers"),
        ("A Tribe Called Quest", "Tribe Called Quest"),
        ("An Horse", "Horse"),
        ("The", "The"),
        ("A", "A"),
        ("Theory of a Deadman", "Theory of a Deadman"),
        ("Anthrax", "Anthrax"),
        ("ABBA", "ABBA"),
        ("The The", "The"),
    ])
    func stripsLeadingArticle(_ name: String, _ expected: String) {
        #expect(name.sortName == expected)
    }

    @Test(arguments: [
        ("The Killers", nil, "Killers"),
        ("The Killers", "", "Killers"),
        ("David Bowie", "Bowie, David", "Bowie, David"),
        ("Modest Mouse", nil, "Modest Mouse"),
    ] as [(String, String?, String)])
    func sortTagOverridesGeneratedName(_ name: String, _ tag: String?, _ expected: String) {
        #expect(name.sortName(tagged: tag) == expected)
    }

    @Test(arguments: [
        ("The Killers", nil, "Killers"),
        ("Modest Mouse", nil, ""),
        ("Modest Mouse", "", ""),
        ("David Bowie", "Bowie, David", "Bowie, David"),
        ("The Beatles", "Beatles, The", "Beatles, The"),
        ("", nil, ""),
    ] as [(String, String?, String)])
    func iPodSortValueIsGeneratedOnlyForLeadingArticles(_ name: String, _ tag: String?, _ expected: String) {
        #expect(name.iPodSortValue(tagged: tag) == expected)
    }
}
