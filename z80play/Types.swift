//
//  Types.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import Foundation

class Token {
    var name: String
    init(name: String) {
        self.name = name
    }
}

extension Token: CustomStringConvertible {
    var description: String {
        return "\(type(of: self)):\(name)"
    }
}


class Inst: Token {
    var breakPoint = false
}

class Org: Token {
    let pc: UInt16
    init(pc: UInt16) {
        self.pc = pc
        super.init(name: "ORG")
    }
}

class DB: Token {
    var watch = false
    init() {
        super.init(name: "nn")
    }
}

class Void: Token {}

class Label: Token {
    var addr: UInt16?
}

class Number: Token {
    var addr: UInt16?
    var label: String?
    init(addr: UInt16) {
        self.addr = addr
        super.init(name: "nn")
    }
    init(label: String) {
        self.label = label
        super.init(name: "nn")
    }
}

class MemAddr: Token {
    init() {
        super.init(name: "(nn)")
    }
}

class Op: Hashable, Identifiable {
    var pc: UInt16 = 0
    let inst: Token
    var length: UInt16 = 0
    var args:[Token]=[]
    var valid = false
    
    var bytes:[UInt8] = []
    
    init(inst: Token) {
        self.inst = inst
    }
    
    static func == (lhs: Op, rhs: Op) -> Bool {
        var l_hasher = Hasher()
        var r_hasher = Hasher()
        lhs.hash(into: &l_hasher)
        rhs.hash(into: &r_hasher)
        return l_hasher.finalize() == r_hasher.finalize()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(inst.description)
        args.forEach { arg in
            hasher.combine(arg.description)
        }
    }
    
    func dump() -> String{
        if self.valid {
            if self.inst is Inst {
                let dump = self.bytes.map({$0.toHexShort()}).joined(separator: " ")
//                let dis = z80InstructionSet.shared.disassembler(data: self.bytes)
                return "\(self.pc.toHex()) \(dump)"
//                    .help("\(dis)\n\(self.description)")
//                    .background((status.nextPc == self.pc) ? .green : .clear)
            } else if self.inst is DB {
                let dump = self.bytes.map({$0.toHexShort()}).joined(separator: " ")
                return "\(self.pc.toHex()) \(dump)"
//                    .help(dump.subSequences(of:3*10).joined(separator: "\n"))
            } else {
                return("")
            }
        }
        return " x "
    }
}

extension Op: CustomStringConvertible {
    var description: String {
        return "\(valid ? "-" : "X") \(inst) \(args)"
    }
}
