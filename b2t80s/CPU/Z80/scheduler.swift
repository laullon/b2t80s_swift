//
//  scheduler.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

struct Scheduler {
    var elemets :[z80op?] = Array(repeating: nil, count: 0x10)
    var e :UInt8 = 0
    var i :UInt8 = 0
    
    func isEmpty() -> Bool {
        return i == e
    }
    
    mutating func append(_ ops: z80op...) {
        for op in ops {
            elemets[Int(e)] = op
            e += 1
            e &= 0x0F
        }
    }
    
    func first() -> z80op {
        return elemets[Int(i)]!
    }
    
    mutating func next() {
        i += 1
        i &= 0x0F
    }
}

class basicOp :z80op {
    func tick(_ cpu: z80) {
        fatalError()
    }
    
    var t    :UInt8 = 0
    var done :Bool = false
    
    func reset() {
        t = 0
        done = false
    }
    
    func  isDone() -> Bool {
        return done
    }
}

class Exec :basicOp {
    var l :UInt8
    var f :z80EXECf
    
    init(l: UInt8, f: @escaping z80EXECf = {cpu in ()}) {
        self.l = l
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
        if t == l {
            f(cpu)
            done = true
        }
    }
}

class MW :basicOp {
    var addr :UInt16
    var data :UInt8
    var f :z80EXECf
    
    init(_ addr: UInt16, _ data: UInt8, _ f: @escaping z80EXECf) {
        self.addr = addr
        self.data = data
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t+=1
        switch t {
        case 1:
            cpu.bus.addr = addr
        case 2:
            cpu.bus.data = data
        case 3:
            cpu.bus.writeMemory()
            cpu.bus.release()
            f(cpu)
            done = true
        default:
            fatalError()
        }
    }
}

class MR :basicOp {
    var f    :z80MRf
    var from :uint16
    
    init(_ from: uint16, _ f: @escaping z80MRf) {
        self.f = f
        self.from = from
    }
    
    override func tick(_ cpu: z80) {
        t+=1
        switch t {
        case 1:
            cpu.bus.addr = from
        case 2:
            ()
        case 3:
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            f(cpu, d)
            done = true
        default:
            fatalError()
        }
    }
}

class Fetch :basicOp {
    var table :[opCode]
    
    init(_ table: [opCode]) {
        self.table = table
    }
    
    override func tick(_ cpu: z80) {
        t += 1
//        print("> [fetch]", t, "pc:", cpu.regs.PC.toHex())
        switch t {
        case 1:
            cpu.regs.M1 = true
            cpu.bus.addr = cpu.regs.PC
            cpu.regs.PC &+= 1
            cpu.regs.R = cpu.regs.R&0x80 | ((cpu.regs.R &+ 1) & 0x7f)
        case 2:
            ()
        case 3:
            cpu.regs.M1 = false
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            cpu.fetched.prefix = cpu.fetched.prefix << 8
            cpu.fetched.prefix |= uint16(cpu.fetched.opCode)
            cpu.fetched.opCode = d
        case 4:
            cpu.fetched.op = table[Int(cpu.fetched.opCode)]
            for op in cpu.fetched.op.ops {
                op.reset()
                cpu.scheduler.append(op)
            }
            cpu.fetched.op.onFetch(cpu)
            done = true
        default:
            fatalError()
        }
    }
}

class mrNNpc :basicOp {
    var f :z80f
    
    init(f: @escaping z80f) {
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
//        print("> [mrNNpc]", t, "pc:", cpu.regs.PC.toHex())
        switch t {
        case 1:
            cpu.bus.addr = (cpu.regs.PC)
            cpu.regs.PC &+= 1
        case 2:
            ()
        case 3:
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            cpu.fetched.n = d
        case 4:
            cpu.bus.addr = (cpu.regs.PC)
            cpu.regs.PC &+= 1
        case 5:
            ()
        case 6:
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            cpu.fetched.n2 = d
            cpu.fetched.nn = uint16(cpu.fetched.n) | (uint16(cpu.fetched.n2) << 8)
            f(cpu)
            done = true
        default:
            fatalError()
        }
    }
}

class mrNpc :basicOp {
    var f :z80f
    
    init(f: @escaping z80f) {
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
        // println("> [mrNpc]", t, "pc:", fmt.Sprintf("0x%04X", cpu.regs.PC))
        switch t {
        case 1:
            cpu.bus.addr = (cpu.regs.PC)
            cpu.regs.PC &+= 1
        case 2:
            ()
        case 3:
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            cpu.fetched.n = d
            f(cpu)
            done = true
        default:
            fatalError()
        }
    }
}

class mw :basicOp {
    var addr :UInt16
    var data :UInt8
    var f :z80f
    
    init(_ addr :UInt16, _ data :UInt8, _ f :@escaping z80f) {
        self.addr = addr
        self.data = data
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
        switch t {
        case 1:
            cpu.bus.addr = addr
        case 2:
            cpu.bus.data = data
        case 3:
            cpu.bus.writeMemory()
            cpu.bus.release()
            f(cpu)
            done = true
        default:
            fatalError()
        }
    }
}

class mr :basicOp {
    var from :UInt16
    var f    :z80MRf
    
    init(_ from :UInt16, _ f :@escaping z80MRf) {
        self.from = from
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
        switch t {
        case 1:
            cpu.bus.addr = from
        case 2:
            ()
        case 3:
            cpu.bus.readMemory()
            let d = cpu.bus.data
            cpu.bus.release()
            f(cpu, d)
            done = true
        default:
            fatalError()
        }
    }
}

class out :basicOp {
    var addr :UInt16
    var data :UInt8
    var f :z80f
    
    init(addr :UInt16, data :UInt8, f :@escaping z80f = {cpu in ()}) {
        self.addr = addr
        self.data = data
        self.f = f
    }
    
    override func tick(_ cpu: z80) {
        t += 1
        switch t {
        case 1:
            cpu.bus.addr = addr
            cpu.bus.data = data
            cpu.bus.writePort()
            cpu.bus.release()
        case 2:
            ()
        case 3:
            f(cpu)
            done = true
        default:
            fatalError()
        }
    }
}


class inOP :basicOp {
    var from :UInt16
    var f    :z80INf
    
    init(from :UInt16, f :@escaping z80INf) {
        self.from = from
        self.f = f
    }

    override func tick(_ cpu: z80) {
        t += 1
        switch t {
        case 1:
            cpu.bus.addr = from
        case 2:
            ()
        case 3:
            ()
        case 4:
            cpu.bus.readPort()
            let data = cpu.bus.data
            cpu.bus.release()
            cpu.regs.F.S = data&0x0080 != 0
            cpu.regs.F.Z = data == 0
            cpu.regs.F.H = false
            cpu.regs.F.P = cpu.parityTable[Int(data)]
            cpu.regs.F.N = false
            f(cpu, data)
            done = true
        default:
            fatalError()
        }
    }
}
