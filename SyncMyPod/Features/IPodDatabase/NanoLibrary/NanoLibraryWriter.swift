import Foundation

/// Generates the nano's `iTunes Library.itlp` files from a finished iTunesDB, the way iTunes does: base tables,
/// then the device's own post-process SQL, then the signed Locations checksum book.
nonisolated struct NanoLibraryWriter: Sendable {
    let commands: NanoPostProcessCommands
    let signer: HashAB

    /// Writes every file into `directory`, replacing what's there. `previous` is the device's current
    /// `iTunes Library.itlp` folder, whose play counts, ratings and other device-owned rows are carried over.
    func write(_ snapshot: NanoLibrarySnapshot, to directory: URL, carryingOverFrom previous: URL?) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let rows = NanoLibraryRows(catalog: NanoLibraryCatalog(snapshot: snapshot))
        try create(.library, in: directory, rows: rows.libraryTables(geniusCUID: nil))
        try create(.locations, in: directory, rows: rows.locations())
        try create(.dynamic, in: directory, rows: [rows.itemStats(), rows.containerViewStates()])
        try create(.extras, in: directory, rows: [])
        try create(.genius, in: directory, rows: [])
        try finish(in: directory, carryingOverFrom: previous)
        let locations = try Data(contentsOf: directory.appending(path: NanoLibraryFile.locations.fileName))
        try LocationsChecksumBook.make(for: locations, signer: signer)
            .write(to: directory.appending(path: LocationsChecksumBook.fileName), options: .atomic)
    }

    private func create(_ file: NanoLibraryFile, in directory: URL, rows: [SQLiteTableRows]) throws {
        let connection = try SQLiteConnection(creatingAt: directory.appending(path: file.fileName))
        try connection.execute(file.creationSQL)
        try connection.execute("BEGIN")
        try rows.forEach { try $0.insert(into: connection) }
        try connection.execute("COMMIT")
    }

    /// Runs the carry-over and the device's commands with every file attached to Library.itdb.
    private func finish(in directory: URL, carryingOverFrom previous: URL?) throws {
        let connection = try SQLiteConnection(openingAt: directory.appending(path: NanoLibraryFile.library.fileName))
        for file in NanoLibraryFile.allCases where file != .library {
            let url = directory.appending(path: file.fileName)
            try connection.execute("ATTACH DATABASE '\(NanoLibraryCarryOver.escaped(url))' AS \(file.alias)")
        }
        if let previous { try NanoLibraryCarryOver.apply(from: previous, into: connection) }
        try connection.execute("BEGIN")
        for statement in commands.statements {
            try? connection.execute(statement)
        }
        try connection.execute("COMMIT")
        try connection.execute("PRAGMA user_version = \(commands.version)")
    }
}
