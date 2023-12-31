//
//  z80.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import Foundation

class z80 {
    var regs = Registers()
    var scheduler = Scheduler()
    var bus :Bus
    var traps :[UInt16: CPUTrap] = [:]
    var wait :Bool = false
    var waitOnNext :Bool = false
    var waitOnNextInterruption :Bool = false
    var doInterrupt :Bool = false {
        didSet {
            if doInterrupt == false {
                interruptDone = false
            }
        }
    }
    var interruptDone :Bool = false
    var doReset :Bool = false
    var halt :Bool = false
    var pushF :z80EXECf?
    var fetched = FetchedData(op: bogusOpCode)
    var indexIdx :Int = 0
        
    var parityTable :[Bool] = Array(repeating: false, count: 0x100)
    var overflowAddTable: [Bool] = [false, false, false, true, true, false, false, false]
    var overflowSubTable: [Bool] = [false, true, false, false, false, false, true, false]
    var halfcarryAddTable: [Bool] = [false, true, true, true, false, false, false, true]
    var halfcarrySubTable: [Bool] = [false, false, true, false, true, false, true, true]
    
    var log: [FetchedData] = Array()
    
    var breakPoints: [UInt16] = []
    
    let ins = z80InstructionSet.shared

    init(_ bus: Bus){
        self.bus = bus
        initParityTable()
    }
    
    func initParityTable() {
        for i in 0...0xff {
            var j = UInt8(i)
            var p = UInt8(0)
            for _ in 0...8 {
                p ^= j & 1
                j = j>>1
            }
            if p != 0 {
                parityTable[i] = false
            } else {
                parityTable[i] = true
            }
        }
    }

    func decodeCB() {
        scheduler.append(Fetch(self.ins.lookupCB))
    }
    
    func decodeDD() {
        indexIdx = 1
        scheduler.append(Fetch(self.ins.lookupDD))
    }
    
    func decodeED() {
        scheduler.append(Fetch(self.ins.lookupED))
    }
    
    func decodeFD() {
        indexIdx = 2
        scheduler.append(Fetch(self.ins.lookupFD))
    }
    
    func decodeDDCB() {
        regs.R &-= 1
        scheduler.append(Fetch(self.ins.lookupDDCB))
    }
    
    func decodeFDCB() {
        regs.R &-= 1
        scheduler.append(Fetch(self.ins.lookupFDCB))
    }
    
    func RegisterTrap(pc: uint16, trap: @escaping CPUTrap) {
        traps[pc] = trap
    }
    
    func tick() {
        if halt {
            if doInterrupt && !interruptDone {
                halt = false
                regs.PC &+= 1
                execInterrupt()
            } else {
                return
            }
        }
        
        if scheduler.isEmpty() {
            if doReset {
                regs.F.SetByte(0xff)
                regs.A = 0xff
                regs.I = 0
                regs.R = 0
                regs.R7 = 0
                regs.PC = 0
                regs.SP = 0xffff
                regs.IFF1 = false
                regs.IFF2 = false
                halt = false
                doReset = false
                return
            }
            
            if doInterrupt && !interruptDone {
                execInterrupt()
            } else {
                newInstruction()
                self.wait = self.breakPoints.contains(regs.PC)
            }
        }
        
        if wait {
            return
        }

        scheduler.first().tick(self)
        fetched.ts += 1

        if scheduler.first().isDone() {
            scheduler.next()
            if scheduler.isEmpty() {
                log.append(fetched)
                if log.count > 10 {
                    log.remove(at: 0)
                }
                wait = waitOnNext
            }
        }
    }
    
    func execInterrupt() {
        if waitOnNextInterruption {
            waitOnNextInterruption = false
            waitOnNext = true
        }
        prepareForNewInstruction()
        interruptDone = true
        
        if regs.IFF1 {
            regs.IFF1 = false
            regs.IFF2 = false
            switch regs.InterruptsMode {
            case 0, 1:
                let code = Exec(l: 7, f: { cpu in
                    cpu.pushToStack(cpu.regs.PC, { cpu in
                        cpu.regs.PC = 0x0038
                    })
                })
                scheduler.append(code)
            case 2:
                let code = Exec(l: 7, f: {cpu in
                    cpu.pushToStack(self.regs.PC, {cpu in
                        let pos = uint16(cpu.regs.I)<<8 + 0x00
                        let mr1 = MR(pos, {cpu, data in
                            cpu.regs.PC = uint16(data) }
                        )
                        let mr2 = MR(pos&+1, {cpu, data in
                            cpu.regs.PC |= uint16(data) << 8}
                        )
                        cpu.scheduler.append(mr1, mr2)
                    })
                })
                scheduler.append(code)
            default:
                fatalError()
            }
        } else {
            newInstruction()
        }
    }
    
