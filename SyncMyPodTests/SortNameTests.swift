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

    @Test func comparatorIgnoresArticlesInBothOrders() {
        let names = ["Travis", "The Killers", "Arcade Fire", "A Perfect Circle"]
        #expect(names.sorted(using: SortNameComparator()) == ["Arcade Fire", "The Killers", "A Perfect Circle", "Travis"])
        #expect(names.sorted(using: SortNameComparator(order: .reverse))
            == ["Travis", "A Perfect Circle", "The Killers", "Arcade Fire"])
    }
}
