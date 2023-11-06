//
//  diss.swift
//  b2t80s
//
//  Created by German Laullon on 26/8/23.
//

import Foundation

private let r:[String?] = ["B", "C", "D", "E", "H", "L", nil,"A"]
private let cc:[String] = ["NZ","Z","NC","C","PO","PE","P","M"]
private let rp = ["BC","DE","HL","SP"]
private let rp2 = ["BC","DE","HL","AF"]


func diss_ldDDmm(_ op: opCode, _ fetched: FetchedData)->(String) {
//    var ins = op.name
//    ins.replace("nn", with: fetched.nn.toHex())
//    ins.replace("dd", with: rp[Int(fetched.opCode&0b00110000)>>4])
//    return "\(ins)";
    return dis(op, fetched);
}

func dis_invalid(_ op: opCode, _ fetched: FetchedData)->(String) {
//    fatalError()
    return dis(op, fetched);
}

func dis_ldrn(_ op: opCode, _ fetched: FetchedData)->(String) {
    return dis(op, fetched);
}

func dis(_ op: opCode, _ fetched: FetchedData)->(String) {
    var ins = op.name
    let y = Int(fetched.opCode & 0b00111000) >> 3
    let z = Int(fetched.opCode & 0b00000111)
    let p = Int(fetched.opCode & 0b00110000) >> 4
    ins.replace("nn", with: fetched.nn.toHex())
    ins.replace("n", with: fetched.n.toHex())
    ins.replace("d", with: fetched.n.toHex())
    ins.replace("rp[p]", with: rp[p])
    ins.replace("r[y]", with: r[y] ?? "x")
    ins.replace("r[z]", with: r[z] ?? "x")
    ins.replace("cc[y]", with: cc[y])
    ins.replace("rp2[p]", with: rp2[p])
    ins.replace(" y*8", with: String("_\(UInt8(y*8).toHex())"))
    ins.replace("y", with: String("\(y)"))

    return "\(ins)";
}

extension z80InstructionSet {
    func disassembler(data _data: [UInt8]) -> String {
        var data = _data
        var op: opCode
        var n: UInt8 = 0
        var nn: UInt16 = 0
        var code = Int(data.removeFirst())
        switch code {
        case 0xCB:
            code = Int(data.removeFirst())
            op = lookupCB[code]
        case 0xDD:
            code = Int(data.removeFirst())
            op = lookupDD[code]
        case 0xED:
            code = Int(data.removeFirst())
            op = lookupED[code]
        case 0xFD:
            code = Int(data.removeFirst())
            op = lookupFD[code]
        default:
            op = lookup[code]
        }
        if op.len > 1 {
            n = data.removeFirst()
        }
        if op.len > 2 {
            nn = UInt16(n) | (UInt16(data.removeFirst())<<8)
        }
        
        return dis(ins: op.name, code: UInt8(code), n: n, nn: nn)
    }
    
    private func dis(ins _ins: String, code: UInt8, n: uint8, nn: UInt16)->(String) {
        var ins = _ins
        let y = Int(code & 0b00111000) >> 3
        let z = Int(code & 0b00000111)
        let p = Int(code & 0b00110000) >> 4
        ins.replace("nn", with: nn.toHex())
        ins.replace("n", with: n.toHex())
        ins.replace("d", with: n.toHex())
        ins.replace("rp[p]", with: rp[p])
        ins.replace("r[y]", with: r[y] ?? "x")
        ins.replace("r[z]", with: r[z] ?? "x")
        ins.replace("cc[y]", with: cc[y])
        ins.replace("rp2[p]", with: rp2[p])
        ins.replace(" y*8", with: String("_\(UInt8(y*8).toHex())"))
        ins.replace("y", with: String("\(y)"))

        return "\(ins)";
    }

}

extension z80 {
    func disassembler(_ nInstructions: UInt16, from:UInt16) -> [FetchedData] {
        var res:[FetchedData] = []
        var pc = from
        for _ in 0..<nInstructions {
            let f = FetchedData(op: bogusOpCode)
            f.pc = pc
            f.opCode = self.bus.readVideoMemory(pc)
            switch f.opCode {
            case 0xCB:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.ins.lookupCB[Int(f.opCode)]
            case 0xDD:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.ins.lookupDD[Int(f.opCode)]
            case 0xED:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.ins.lookupED[Int(f.opCode)]
            case 0xFD:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.ins.lookupFD[Int(f.opCode)]
            default:
                f.op = self.ins.lookup[Int(f.opCode)]
            }
            if f.op.len >= 2 {
                pc &+= 1
                f.n = self.bus.readVideoMemory(pc)
            }
            if f.op.len >= 3 {
                pc &+= 1
                f.n2 = self.bus.readVideoMemory(pc)
                f.nn = (UInt16(f.n)) | (UInt16(f.n2)<<8)
            }
            if f.op.len > 3 {
                fatalError()
            }

            
            res.append(f)
            pc &+= 1
        }
        return res
    }
}
