import Foundation

/// Reads an RSS 2.0 podcast feed with Apple's `itunes:` tags, the format nearly every podcast host publishes.
/// Elements outside RSS and the iTunes namespace are keyed by namespace, so `media:title` can't replace `title`.
nonisolated final class PodcastFeedParser: NSObject, XMLParserDelegate {
    private static let iTunesNamespace = "http://www.itunes.com/dtds/podcast-1.0.dtd"

    private var feed = PodcastFeed()
    private var path: [String] = []
    private var item: [String: String]?
    private var text = ""
    private var sawChannel = false

    static func parse(_ data: Data) throws -> PodcastFeed {
        let delegate = PodcastFeedParser()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        guard parser.parse(), delegate.sawChannel, !delegate.feed.title.isEmpty else {
            throw PodcastFeedError.notAFeed
        }
        return delegate.feed
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes: [String: String] = [:]) {
        let key = Self.key(elementName, namespaceURI)
        let parent = path.last
        path.append(key)
        text = ""
        switch key {
        case "channel": sawChannel = true
        case "item": item = [:]
        case "enclosure" where item?["enclosure"] == nil:
            item?["enclosure"] = attributes["url"]
            item?["enclosureLength"] = attributes["length"]
            item?["enclosureType"] = attributes["type"]
        case "itunes:image" where parent == "channel":
            if let href = attributes["href"] { feed.artworkURL = URL(string: href) }
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        let key = path.removeLast()
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
        if key == "item" {
            if let item, let episode = Self.episode(from: item) { feed.episodes.append(episode) }
            item = nil
        } else if item != nil, path.last == "item", !value.isEmpty, item?[key] == nil {
            item?[key] = value
        } else if item == nil, !value.isEmpty {
            applyChannelValue(value, for: key)
        }
    }

    /// `path.last` is the enclosing element, the current one having been popped.
    private func applyChannelValue(_ value: String, for key: String) {
        switch (key, path.last) {
        case ("title", "channel"): feed.title = value
        case ("itunes:author", "channel"): feed.author = value
        case ("description", "channel"): feed.summary = Self.plainText(value)
        case ("itunes:summary", "channel") where feed.summary.isEmpty: feed.summary = Self.plainText(value)
        case ("url", "image") where feed.artworkURL == nil: feed.artworkURL = URL(string: value)
        default: break
        }
    }

    private static func episode(from item: [String: String]) -> PodcastFeedEpisode? {
        guard let enclosure = item["enclosure"].flatMap(URL.init(string:)) else { return nil }
        return PodcastFeedEpisode(
            guid: item["guid"] ?? enclosure.absoluteString,
            title: item["title"] ?? item["itunes:title"] ?? enclosure.lastPathComponent,
            summary: plainText(item["description"] ?? item["itunes:summary"] ?? ""),
            publishedAt: item["pubDate"].flatMap(PodcastDateParser.date(from:)),
            duration: item["itunes:duration"].flatMap(PodcastDuration.seconds(from:)),
            enclosureURL: enclosure,
            enclosureType: item["enclosureType"],
            byteCount: item["enclosureLength"].flatMap { Int64($0) }.flatMap { $0 > 0 ? $0 : nil },
            episodeNumber: item["itunes:episode"].flatMap { Int($0) },
            seasonNumber: item["itunes:season"].flatMap { Int($0) })
    }

    private static func key(_ name: String, _ namespace: String?) -> String {
        switch namespace {
        case nil, "": name
        case iTunesNamespace: "itunes:\(name)"
        case let namespace?: "\(namespace)|\(name)"
        }
    }

    /// Feeds usually describe shows and episodes in HTML; the app shows them as plain text.
    static func plainText(_ html: String) -> String {
        html.replacing(/<(br|\/p|\/div|\/li)\b[^>]*>/.ignoresCase(), with: "\n")
            .replacing(/<[^>]+>/, with: "")
            .replacing("&nbsp;", with: " ").replacing("&amp;", with: "&")
            .replacing(/[ \t]+/, with: " ")
            .replacing(/\ *\n\s*/, with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
