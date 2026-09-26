import Foundation

/// An MP4 box held in memory. Containers keep parsed `children`; everything else keeps its raw `payload`.
nonisolated struct MP4Box: Equatable, Sendable {
    static let headerSize = 8

    var type: FourCC
    /// Bytes before the children of a container, such as the version and flags of a full `meta` box.
    var prefix = Data()
    var payload = Data()
    var children: [MP4Box]?

    var size: Int {
        Self.headerSize + prefix.count + (children?.reduce(0) { $0 + $1.size } ?? payload.count)
    }

    func serialized() -> Data {
        var data = Data(capacity: size)
        append(to: &data)
        return data
    }

    func append(to data: inout Data) {
        data.appendBigEndian(UInt32(size))
        data.appendBigEndian(type.rawValue)
        data.append(prefix)
        guard let children else { return data.append(payload) }
        children.forEach { $0.append(to: &data) }
    }

    func firstChild(_ type: FourCC) -> MP4Box? {
        children?.first { $0.type == type }
    }

    /// Runs `body` on the first child of `type`, adding `make()` first when there is none.
    mutating func withChild<Result>(_ type: FourCC, orMake make: () -> MP4Box,
                                    _ body: (inout MP4Box) throws -> Result) rethrows -> Result {
        var children = self.children ?? []
        let index = children.firstIndex { $0.type == type } ?? {
            children.append(make())
            return children.count - 1
        }()
        defer { self.children = children }
        return try body(&children[index])
    }

    static func free(size: Int) -> MP4Box {
        MP4Box(type: .free, payload: Data(count: size - headerSize))
    }
}
