//
//  Z80Compiler.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import Foundation

class Z80Compiler {
    private let validTokens: [String] = [
        "A","B","C","D","E","F","H","L",
        "AF","BC","DE","HL","IX","IY","SP","PC",
        "AF'",
        "NZ","Z","NC","C","PO","PE","P","M"]
    
    private var validOps: Set<Op> = []
    
    init() {
        let tables :[([opCode],[UInt8])] = [
            (z80InstructionSet.shared.lookup,[]),
            (z80InstructionSet.shared.lookupCB,[0xcb]),
            (z80InstructionSet.shared.lookupDD,[0xdd]),
            (z80InstructionSet.shared.lookupED,[0xdd]),
            (z80InstructionSet.shared.lookupFD,[0xfd]),
            (z80InstructionSet.shared.lookupDDCB,[0xDD,0xcb]),
            (z80InstructionSet.shared.lookupFDCB,[0xFD,0xcb]),
        ]
        
        tables.forEach { (table, prefix) in
            table.forEach { opCode in
                if opCode.name != "bogus" && !opCode.name.hasPrefix("_"){
//                    print(opCode, (prefix + [opCode.code,0x00,0x00]).map { $0.toHex() })
                    let line = z80InstructionSet.shared.disassembler(data: prefix + [opCode.code,0x00,0x00])
                    let op = compile_line(line)
                    op.length = UInt16(opCode.len)
                    op.bytes.append(contentsOf: prefix)
                    op.bytes.append(opCode.code)
                    validOps.insert(op)
                    //                     print(opCode.code.toHex(), op)
                }
            }
        }
    }
    
    func compile(_ sourceCode: String, menStart: UInt16 = 0) -> [Op] {
        var res: [Op] = []
        
        sourceCode.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .forEach { range in
                var line = String(range).trimmingCharacters(in: .whitespaces).uppercased()
                if let idx = line.firstIndex(of: ";") {
                    line = String(line.prefix(upTo: idx))
                }
                if !line.isEmpty {
                    res.append(compile_line(line))
                } else {
                    let op = Op(inst: Void(name: ""))
                    op.valid = true
                    res.append(op)
                }
            }
        
        var labels: [String: UInt16]=[:]
        var pc = menStart
        res.forEach { op in
            if op.valid {
                if let l = op.inst as? Label {
                    labels[l.name] = pc
                    l.addr = pc
                } else if let org = op.inst as? Org {
                    pc = org.pc + menStart
                } else {
                    op.pc = pc
                }
                pc += op.length
            }
        }
        
        res.forEach { op in
            op.args.forEach { arg in
                if let num = arg as? Number {
                    if let val = num.addr {
                        op.bytes.append(UInt8(val&0xff))
                        if op.length == 3 {
                            op.bytes.append(UInt8((val>>8)&0xff))
                        }
                    } else if let val = num.label {
                        if let pc = labels[val] {
                            if  ["JR","DJNZ"].contains(op.inst.name) && op.valid {
                                let diff = Int32(pc) - Int32(op.pc+2)
                                op.valid = (abs(diff) < 128)
                                let r = UInt8(abs(diff)&0x7f)
                                if diff < 0 {
                                    op.bytes.append(0xff^(r-1))
                                } else {
                                    op.bytes.append(r)
                                }
                            } else {
                                op.bytes.append(UInt8(pc&0xff))
                                if op.length == 3 {
                                    op.bytes.append(UInt8((pc>>8)))
                                }
                            }
                        } else {
                            op.valid = false
                        }
                    }
                }
            }
        }
        return res
    }
    
    private func compile_line(_ line: String) -> Op {
        let idx = line.firstIndex(of: " ")
        if idx == nil {
            let code = line.trimmingCharacters(in: .whitespaces)
            if code.hasSuffix(":") {
                let op = Op(inst: Label(name: code.trimmingCharacters(in: .init(charactersIn: ":"))))
                op.valid = true
                return op
            } else {
                let op = Op(inst: Inst(name: code))
                if let idx = validOps.firstIndex(of: op){
                    op.valid = true
                    op.length = validOps[idx].length
                    op.bytes.append(contentsOf: validOps[idx].bytes)
                }
                return op
            }
        }
        
        var op: Op = Op(inst: Token(name: "err"))
        op.valid = false

        let code = line[..<idx!].trimmingCharacters(in: .whitespaces)
        let args = line[idx!...].trimmingCharacters(in: .whitespaces).split(separator: ",",omittingEmptySubsequences: false).map { str in
            String(str).trimmingCharacters(in: .whitespaces)
        }

        switch code {
        case "ORG":
            if let v = args[0] as String? {
                if let addr = UInt16(asm: v) {
                    op = Op(inst: Org(pc: addr))
                    op.valid = true
                }
            }

        case "DB":
            op = Op(inst: DB())
            op.valid = args.count > 0
            op.length = UInt16(args.count)
            args.forEach { arg in
                if let val = UInt8(asm: arg) {
                    op.bytes.append(val)
                } else {
                    op.valid = false
                }
            }

        default:
            op = Op(inst: Inst(name: code))
            args.forEach { arg in
                parseArg(arg, op: op)
            }
            if let idx = validOps.firstIndex(of: op){
                op.valid = true
                op.length = validOps[idx].length
                op.bytes.append(contentsOf: validOps[idx].bytes)
            }
        }

        return op
    }
    
    func parseArg(_ arg: String, op: Op) {
        if arg.hasPrefix("(") && arg.hasSuffix(")") {
            op.args.append(MemAddr())
            parseArg(arg.trimmingCharacters(in: .init(charactersIn: "()")), op: op)
        } else if validTokens.contains(arg) {
            op.args.append(Token(name: arg))
        } else if arg.contains("+") {
            arg.split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }.forEach { arg in
                parseArg(arg, op: op)
            }
        } else if let v = UInt16(asm: arg){
            op.args.append(Number(addr: v))
        } else {
            op.args.append(Number(label: arg))
        }
    }
}

//class DummyBus:Bus {
//    var addr :UInt16 = 0
//    var data :UInt8 = 0
//    func writeToMemory(_ addr: UInt16, _ data: UInt8) { fatalError() }
//    func readVideoMemory(_ addr: UInt16) -> UInt8 { fatalError() }
//    func readMemory() {    }
//    func writeMemory() {}
//    func release() {}
//    func registerPort(mask: PortMask, manager: PortManager) {}
//    func readPort() {}
//    func writePort() {}
//    func getBlock(addr: UInt16, length: UInt16) -> [UInt8] { fatalError() }
//}
