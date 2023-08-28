//
//  diss.swift
//  b2t80s
//
//  Created by German Laullon on 26/8/23.
//

import Foundation

private let regs:[String?] = ["B", "C", "D", "E", "H", "L", nil,"A"]

func dis_ldrn(_ op: opCode, _ cpu: z80)->(String) {
    return dis(op, cpu);
}

func dis(_ op: opCode, _ cpu: z80)->(String) {
    var ins = op.name
    ins.replace("nn", with: cpu.fetched.nn.toHex())
    ins.replace("n", with: cpu.fetched.n.toHex())
    if ins.contains("r"){
        let r = Int((op.code&0b00111000)>>3)
        if let reg = regs[r]{
            ins.replace("r", with: reg)
        }
    }
    return "\(ins)";
}