    func pushToStack(_ data: uint16,_ f: @escaping z80EXECf) {
        pushF = f
        let push1 = MW(regs.SP &- 1, uint8(data>>8), {cpu in ()})
        let push2 = MW(regs.SP &- 2, uint8(data&0xff), push_m1)
        scheduler.append(push1, push2)
    }
    
    func popFromStack(_ f :@escaping (_ cpu: z80, _ data :UInt16)->()) {
        popF = f
        let pop1 = MR(regs.SP, pop_m1)
        let pop2 = MR(regs.SP &+ 1, pop_m2)
        scheduler.append(pop1, pop2)
    }
    
    func newInstruction() {
        prepareForNewInstruction()
        doTraps()
        scheduler.append(Fetch(self.ins.lookup))
    }
    
    func prepareForNewInstruction() {

        fetched = FetchedData(op: bogusOpCode)
        fetched.pc = regs.PC
        indexIdx = 0
    }
    
    func doTraps() {
        if let trap = traps[regs.PC] {
            wait = true
            trap(self)
            wait = false
        }
    }
    
    func checkCondition(_ ccIdx :UInt8) -> Bool {
        var res = false
        switch ccIdx {
        case 0:
            res = !regs.F.Z
        case 1:
            res = regs.F.Z
        case 2:
            res = !regs.F.C
        case 3:
            res = regs.F.C
        case 4:
            res = !regs.F.P
        case 5:
            res = regs.F.P
        case 6:
            res = !regs.F.S
        case 7:
            res = regs.F.S
        default:
            fatalError()
        }
        return res
        }
    
    func incR(_ r :UnsafeMutablePointer<UInt8>) {
        r.pointee &+= 1
        regs.F.S = r.pointee&0x80 != 0
        regs.F.Z = r.pointee == 0
        regs.F.H = r.pointee&0x0f == 0
        regs.F.P = r.pointee == 0x80
        regs.F.N = false
        // panic(fmt.Sprintf("%08b", *r&0x0f))
    }
    
    func decR(_ r :UnsafeMutablePointer<UInt8>) {
        regs.F.H = r.pointee&0x0f == 0
        r.pointee = r.pointee &- 1
        regs.F.S = r.pointee&0x80 != 0
        regs.F.Z = r.pointee == 0
        regs.F.P = r.pointee == 0x7f
        regs.F.N = true
    }
        
    func getIXYn(_ n :UInt8) -> UInt16 {
        let reg = regs.indexRegsPtrs[indexIdx]
        let i = Int16(Int8(bitPattern:n))
        let ix = Int16(bitPattern: reg.pointee) &+ i
        return UInt16(bitPattern: ix)
    }
    
    func res(_ b: UInt8, _ v: UnsafeMutablePointer<UInt8>) {
        let res:UInt8 = 1 << b
        v.pointee &= (0xff^res)
    }
    
    func set(_ b: UInt8, _ v: UnsafeMutablePointer<UInt8>) {
        let res:UInt8 = 1 << b
        v.pointee |= res
    }
    
    func bit(_ b :UInt8, _ v :UInt8) {
        let res:UInt8 = 1 << b
        let nV = v & res
        regs.F.S = nV&0x80 != 0
        regs.F.Z = nV == 0
        regs.F.H = true
        regs.F.P = parityTable[Int(nV)]
        regs.F.N = false
    }
    
    func adcA(_ s: UInt8) {
        var res = UInt16(regs.A) &+ UInt16(s)
        if regs.F.C {
            res &+= 1
        }
        let lookup = ((regs.A & 0x88) >> 3) | ((s & 0x88) >> 2) | ((UInt8(res&0xff) & 0x88) >> 1)
        regs.A = UInt8(res&0xff)
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = halfcarryAddTable[Int(lookup)&0x07]
        regs.F.P = overflowAddTable[Int(lookup)>>4]
        regs.F.N = false
        regs.F.C = (res & 0x100) == 0x100
    }
    
    func adcHL(_ ss :UInt16) {
        var hl = regs.HL
        var res = UInt32(hl) + UInt32(ss)
        if regs.F.C {
            res += 1
        }
        let lookup = UInt8(((hl & 0x8800) >> 11) | ((ss & 0x8800) >> 10) | ((uint16(res & 0xffff) & 0x8800) >> 9))
        hl = UInt16(res & 0xffff)
        regs.HL = hl
        regs.F.S = regs.H&0x80 != 0
        regs.F.Z = hl == 0
        regs.F.H = halfcarryAddTable[Int(lookup)&0x07]
        regs.F.P = overflowAddTable[Int(lookup)>>4]
        regs.F.N = false
        regs.F.C = (res & 0x10000) != 0
    }
    
