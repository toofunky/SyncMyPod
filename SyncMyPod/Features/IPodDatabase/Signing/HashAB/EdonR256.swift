/*
 Swift port of the EDON-R' 256 compression function from dstaley/hashab's src/edonr.c,
 itself based on RHash's edonr.c.

 Copyright (c) 2011, Aleksey Kravchenko <rhash.admin@gmail.com>

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 PERFORMANCE OF THIS SOFTWARE.
*/
import Foundation

nonisolated struct EdonR256 {
    private(set) var state: [UInt32] = [
        0x4041_4243, 0x4445_4647, 0x4849_4A4B, 0x4C4D_4E4F, 0x5051_5253, 0x5455_5657, 0x5859_5A5B, 0x5C5D_5E5F,
        0x6061_6263, 0x6465_6667, 0x6869_6A6B, 0x6C6D_6E6F, 0x7071_7273, 0x7475_7677, 0x7879_7A7B, 0x7C7D_7E7F
    ]

    mutating func compress(_ block: [UInt32]) {
        let low = Array(block[0..<8]), high = Array(block[8..<16])
        var p = Self.quasigroup(high.reversed(), low)
        var r = Self.quasigroup(p, high)
        p = Self.quasigroup(Array(state[8..<16]), p)
        r = Self.quasigroup(p, r)
        p = Self.quasigroup(p, Array(state[0..<8]))
        r = Self.quasigroup(r, p)
        p = Self.quasigroup(low.reversed(), p)
        r = Self.quasigroup(p, r)
        for index in 0..<8 {
            state[index] ^= high[index] ^ p[index]
            state[8 + index] ^= low[index] ^ r[index]
        }
    }

    /// The Q256 macro: two eight-word quasigroup halves combined into eight output words.
    private static func quasigroup(_ x: [UInt32], _ y: [UInt32]) -> [UInt32] {
        let a = xHalf(x), t = yHalf(y)
        let u16 = t[0] ^ t[1], u17 = t[2] ^ t[5], u18 = t[3] ^ t[4], u19 = t[6] ^ t[7]
        return [a[3] &+ (u16 ^ t[5]), a[4] &+ (t[2] ^ u19), a[5] &+ (u16 ^ t[3]), a[6] &+ (t[0] ^ u18),
                a[7] &+ (t[1] ^ u17), a[0] &+ (u18 ^ t[6]), a[1] &+ (u17 ^ t[7]), a[2] &+ (t[4] ^ u19)]
    }

    private static func xHalf(_ x: [UInt32]) -> [UInt32] {
        let t8 = x[0] &+ x[4], t9 = x[1] &+ x[7], t10 = x[2] &+ x[3], t11 = x[5] &+ x[6]
        let t12 = t8 &+ t9, t13 = t10 &+ t11
        let t0 = 0xAAAA_AAAA &+ t12 &+ x[2]
        let t1 = (t12 &+ x[3]).rotatedLeft(4), t2 = (t12 &+ x[6]).rotatedLeft(8)
        let t3 = (t13 &+ x[7]).rotatedLeft(13), t4 = (x[1] &+ t13).rotatedLeft(17)
        let t5 = (t8 &+ t10 &+ x[5]).rotatedLeft(22), t6 = (x[0] &+ t9 &+ t11).rotatedLeft(24)
        let t7 = (t13 &+ x[4]).rotatedLeft(29)
        let t16 = t0 ^ t4, t17 = t1 ^ t7, t18 = t2 ^ t3, t19 = t5 ^ t6
        return [t3 ^ t19, t2 ^ t19, t18 ^ t5, t16 ^ t1, t16 ^ t7, t17 ^ t6, t18 ^ t4, t0 ^ t17]
    }

    private static func yHalf(_ y: [UInt32]) -> [UInt32] {
        let t16 = y[0] &+ y[1], t17 = y[2] &+ y[5], t18 = y[3] &+ y[4], t19 = y[6] &+ y[7]
        let t20 = t16 &+ t17, t21 = t18 &+ t19, t22 = t16 &+ t18, t23 = t17 &+ t19
        return [0x5555_5555 &+ t20 &+ y[7], (t22 &+ y[6]).rotatedLeft(5), (t20 &+ y[3]).rotatedLeft(9),
                (y[2] &+ t21).rotatedLeft(11), (t22 &+ y[5]).rotatedLeft(15), (t23 &+ y[4]).rotatedLeft(20),
                (y[1] &+ t23).rotatedLeft(25), (y[0] &+ t21).rotatedLeft(27)]
    }
}
