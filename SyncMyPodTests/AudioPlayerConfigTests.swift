import Foundation
import Testing
@testable import SyncMyPod

struct AudioPlayerConfigTests {
    @Test func blankFoldersFallBackToTheRoot() {
        let config = AudioPlayerConfig(name: "Player", rootPath: "SD Card", musicFolder: "", playlistFolder: "  ")
        #expect(config.musicPath == "SD Card")
        #expect(config.playlistPath == "SD Card")
    }

    @Test func foldersAreCleanedAndCannotLeaveTheVolume() {
        let config = AudioPlayerConfig(name: "Player", rootPath: "/", musicFolder: " /Media//Music/ ",
                                       playlistFolder: "../../Lists")
        #expect(config.musicPath == "Media/Music")
        #expect(config.playlistPath == "Lists")
    }

    @Test func blankNamesTakeTheVolumeName() {
        let config = AudioPlayerConfig(name: "  ", rootPath: "").cleaned(defaultName: "FIIO")
        #expect(config.name == "FIIO")
    }

    @Test func preservingOptionsAreOffByDefault() {
        let config = AudioPlayerConfig(name: "Player", rootPath: "")
        #expect(!config.preserveTrackSorting)
        #expect(!config.preserveAlbumArtist)
        #expect(!config.copyCovers)
        #expect(!config.copyLyricFiles)
    }

    @Test func configsSavedWithoutTheOptionsStillLoad() throws {
        let older = ["id": "A", "name": "FiiO", "rootPath": "", "musicFolder": "Music"]
        let data = try PropertyListSerialization.data(fromPropertyList: older, format: .binary, options: 0)
        let config = try PropertyListDecoder().decode(AudioPlayerConfig.self, from: data)
        #expect(config.musicPath == "Music")
        #expect(!config.preserveTrackSorting && !config.preserveAlbumArtist)
    }

    @Test func savedPlayersAreRecognizedWhenTheirVolumeMounts() async throws {
        let config = AudioPlayerConfig(name: "FiiO", rootPath: "", musicFolder: "Music")
        let volume = try TemporaryPlayerVolume(config: config)
        let device = await ConnectedDevice.scan(volumeAt: volume.volumeURL)
        #expect(device?.id == config.id)
        #expect(device?.displayName == "FiiO")
        #expect(device?.kindName == "player")
    }

    @Test func foldersWithoutAConfigAreIgnored() async throws {
        let volume = try TemporaryPlayerVolume(config: AudioPlayerConfig(name: "FiiO", rootPath: ""))
        try AudioPlayerControlFiles(volumeURL: volume.volumeURL).removeConfig()
        #expect(await ConnectedDevice.scan(volumeAt: volume.volumeURL) == nil)
    }

    @Test func onlyPlayersRootedAtTheirVolumeCanBeEjected() {
        let volume = URL(filePath: "/Volumes/Secondary")
        let drive = AudioPlayerDevice(volumeURL: volume, volumeName: "FIIO", capacityBytes: nil, availableBytes: nil,
                                      config: AudioPlayerConfig(name: "FiiO", rootPath: ""))
        let folder = AudioPlayerDevice(volumeURL: volume, volumeName: "Secondary", capacityBytes: nil,
                                       availableBytes: nil,
                                       config: AudioPlayerConfig(name: "Sandbox",
                                                                 rootPath: "Users/michael/Music/DAPConductorSandbox/Device"))
        #expect(ConnectedDevice.audioPlayer(drive).isEjectable)
        #expect(!ConnectedDevice.audioPlayer(folder).isEjectable)
    }

    @Test func deviceKindTitlesCapitalizeWordsButNotIPod() {
        #expect("player".deviceKindTitle == "Player")
        #expect("iPod".deviceKindTitle == "iPod")
    }
}
