import Testing
@testable import SyncMyPod

@MainActor
struct DeviceSyncSettingsTests {
    @Test func newDeviceSyncsAllSongsAndNothingElse() {
        let selection = DeviceSyncSettings(deviceID: "new").selection
        #expect([selection.songs, selection.playlistScope, selection.podcastScope, selection.audiobookScope]
            == [.all, .none, .none, .none])
    }

    @Test func oldAllSongsChoiceSyncsEverything() {
        let selection = oldSettings().selection
        #expect([selection.songs, selection.playlistScope, selection.podcastScope, selection.audiobookScope]
            == [.all, .all, .all, .all])
    }

    @Test func oldCustomChoiceSyncsWhatWasSelected() {
        let settings = oldSettings()
        settings.modeRawValue = "custom"
        let selection = settings.selection
        #expect([selection.songs, selection.playlistScope, selection.podcastScope, selection.audiobookScope]
            == [.selected, .selected, .selected, .selected])
    }

    @Test func chosenScopeWinsOverTheOldChoice() {
        let settings = oldSettings()
        settings.modeRawValue = "custom"
        settings.podcastScope = .none
        #expect(settings.selection.podcastScope == .none && settings.selection.songs == .selected)
    }

    /// Settings saved before per-tab scopes hold `NULL` for every scope.
    private func oldSettings() -> DeviceSyncSettings {
        let settings = DeviceSyncSettings(deviceID: "old")
        settings.playlistScopeValue = nil
        settings.podcastScopeValue = nil
        settings.audiobookScopeValue = nil
        return settings
    }
}
