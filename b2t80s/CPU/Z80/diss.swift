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
    ins.replace("rp[p]", with: rp[p])
    ins.replace("r[y]", with: r[y] ?? "x")
    ins.replace("r[z]", with: r[z] ?? "x")
    ins.replace("cc[y]", with: cc[y])
    ins.replace("rp2[p]", with: rp2[p])
    ins.replace("y*8", with: String("\(y*8)"))
    ins.replace("y", with: String("\(y)"))

    return "\(ins)";
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
                f.op = self.lookupCB[Int(f.opCode)]
            case 0xDD:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.lookupDD[Int(f.opCode)]
            case 0xED:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.lookupED[Int(f.opCode)]
            case 0xFD:
                f.prefix = UInt16(f.opCode)
                pc &+= 1
                f.opCode = self.bus.readVideoMemory(pc)
                f.op = self.lookupFD[Int(f.opCode)]
            default:
                f.op = self.lookup[Int(f.opCode)]
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
