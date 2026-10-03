import Foundation

/// Carries out a `PlayerSyncPlan`. Every finished step is kept and recorded, even when a later one fails
/// or the sync is cancelled, because each song is its own file.
nonisolated struct PlayerTrackSyncer {
    let device: AudioPlayerDevice

    private var files: PlayerFileOperations { PlayerFileOperations(device: device) }

    @concurrent
    func sync(_ plan: PlayerSyncPlan,
              progress: @escaping @Sendable (SyncProgress) async -> Void = { _ in }) async throws -> SyncSummary {
        try ensureFreeSpace(for: plan.totals)
        var state = PlayerSyncState(manifest: device.controlFiles.manifest(),
                                    summary: SyncSummary(skipped: plan.totals.alreadyOnDeviceCount - plan.moves.count,
                                                         deviceKind: "player", suggestsEject: device.isEjectable))
        defer { finish(state) }
        remove(plan.removals, state: &state)
        removeSidecars(plan.sidecarRemovals, state: &state)
        try move(plan.moves, state: &state)
        try await write(plan, state: &state, progress: progress)
        if !state.summary.wasCancelled {
            if let playlists = plan.playlists {
                try write(playlists, removing: plan.stalePlaylistPaths, state: &state)
                state.summary.syncedPlaylistCount = plan.playlistChangeCount
            }
            await copySidecars(plan.sidecarCopies, state: &state)
        }
        await progress(SyncProgress(completed: plan.writes.count, total: plan.writes.count, currentTitle: nil))
        return state.summary
    }

    private func finish(_ state: PlayerSyncState) {
        try? device.controlFiles.save(state.manifest)
        files.pruneEmptyFolders(containing: state.vacatedPaths)
    }

    private func remove(_ removals: [PlayerFileRemoval], state: inout PlayerSyncState) {
        for removal in removals {
            files.remove(removal.path)
            state.manifest.entries[removal.sourcePath] = nil
            state.vacatedPaths.append(removal.path)
        }
        state.summary.removed = removals.count
    }

    private func move(_ moves: [PlayerFileMove], state: inout PlayerSyncState) throws {
        for move in moves {
            try files.move(from: move.from, to: move.to)
            let source = state.manifest.entries[move.sourcePath]?.source
            state.manifest.entries[move.sourcePath] = PlayerManifestEntry(path: move.to, source: source)
            state.vacatedPaths.append(move.from)
            state.summary.updated += 1
        }
    }

    /// Updates first, then new songs, stopping between files when cancelled.
    private func write(_ plan: PlayerSyncPlan, state: inout PlayerSyncState,
                       progress: @Sendable (SyncProgress) async -> Void) async throws {
        for (index, copy) in plan.writes.enumerated() {
            await progress(SyncProgress(completed: index, total: plan.writes.count, currentTitle: copy.request.draft.title))
            guard !Task.isCancelled else {
                state.summary.wasCancelled = true
                return
            }
            try await files.copy(copy.request, to: copy.destination)
            if let old = copy.replacing {
                files.remove(old)
                state.vacatedPaths.append(old)
            }
            state.manifest.entries[copy.request.sourcePath] = PlayerManifestEntry(path: copy.destination,
                                                                                 source: copy.request.source)
            if index < plan.updates.count { state.summary.updated += 1 } else { state.summary.added += 1 }
        }
    }

    private func write(_ playlists: [PlayerPlaylistFile], removing stale: [String],
                       state: inout PlayerSyncState) throws {
        for playlist in playlists {
            try files.write(playlist.contents, to: playlist.path)
        }
        stale.forEach(files.remove)
        state.manifest.playlistPaths = Set(playlists.map(\.path))
    }

    private func removeSidecars(_ paths: [String], state: inout PlayerSyncState) {
        for path in paths {
            files.remove(path)
            state.manifest.sidecars[path] = nil
            state.manifest.coverPixelLimits[path] = nil
            state.vacatedPaths.append(path)
        }
        state.summary.sidecarChangeCount += paths.count
    }

    /// Covers are scaled down before they replace anything. A cover or lyric file that disappeared from the
    /// library since planning, or an image that can't be read, is skipped rather than failing the sync.
    private func copySidecars(_ copies: [PlayerSidecarCopy], state: inout PlayerSyncState) async {
        for copy in copies {
            let copied = try? await files.copy(copy.source.url, to: copy.destination) { staged in
                if let limit = copy.pixelLimit { try CoverResizer.fit(imageAt: staged, within: limit) }
            }
            guard copied != nil else { continue }
            state.manifest.sidecars[copy.destination] = copy.source
            state.manifest.coverPixelLimits[copy.destination] = copy.pixelLimit
            state.summary.sidecarChangeCount += 1
        }
    }

    private func ensureFreeSpace(for totals: SyncPlanTotals) throws {
        let values = try device.volumeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let available = Int64(values.volumeAvailableCapacity ?? 0)
        guard totals.fits(in: available) else {
            throw PlayerSyncError.insufficientSpace(required: totals.requiredBytes,
                                                    available: available + totals.removeBytes)
        }
    }
}