    func cp(_ r:UInt8) {
        let a = UInt16(regs.A)
        let result = a &- UInt16(r)
        let lookup = ((regs.A & 0x88) >> 3) | (((r) & 0x88) >> 2) | ((UInt8(result&0xff) & 0x88) >> 1)
        
        regs.F.S = result&0x80 != 0
        regs.F.Z = result == 0
        regs.F.H = halfcarrySubTable[Int(lookup)&0x07]
        regs.F.P = overflowSubTable[Int(lookup)>>4]
        regs.F.N = true
        regs.F.C = ((result) & 0x100) == 0x100
    }
    
    func addA(_ r:UInt8) {
        let a = UInt16(regs.A)
        let result = a &+ UInt16(r)
        let lookup = ((regs.A & 0x88) >> 3) | (((r) & 0x88) >> 2) | ((UInt8(result&0xff) & 0x88) >> 1)
        regs.A = UInt8(result & 0x00ff)
        
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = halfcarryAddTable[Int(lookup)&0x07]
        regs.F.P = overflowAddTable[Int(lookup)>>4]
        regs.F.N = false
        regs.F.C = ((result) & 0x100) != 0
    }
    
    func subA(_ r:UInt8) {
        let a = UInt16(regs.A)
        let result = a &- UInt16(r)
        let lookup = ((regs.A & 0x88) >> 3) | (((r) & 0x88) >> 2) | ((UInt8(result&0xff) & 0x88) >> 1)
        regs.A = UInt8(result & 0x00ff)
        
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = halfcarrySubTable[Int(lookup)&0x07]
        regs.F.P = overflowSubTable[Int(lookup)>>4]
        regs.F.N = true
        regs.F.C = ((result) & 0x100) == 0x100
    }
    
    func xor(_ s:UInt8) {
        regs.A = regs.A ^ s
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = false
        regs.F.P = parityTable[Int(regs.A)]
        regs.F.N = false
        regs.F.C = false
    }
    
    func and(_ s:UInt8) {
        regs.A = regs.A & s
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = true
        regs.F.P = parityTable[Int(regs.A)]
        regs.F.N = false
        regs.F.C = false
    }
    
    func or(_ s:UInt8) {
        // TODO: review p/v flag
        regs.A = regs.A | s
        regs.F.S = regs.A&0x80 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = false
        regs.F.P = parityTable[Int(regs.A)]
        regs.F.N = false
        regs.F.C = false
    }
    
    func sbcA(_ s:UInt8) {
        var res = UInt16(regs.A) &- UInt16(s)
        if regs.F.C {
            res &-= 1
        }
        let lookup = ((regs.A & 0x88) >> 3) | ((s & 0x88) >> 2) | UInt8((res&0x88)>>1)
//        lookup :=  ((regs.A & 0x88) >> 3) | ((s & 0x88) >> 2) | byte(res&0x88>>1)

//        print("->",lookup,"-",res,"-",regs.A,"-",s)
        regs.A = UInt8(res&0xff)
        regs.F.S = regs.A&0x0080 != 0
        regs.F.Z = regs.A == 0
        regs.F.H = halfcarrySubTable[Int(lookup)&0x07]
        regs.F.P = overflowSubTable[Int(lookup)>>4]
        regs.F.N = true
        regs.F.C = (res & 0x100) == 0x100
    }
    
    func sbcHL(_ ss :UInt16) {
        let hl = regs.HL
        var res = UInt32(hl) &- UInt32(ss)
        if regs.F.C {
            res &-= 1
        }
        regs.HL = uint16(res&0xffff)
        
        let lookup = UInt8(((hl & 0x8800) >> 11) | ((ss & 0x8800) >> 10) | ((UInt16(res&0xffff) & 0x8800) >> 9))
        regs.F.N = true
        regs.F.S = regs.H&0x80 != 0 // negative
        regs.F.Z = res == 0
        regs.F.C = (res & 0x10000) != 0
        regs.F.P = overflowSubTable[Int(lookup)>>4]
        regs.F.H = halfcarrySubTable[Int(lookup)&0x07]
    }
    
    func sbcHL(ss :UInt16) {
        let hl = regs.HL
        var res = UInt32(hl) &- UInt32(ss)
        if regs.F.C {
            res -= 1
        }
        regs.HL = uint16(res&0xffff)

        let lookup = UInt8(((hl & 0x8800) >> 11) | ((ss & 0x8800) >> 10) | ((uint16(res) & 0x8800) >> 9))
        regs.F.N = true
        regs.F.S = regs.H&0x80 != 0 // negative
        regs.F.Z = res == 0
        regs.F.C = (res & 0x10000) != 0
        regs.F.P = overflowSubTable[Int(lookup)>>4]
        regs.F.H = halfcarrySubTable[Int(lookup)&0x07]
    }
}
