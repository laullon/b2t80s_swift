//
//  types.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

typealias CPUTrap = (_ cpu: z80)->()
typealias z80EXECf = (_ cpu: z80)->()
typealias z80MRf =  (_ cpu: z80, _ data: UInt8)->()
typealias z80f = (_ cpu: z80)->()
typealias z80INf =  (_ cpu: z80, _ data: UInt8)->()
typealias z80Painter = (_ op: opCode, _ fetchedData: FetchedData)->(String)

protocol z80op {
    var t: UInt8 { get }
    func tick(_ cpu: z80)
    func isDone() -> Bool
    func reset() // TODO i hate this
}


class FetchedData {
    var pc     :UInt16 = 0
    var prefix :UInt16 = 0
    var opCode :UInt8 = 0
    var n2     :UInt8 = 0
    var n      :UInt8 = 0
    var nn     :UInt16 = 0
    var op     :opCode
    var ts     :UInt = 0
    
    init(op: opCode) {
        self.op = op
        self.opCode = op.code
    }
}

extension Array where Element == FetchedData {
    func dump() -> String {
        return self.reduce("") {"\($0)\n\($1.pc.toHex()) - \($1.op.disassemble($1))"}.trimmingCharacters(in: .newlines)
    }
}

extension Array where Element == UInt8 {
    func dump() -> String {
        return self.reduce("") {"\($0) \($1.toHexShort())"}.trimmingCharacters(in: .whitespaces)
    }
}

struct opCode {
    var name       :String
    var mask, code :UInt8
    var len        :UInt8
    var ops        :[z80op]
    var onFetch    :z80f
    var diss :z80Painter
    
    init(_ name: String,_ mask: UInt8, _ code: UInt8, _ len :UInt8, _ ops :[z80op], _ onFetch: @escaping z80f,_ diss:@escaping z80Painter = dis) {
        self.name = name
        self.mask = mask
        self.code = code
        self.len = len
        self.ops = ops
        self.onFetch = onFetch
        self.diss = diss
    }

    func disassemble(_ fetchedData: FetchedData) -> String {
        return diss(self, fetchedData)
    }
}

let bogusOpCode = opCode("bogus", 0, 0, 0, [], {cpu in fatalError()})

public extension UInt16 {
    init?(asm: String) {
        let v = asm.uppercased()
        if v.hasPrefix("0X") {
            self.init(v.trimmingPrefix("0X"), radix: 16)
        } else if v.hasPrefix("0B") {
            self.init(v.trimmingPrefix("0B"), radix: 2)
        } else if v.hasPrefix("%") {
            self.init(v.trimmingPrefix("%"), radix: 2)
        } else {
            self.init(v)
        }
    }
    
    func toHex() -> String {
        return String(format: "0x%04X", self)
    }
}

extension UInt8 {
    init?(asm: String) {
        let v = asm.uppercased()
        if v.hasPrefix("0X") {
            self.init(v.trimmingPrefix("0X"), radix: 16)
        } else if v.hasPrefix("0B") {
            self.init(v.trimmingPrefix("0B"), radix: 2)
        } else if v.hasPrefix("%") {
            self.init(v.trimmingPrefix("%"), radix: 2)
        } else {
            self.init(v)
        }
    }

    func toHex() -> String {
        return String(format: "0x%02X", self)
    }
    
    func toBin() -> String {
        var str = String(self, radix: 2)
        str = String(repeating: "0", count: self.leadingZeroBitCount) + str
        return "0b\(str)"
    }
    
    func toHexShort() -> String {
        return String(format: "%02X", self)
    }
}

extension Collection {
    func unfoldSubSequences(limitedTo maxLength: Int) -> UnfoldSequence<SubSequence,Index> {
        sequence(state: startIndex) { start in
            guard start < self.endIndex else { return nil }
            let end = self.index(start, offsetBy: maxLength, limitedBy: self.endIndex) ?? self.endIndex
            defer { start = end }
            return self[start..<end]
        }
    }
    func subSequences(of n: Int) -> [SubSequence] {
        .init(unfoldSubSequences(limitedTo: n))
    }
}
