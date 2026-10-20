import SwiftData
import SwiftUI

struct AudiobookHeaderView: View {
    let book: Audiobook

    @Environment(MusicPlayerModel.self) private var player: MusicPlayerModel?

    private static let artworkSize: CGFloat = 96

    var body: some View {
        HStack(alignment: .top) {
            AudiobookArtworkView(book: book, size: Self.artworkSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.title2.bold())
                    .lineLimit(2)
                if !book.author.isEmpty {
                    Text(book.author)
                        .foregroundStyle(.secondary)
                }
                details
            }
            Spacer(minLength: 0)
            playButton
        }
        .padding()
    }

    /// Plays or pauses the book, carrying on from where it was left.
    private var playButton: some View {
        let isPlaying = player?.isCurrent(book) == true && player?.isPlaying == true
        return Button(isPlaying ? "Pause" : (book.isStarted ? "Resume" : "Play"),
                      systemImage: isPlaying ? "pause.fill" : "play.fill") {
            isPlaying ? player?.togglePlayPause() : player?.play(book)
        }
        .disabled(player == nil)
        .contentTransition(.symbolEffect(.replace))
    }

    private var details: some View {
        HStack(spacing: 4) {
            Text("^[\(book.files.count) file](inflect: true)")
            Text("·")
            Text(book.progressText)
            Text("·")
            Text(book.byteCount.formatted(.byteCount(style: .file)))
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
}

#if DEBUG
#Preview {
    AudiobookHeaderView(book: .preview)
        .environment(MusicPlayerModel())
        .modelContainer(.preview)
        .frame(width: 600)
}
#endif
