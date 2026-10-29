import Foundation

/// Copies audio into `iPod_Control/Music/Fnn/` under a random four-character name, as iTunes does.
nonisolated struct IPodMusicFileCopier {
    private static let nameCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private static let fallbackFolder = "F00"

    let volumeURL: URL

    private var musicURL: URL {
        volumeURL.appending(path: "iPod_Control/Music", directoryHint: .isDirectory)
    }

    func copy(_ sourceURL: URL) throws -> IPodMusicFile {
        let folder = try musicFolders().randomElement() ?? createFallbackFolder()
        let folderURL = musicURL.appending(path: folder, directoryHint: .isDirectory)
        let name = uniqueName(in: folderURL, pathExtension: sourceURL.pathExtension.lowercased())
        let destination = folderURL.appending(path: name, directoryHint: .notDirectory)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return IPodMusicFile(location: ":iPod_Control:Music:\(folder):\(name)", url: destination)
    }

    private func musicFolders() throws -> [String] {
        guard FileManager.default.fileExists(atPath: musicURL.path(percentEncoded: false)) else { return [] }
        return try FileManager.default.contentsOfDirectory(atPath: musicURL.path(percentEncoded: false))
            .filter { $0.count == 3 && $0.hasPrefix("F") && Int($0.dropFirst()) != nil }
    }

    private func createFallbackFolder() throws -> String {
        let url = musicURL.appending(path: Self.fallbackFolder, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return Self.fallbackFolder
    }

    private func uniqueName(in folderURL: URL, pathExtension: String) -> String {
        while true {
            let stem = String((0..<4).map { _ in Self.nameCharacters.randomElement()! })
            let name = "\(stem).\(pathExtension)"
            let path = folderURL.appending(path: name).path(percentEncoded: false)
            if !FileManager.default.fileExists(atPath: path) { return name }
        }
    }
}
