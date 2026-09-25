/*
 Swift port of libgpod's src/itdb_hash58.c.

 Copyright (C) 2007 Christophe Fergeau <teuf@gnome.org>
 The code in this file is heavily based on the proof-of-concept code written by wtbw

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
   3. The name of the author may not be used to endorse or promote
 products derived from this software without specific prior written
 permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
*/
import CryptoKit
import Foundation

/// Signs an iTunesDB for iPod classic firmware: an HMAC-SHA1 over the whole file, keyed on the FireWire ID.
nonisolated struct Hash58: Sendable {
    static let scheme: UInt16 = 1
    static let schemeOffset = 0x30
    static let hashRange = 0x58..<0x6C
    private static let zeroedRanges = [0x18..<0x20, 0x32..<0x46, hashRange]
    private static let fixed: [UInt8] = [
        0x67, 0x23, 0xFE, 0x30, 0x45, 0x33, 0xF8, 0x90, 0x99,
        0x21, 0x07, 0xC1, 0xD0, 0x12, 0xB2, 0xA1, 0x07, 0x81
    ]

    private let key: SymmetricKey

    init(fireWireID: FireWireID) {
        key = SymmetricKey(data: Insecure.SHA1.hash(data: Self.fixed + Self.keyMaterial(fireWireID.bytes)))
    }

    /// Returns `database` with the hashing scheme set and the hash58 field filled in.
    func sign(_ database: Data) throws -> Data {
        guard database.count >= Self.hashRange.upperBound, database.prefix(4) == Data("mhbd".utf8) else {
            throw ITunesDBError.invalidLength(offset: 0)
        }
        var signed = database
        signed.write(Self.scheme, at: Self.schemeOffset)
        signed.replaceSubrange(Self.hashRange, with: signature(of: signed))
        return signed
    }

    /// Whether an already signed database carries the hash this key produces.
    func isValid(_ database: Data) -> Bool {
        guard database.count >= Self.hashRange.upperBound,
              database.read(UInt16.self, at: Self.schemeOffset) == Self.scheme else { return false }
        return database.subdata(in: Self.hashRange) == signature(of: database)
    }

    static func isSigned(_ database: Data) -> Bool {
        database.count >= hashRange.upperBound && database.read(UInt16.self, at: schemeOffset) == scheme
    }

    private func signature(of database: Data) -> Data {
        var prepared = database
        for range in Self.zeroedRanges { prepared.replaceSubrange(range, with: Data(count: range.count)) }
        return Data(HMAC<Insecure.SHA1>.authenticationCode(for: prepared, using: key))
    }

    /// For each byte pair, the LCM's high and low bytes looked up in the S-box and its inverse.
    private static func keyMaterial(_ id: [UInt8]) -> [UInt8] {
        stride(from: 0, to: 8, by: 2).flatMap { index -> [UInt8] in
            let multiple = leastCommonMultiple(Int(id[index]), Int(id[index + 1]))
            let high = (multiple & 0xFF00) >> 8, low = multiple & 0xFF
            return [AESSubstitutionBox.forward[high], AESSubstitutionBox.inverse[high],
                    AESSubstitutionBox.forward[low], AESSubstitutionBox.inverse[low]]
        }
    }

    /// libgpod treats a zero byte as an LCM of 1.
    private static func leastCommonMultiple(_ a: Int, _ b: Int) -> Int {
        guard a != 0, b != 0 else { return 1 }
        var x = a, y = b
        while y != 0 { (x, y) = (y, x % y) }
        return a * b / x
    }
}
