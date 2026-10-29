import Foundation

/// Folds hashAB's 190 bytes of key material into the 16-byte stage-two IV (dstaley/hashab's src/reduce.c).
/// The steps are straight-line obfuscated arithmetic; their order matters because later steps read earlier writes.
nonisolated struct HashABReducer {
    private static let inputSize = 190
    private static let outputSize = 16

    private var key = keySeed
    private var state = stateSeed
    private var work: [UInt32]
    private var s6: UInt32 = 0, s7: UInt32 = 0, s8: UInt32 = 0, s9: UInt32 = 0, s10: UInt32 = 0
    private var s18: UInt32 = 0, s19: UInt32 = 0, s21: UInt32 = 0, s22: UInt32 = 0
    private var s24: UInt32 = 0, s25: UInt32 = 0, s26: UInt32 = 0

    static func reduce(_ input: [UInt8]) -> [UInt8] {
        var reducer = HashABReducer(input: input)
        reducer.diffuse()
        reducer.stepOne()
        reducer.stepTwo()
        reducer.stepThree()
        reducer.stepFour()
        reducer.stepFive()
        reducer.stepSix()
        reducer.stepSeven()
        return reducer.output()
    }

    private init(input: [UInt8]) {
        work = (0..<128).map { index in
            (0..<4).reduce(UInt32(0)) { word, byte in
                word | UInt32(input[(4 * index + byte) % Self.inputSize] &* 0xBD) << (24 - 8 * byte)
            }
        }
    }

    private mutating func diffuse() {
        for _ in 0..<4 {
            for j in 0..<128 {
                let mixed = work[j] ^ work[(j - 13) & 127].rotatedLeft(3)
                work[j] = mixed &+ work[(j + 71) & 127].rotatedLeft(5) &- work[(j + 101) & 127].rotatedLeft(23)
            }
        }
    }

    private mutating func stepOne() {
        s7 = (work[22] / 5) &* 0xC345_6F96
        s8 = Self.majority(state[60], Self.table[63], 0x908D_4D25) / 3 &+ 0xEF96_95DD
        key[42] &+= ((tableAt(work[33]) & 0x3CBA_9069) &+ 0x4344_0114) / 5
        s9 = Self.choose(state[26], stateAt(work[87]), ~0x3CBA_9069)
        let rotation = Self.rotateLeftOrOnes(0x6F72_B2DA, (0 &- stateAt(work[55])) & 31)
        let quotient = keyAt(s7) / 5
        let selected = Self.choose(state[42], ~0x3047_874D, ~0xB0DE_A603)
        s10 = rotation ^ 0x908D_4D25
        key[63] &-= Self.majority(selected, quotient, s7)
        state[25] &+= keyAt(s7)
        state[60] = Self.choose(key[21], s8, ~0x1FB7_D8D3) &* work[122]
        work[5] &+= Self.choose(s7, ~0xD36D_6FB6, tableAt(work[120]))
    }

    private mutating func stepTwo() {
        key[35] &+= 0xB1A7_E76F
        s18 = keyAt(s10) ^ 0x908D_4D25
        state[44] ^= 3 &* Self.choose(0xC345_6F96, Self.table[29], tableAt(work[18]))
        work[107] &+= stateAt(work[44]) &+ 1
        let invertedRotation = ~Self.rotateRightOrOnes(0xB0DE_A603, work[71] & 31)
        key[54] &-= Self.majority(state[29], invertedRotation, ~0x6F72_B2DA)
        work[62] ^= 0xDBD3_D289
        key[19] &+= stateAt(s7) / 5 &- Self.majority(state[45], tableAt(work[45]), ~0x4CF5_0FA3)
        key[49] = tableAt(stateAt(s18) &* stateAt(s18))
        key[21] ^= tableAt(work[27])
    }

    private mutating func stepThree() {
        s19 = 0x908D_4D24 &- Self.rotateLeftOrOnes(0x98B9_9BD8, (state[60] &* state[41]) & 31)
        state[10] = work[73]
        key[20] ^= Self.rotateLeftOrOnes(~stateAt(work[98]), key[60] & 31)
        key[49] &+= Self.choose(state[56], key[41], tableAt(s19)) >> 1
        let tableWord = tableAt(work[10])
        state[24] ^= Self.choose(key[39], state[37], tableWord &* tableWord &* tableWord)
        s6 = ((tableAt(work[43]) & ~0x4505_9986) | 0x4105_0082) ^ 0x3CBA_9069
        let rotated = Self.rotateRightOrOnes(~s18, tableAt(work[31]) & 31)
        state[13] ^= (keyAt(work[50]) & ~0x147F_3886) | ~(rotated | 0xEB80_C779)
        key[28] &-= Self.choose(key[35], Self.majority(key[58], tableAt(s9), 0x908D_4D25), ~key[29])
        state[23] &+= ~Self.majority(s8, stateAt(work[106]), 0x2725_FE3B)
        state[24] ^= work[118] &* work[118]
    }

    private mutating func stepFour() {
        key[35] ^= Self.majority(state[54], 2 &* work[108], state[41] &* state[41] &* state[41])
        work[34] ^= Self.choose(s18, stateAt(work[39]) ^ state[37], Self.table[29] &+ 0x02E5_A7E3)
        state[42] ^= Self.choose(state[40], stateAt(work[35]), work[78] &* work[78])
        work[49] &+= 3 &* keyAt(work[39]) &+ 0x6211_6BE6
        key[48] = s7
        state[62] = keyAt(s19) &- stateAt(work[93]) &- 0xEF96_95DD
        key[55] &+= key[60] / 3 &- stateAt(work[112]) / 3
        s21 = Self.majority(s6, Self.table[60] &+ 0x4D48_5456, 0x41D4_4D69) &+ 0x3CBA_9069
        s25 = s9 ^ key[37]
        state[55] &+= 0x1D0F_1B76
        work[77] &-= Self.table[Int((state[60] & 127) >> 1)]
        state[29] = keyAt(work[68]) / 15
    }

    private mutating func stepFive() {
        state[46] ^= tableAt(tableAt(Self.table[37]))
        s22 = 0x4F21_59FC &- Self.majority(state[59], Self.table[29], Self.table[60] / 5)
        let inner = Self.majority(0x5908_9BE9, tableAt(work[16]), state[60])
        s24 = Self.choose(0xBD06_DD88, inner, Self.table[60]) &+ 0x4F21_59FC
        work[10] = 0xDE28_49DD
        let chosen = Self.choose(state[52], 0x908D_4D25, 0x5987_B420)
        work[8] &+= Self.majority(chosen, work[48] ^ s22, 0x5112_7D0F)
        state[20] &+= tableAt(work[1])
        work[32] &+= 1 &+ Self.rotateRightOrOnes(0x0C7A_D237, (s22 &* s22 &* s22) & 31)
        let rotated = Self.rotateRightOrOnes(0x46EF_99F4, key[41] & 31)
        state[4] &-= Self.choose(key[35], 0x4F21_59FC, 0xC054_0978) | ~rotated
    }

    private mutating func stepSix() {
        state[60] = ~Self.rotateLeftOrOnes(~(work[62] / 3), (work[22] &+ keyAt(work[93])) & 31)
        key[30] = 0x3CBA_9069
        key[10] = ~(tableAt(work[122]) &+ 0x972D_A190)
        state[46] &+= Self.majority(state[8], tableAt(work[35]) | Self.table[41], 0xF3D3_9067)
        let masked = (tableAt(work[67]) | tableAt(work[120])) &- tableAt(work[98]) &- 1
        s26 = 0x3CBA_9069 &- masked
        let halved = stateAt(work[38]) >> 1
        state[17] ^= halved &* halved &* halved
        state[44] &+= Self.table[62]
        key[26] &-= tableAt(s6)
    }

    private mutating func stepSeven() {
        let first = Self.choose(0x313E_C15D, keyAt(s6), state[60])
        let second = (tableAt(work[79]) & 0x7FBB_D9FD) | 0x0C20_1068
        key[35] &-= Self.majority(key[34], first, second)
        key[16] ^= Self.majority(state[43], work[27] >> 1, state[41] | state[37])
        work[33] = 0x1C3E_9665
        key[58] &-= work[118]
        state[21] &+= key[60]
        state[10] &-= state[60]
    }

    private func output() -> [UInt8] {
        let seeds: [UInt32] = [0xBA &+ s25, 0x97, 0x97, 0x9B &+ s24, 0xBA &+ s8, 0x97, 0xD3 &+ s22, 0x97,
                               0xBE &+ s18 &+ s6, 0x27 &+ s7, 0x4C, 0x27 &+ s19,
                               0xBE &+ s10 &+ s21, 0xE3 &+ s26, 0x4C, 0x27 &+ work[92]]
        return (0..<Self.outputSize).map { index in
            var reduced = UInt8(truncatingIfNeeded: seeds[index])
            for j in stride(from: index, to: 64, by: Self.outputSize) {
                reduced ^= UInt8(truncatingIfNeeded: key[j]) ^ UInt8(truncatingIfNeeded: state[j])
            }
            for j in stride(from: index, to: 128, by: Self.outputSize) {
                reduced ^= Self.fold(work[j])
            }
            return 0xA5 &* reduced
        }
    }

    private func keyAt(_ index: UInt32) -> UInt32 { key[Int(index & 63)] }
    private func stateAt(_ index: UInt32) -> UInt32 { state[Int(index & 63)] }
    private func tableAt(_ index: UInt32) -> UInt32 { Self.table[Int(index & 63)] }

    private static func choose(_ mask: UInt32, _ whenSet: UInt32, _ whenClear: UInt32) -> UInt32 {
        (mask & whenSet) | (~mask & whenClear)
    }

    private static func majority(_ a: UInt32, _ b: UInt32, _ c: UInt32) -> UInt32 {
        (a & b) | (a & c) | (b & c)
    }

    private static func rotateLeftOrOnes(_ value: UInt32, _ count: UInt32) -> UInt32 {
        count == 0 ? .max : value.rotatedLeft(count)
    }

    private static func rotateRightOrOnes(_ value: UInt32, _ count: UInt32) -> UInt32 {
        count == 0 ? .max : value.rotatedRight(count)
    }

    private static func fold(_ word: UInt32) -> UInt8 {
        var folded = UInt8(truncatingIfNeeded: word)
        folded &+= UInt8(truncatingIfNeeded: word >> 8)
        folded ^= UInt8(truncatingIfNeeded: word >> 16)
        folded &+= UInt8(truncatingIfNeeded: word >> 24)
        return folded
    }
}
