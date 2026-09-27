import Foundation
import Testing
@testable import SyncMyPod

struct TrackSearchQueryTests {
    @Test func blankTextMatchesEverything() {
        #expect(TrackSearchQuery("").matches("Vogue"))
        #expect(TrackSearchQuery("   ").matches("Vogue"))
    }

    @Test func matchesAnyFieldIgnoringCaseAndDiacritics() {
        #expect(TrackSearchQuery("madonna").matches("Vogue", "", "Madonna", "The Immaculate Collection"))
        #expect(TrackSearchQuery("beyonce").matches("Halo", "Beyoncé"))
        #expect(!TrackSearchQuery("madonna").matches("Like a Prayer", "", "", ""))
    }

    @Test func matchesTheWholePhraseOnly() {
        let query = TrackSearchQuery(" no string ")
        #expect(query.matches("No String Attached"))
        #expect(!query.matches("String Theory", "No Doubt"))
        #expect(!query.matches("No Air", "String Cheese Incident"))
    }
}
