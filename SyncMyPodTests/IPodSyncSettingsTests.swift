import Testing
@testable import SyncMyPod

@MainActor
struct IPodSyncSettingsTests {
    @Test func oldAllSongsChoiceSyncsEverything() {
        let selection = IPodSyncSettings(deviceID: "old").selection
        #expect([selection.songs, selection.playlistScope, selection.podcastScope, selection.audiobookScope]
            == [.all, .all, .all, .all])
    }

    @Test func oldCustomChoiceSyncsWhatWasSelected() {
        let settings = IPodSyncSettings(deviceID: "old")
        settings.modeRawValue = "custom"
        let selection = settings.selection
        #expect([selection.songs, selection.playlistScope, selection.podcastScope, selection.audiobookScope]
            == [.selected, .selected, .selected, .selected])
    }

    @Test func chosenScopeWinsOverTheOldChoice() {
        let settings = IPodSyncSettings(deviceID: "old")
        settings.modeRawValue = "custom"
        settings.podcastScope = .none
        #expect(settings.selection.podcastScope == .none && settings.selection.songs == .selected)
    }
}
