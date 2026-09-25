import Foundation
import Testing
@testable import SyncMyPod

struct TagNumberPairTests {
    @Test func parsesBigEndianNumberAndCount() {
        let pair = TagNumberPair(atomData: Data([0, 0, 0x01, 0x02, 0, 12, 0, 0]))
        #expect(pair == TagNumberPair(number: 258, count: 12))
    }

    @Test func ignoresTruncatedData() {
        #expect(TagNumberPair(atomData: Data([0, 0, 1])) == TagNumberPair())
    }
}
