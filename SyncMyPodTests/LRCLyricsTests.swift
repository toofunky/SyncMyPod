import Testing
@testable import SyncMyPod

struct LRCLyricsTests {
    @Test func dropsHeadersAndTimesKeepingStanzaBreaks() {
        let lrc = "[ar:Coldplay]\r\n[ti:Clocks]\r\n[00:01.00]\r\n[00:12.34]Lights go out\r\n"
            + "[00:15.00][01:40.00]And I can't be saved\r\n[00:18.00]\r\n[00:20.5]Tides that I tried\r\n"
        #expect(LRCLyrics.plainText(from: lrc) == "Lights go out\nAnd I can't be saved\n\nTides that I tried")
    }

    @Test func dropsEnhancedWordTimes() {
        #expect(LRCLyrics.plainText(from: "[00:12.34]<00:12.34>Lights <00:13.00>go <00:13.50>out")
                == "Lights go out")
    }

    @Test func keepsUntimedTextAndBracketedWords() {
        #expect(LRCLyrics.plainText(from: "Lights go out\n[Chorus]\nAnd I can't be saved")
                == "Lights go out\n[Chorus]\nAnd I can't be saved")
    }

    @Test func headersAloneLeaveNothing() {
        #expect(LRCLyrics.plainText(from: "[ar:Coldplay]\n[length: 05:07]\n\n").isEmpty)
    }
}
