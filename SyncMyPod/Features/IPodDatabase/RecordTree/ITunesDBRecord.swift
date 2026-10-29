import Foundation

/// A lossless view of one iTunesDB record. Serializing recomputes the 0x08 length/count
/// field, so edited children propagate their size up to `mhbd`.
nonisolated struct ITunesDBRecord: Equatable, Sendable {
    var header: Data
    var body: ITunesDBRecordBody

    var tag: String { String(decoding: header.prefix(4), as: UTF8.self) }

    var children: [ITunesDBRecord] {
        get {
            switch body {
            case .container(let children, _), .list(let children): children
            case .opaque: []
            }
        }
        set {
            switch body {
            case .container(_, let trailer): body = .container(newValue, trailer: trailer)
            case .list: body = .list(newValue)
            case .opaque: preconditionFailure("\(tag) records cannot hold children")
            }
        }
    }

    func serialized() -> Data {
        var output = Data()
        append(to: &output)
        return output
    }

    private func append(to output: inout Data) {
        let start = output.count
        output.append(header)
        switch body {
        case .opaque(let payload):
            output.append(payload)
        case .container(let children, let trailer):
            children.forEach { $0.append(to: &output) }
            output.append(trailer)
        case .list(let children):
            output.write(UInt32(children.count), at: start + 0x08)
            children.forEach { $0.append(to: &output) }
            return
        }
        output.write(UInt32(output.count - start), at: start + 0x08)
    }
}
