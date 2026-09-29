import Foundation

/// Moves a generated `iTunes Library.itlp` onto the nano, keeping a backup of each file it replaces.
nonisolated struct NanoLibraryInstaller {
    static let backupSuffix = ".syncmypod-backup"
    private static let stagingSuffix = ".syncmypod-new"

    let volumeURL: URL

    var folderURL: URL {
        volumeURL.appending(path: "iPod_Control/iTunes/iTunes Library.itlp", directoryHint: .isDirectory)
    }

    /// Copies every staged file next to its target first, so a failed copy leaves the old library intact, then
    /// swaps them in with the checksum book last. The device's Genius data is kept if it has any.
    func install(from staged: URL) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let names = try fileNames(in: staged)
        for name in names {
            let incoming = folderURL.appending(path: name + Self.stagingSuffix)
            try? manager.removeItem(at: incoming)
            try manager.copyItem(at: staged.appending(path: name), to: incoming)
        }
        for name in names {
            try replace(name)
        }
    }

    private func fileNames(in staged: URL) throws -> [String] {
        let genius = NanoLibraryFile.genius.fileName
        let keepsGenius = FileManager.default.fileExists(atPath: folderURL.appending(path: genius).path(percentEncoded: false))
        let databases = NanoLibraryFile.allCases.map(\.fileName).filter { !(keepsGenius && $0 == genius) }
        return databases + [LocationsChecksumBook.fileName]
    }

    private func replace(_ name: String) throws {
        let manager = FileManager.default
        let target = folderURL.appending(path: name)
        let backup = folderURL.appending(path: name + Self.backupSuffix)
        if manager.fileExists(atPath: target.path(percentEncoded: false)) {
            try? manager.removeItem(at: backup)
            try manager.moveItem(at: target, to: backup)
        }
        try manager.moveItem(at: folderURL.appending(path: name + Self.stagingSuffix), to: target)
    }
}
