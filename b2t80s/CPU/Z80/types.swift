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
typealias z80Painter = (_ op: opCode, _ cpu: z80)->(String)

protocol z80op {
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

    func disassemble(_ cpu: z80) -> String {
        return diss(self,cpu)
    }
}

let bogusOpCode = opCode("bogus", 0, 0, 0, [], {cpu in fatalError()})
