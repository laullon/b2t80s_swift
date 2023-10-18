//
//  ops.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

func push_m1(cpu: z80) {
    cpu.regs.SP = (cpu.regs.SP &- 2)
    if cpu.pushF != nil {
        cpu.pushF!(cpu)
    }
}

func ini(cpu: z80) { // TODO review tests changes
    let inOP = inOP(from: cpu.regs.BC, f: ini_m1)
    cpu.scheduler.append(inOP)
}

func ini_m1(cpu: z80, data :UInt8) {
    let mw = mw(cpu.regs.HL, data, ini_m2)
    cpu.scheduler.append(Exec(l: 1,f: {cpu in ()}),mw)
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: ini_m3))
    }
}

func ini_m2(cpu: z80) {
    cpu.regs.B &-= 1
    cpu.regs.HL = (cpu.regs.HL &+ 1)
    cpu.regs.F.N = true
    cpu.regs.F.Z = cpu.regs.B == 0
}

func ini_m3(cpu: z80) {
    if cpu.regs.B != 0 {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func ind(cpu: z80) { // TODO review tests changes
    let inOP = inOP(from: cpu.regs.BC, f: ind_m1)
    cpu.scheduler.append(Exec(l: 1, f:{cpu in ()}), inOP)
}

func ind_m1(cpu: z80, data :UInt8) {
    let hl = cpu.regs.HL
    let mw = mw(hl, data, ind_m2)
    cpu.scheduler.append(mw)
}

func ind_m2(cpu: z80) {
    let hl = cpu.regs.HL
    cpu.regs.B &-= 1
    cpu.regs.HL = (hl - 1)
    cpu.regs.F.N = true
    cpu.regs.F.Z = cpu.regs.B == 0
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: ind_m3))
    }
}

func ind_m3(cpu: z80) {
    if cpu.regs.B != 0 {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func outi(cpu: z80) { // TODO review tests changes
    let mr = mr(cpu.regs.HL, outi_m2)
    cpu.scheduler.append(Exec(l: 1,f:{cpu in ()}), mr)
}

func outi_m2(cpu: z80, data :UInt8) {
    cpu.regs.B &-= 1
    let out = out(addr: cpu.regs.BC, data: data, f: outi_m3)
    cpu.scheduler.append(Exec(l: 1,f: {cpu in ()}), out)
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: {cpu in
            if cpu.regs.B != 0 {
                cpu.regs.PC = cpu.regs.PC &- 2
            }
        }))
    }
}

func outi_m3(cpu: z80) {
    cpu.regs.HL = (cpu.regs.HL &+ 1)
    cpu.regs.F.Z = cpu.regs.B == 0
    cpu.regs.F.S = cpu.regs.B&0x80 != 0
    cpu.regs.F.N = cpu.regs.B&0x80 == 0
    cpu.regs.F.H = true
    cpu.regs.F.P = cpu.parityTable[Int(cpu.regs.B)]
}

func outd(cpu: z80) { // TODO review tests changes
    let mr = mr(cpu.regs.HL, outd_m1)
    cpu.scheduler.append(Exec(l: 1,f:{cpu in ()}), mr)
}

func outd_m1(cpu: z80, data :UInt8) {
    cpu.regs.B &-= 1
    let out = out(addr: cpu.regs.BC, data: data, f: outd_m2)
    cpu.scheduler.append(Exec(l: 1, f:{cpu in ()}), out)
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: outd_m3))
    }
}

func outd_m2(cpu: z80) {
    cpu.regs.HL = (cpu.regs.HL &- 1)
    cpu.regs.F.Z = cpu.regs.B == 0
    cpu.regs.F.S = cpu.regs.B&0x80 != 0
    cpu.regs.F.N = cpu.regs.B&0x80 == 0
    cpu.regs.F.H = true
    cpu.regs.F.P = cpu.parityTable[Int(cpu.regs.B)]
}

func outd_m3(cpu: z80) {
    if cpu.regs.B != 0 {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func cpi(cpu: z80) {
    let mr = mr(cpu.regs.HL, cpi_m1)
    cpu.scheduler.append(mr)
}

var cpi_result :UInt8 = 0

func cpi_m1(cpu: z80, data :UInt8) {
    
    let val = data
    cpi_result = cpu.regs.A &- val
    let lookup = (cpu.regs.A&0x08)>>3 | (val&0x08)>>2 | (cpi_result&0x08)>>1
    cpu.regs.F.H = cpu.halfcarrySubTable[Int(lookup)]
    
    cpu.scheduler.append(Exec(l: 5, f: cpi_m2))
}

func cpi_m2(cpu: z80) {
    var bc = cpu.regs.BC
    bc -= 1
    cpu.regs.BC = (bc)
    cpu.regs.HL = (cpu.regs.HL &+ 1)
    
    cpu.regs.F.S = cpi_result&0x80 != 0
    cpu.regs.F.Z = cpi_result == 0
    cpu.regs.F.P = bc != 0
    cpu.regs.F.N = true
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: cpi_m3))
    }
}

func cpi_m3(cpu: z80) {
    if (cpu.regs.BC) != 0 && (cpi_result != 0) {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func cpd(cpu: z80) {
    let hl = cpu.regs.HL
    let mr = mr(hl, cpd_m1)
    cpu.scheduler.append(mr)
}

func cpd_m1(cpu: z80, data :UInt8) {
    let val = data
    let result = cpu.regs.A &- UInt8(val)
    let lookup = (cpu.regs.A & 0x08) >> 3 | (val & 0x08) >> 2 | (result & 0x08) >> 1
    
    cpu.regs.F.S = result&0x80 != 0
    cpu.regs.F.Z = result == 0
    cpu.regs.F.H = cpu.halfcarrySubTable[Int(lookup)]
    
    cpu.scheduler.append(Exec(l: 5, f: cpd_m2))
}

func cpd_m2(cpu: z80) {
    var bc = cpu.regs.BC
    var hl = cpu.regs.HL
    
    bc -= 1
    hl -= 1
    
    cpu.regs.BC = (bc)
    cpu.regs.HL = (hl)
    
    cpu.regs.F.P = bc != 0
    cpu.regs.F.N = true
    
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: cpd_m3))
    }
}

func cpd_m3(cpu: z80) {
    if (cpu.regs.BC != 0) && (!cpu.regs.F.Z) {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func ldi(cpu: z80) {
    let hl = cpu.regs.HL
    let mr = mr(hl, ldi_m1)
    cpu.scheduler.append(mr)
}

func ldi_m1(cpu: z80, data :UInt8) {
    let v = data
    let de = cpu.regs.DE
    let mw = mw(de, v, ldi_m2)
    cpu.scheduler.append(Exec(l: 2,f:{cpu in ()}), mw)
}

func ldi_m2(cpu: z80) {
    var bc = cpu.regs.BC
    var de = cpu.regs.DE
    var hl = cpu.regs.HL
    
    bc &-= 1
    de &+= 1
    hl &+= 1
    
    cpu.regs.BC = (bc)
    cpu.regs.DE = (de)
    cpu.regs.HL = (hl)
    
    cpu.regs.F.P = bc != 0
    cpu.regs.F.H = false
    cpu.regs.F.N = false
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: ldi_m3))
    }
}

func ldi_m3(cpu: z80) {
    if cpu.regs.BC != 0 {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

func ldd(cpu: z80) {
    let hl = cpu.regs.HL
    let mr = mr(hl, ldd_m1)
    cpu.scheduler.append(mr)
}

func ldd_m1(cpu: z80, data :UInt8) {
    let de = cpu.regs.DE
    let v = data
    let mw = mw(de, v, ldd_m2)
    cpu.scheduler.append(Exec(l: 2,f: {cpu in ()}), mw)
}

func ldd_m2(cpu: z80) {
    var bc = cpu.regs.BC
    var de = cpu.regs.DE
    var hl = cpu.regs.HL
    
    bc &-= 1
    de &-= 1
    hl &-= 1
    
    cpu.regs.BC = (bc)
    cpu.regs.DE = (de)
    cpu.regs.HL = (hl)
    
    cpu.regs.F.P = bc != 0
    cpu.regs.F.H = false
    cpu.regs.F.N = false
    if cpu.fetched.opCode > 0xAF {
        cpu.scheduler.append(Exec(l: 5, f: ldd_m3))
    }
}

func ldd_m3(cpu: z80) {
    if cpu.regs.BC != 0 {
        cpu.regs.PC = cpu.regs.PC &- 2
    }
}

var spv :UInt16 = 0

func exSP(cpu: z80) {
    var rH, rL :UInt8
    switch cpu.indexIdx {
    case 0:
        rH = cpu.regs.H
        rL = cpu.regs.L
    case 1:
        rH = cpu.regs.IXH
        rL = cpu.regs.IXL
    case 2:
        rH = cpu.regs.IYH
        rL = cpu.regs.IYL
    default:
        fatalError()
    }
    let mr1 = mr(cpu.regs.SP, exSP_m1)
    let mr2 = mr(cpu.regs.SP &+ 1, exSP_m2)
    let mw1 = mw(cpu.regs.SP, rL, {cpu in ()})
    let mw2 = mw(cpu.regs.SP &+ 1, rH, exSP_m3)
    cpu.scheduler.append(mr1, Exec(l: 1), mr2, mw1, Exec(l: 2, f:{cpu in ()}), mw2)
}

func exSP_m1(cpu: z80, data :UInt8) { spv = UInt16(data) }
func exSP_m2(cpu: z80, data :UInt8) { spv |= UInt16(data) << 8 }
func exSP_m3(cpu: z80) {
    switch cpu.indexIdx {
    case 0:
       cpu.regs.HL = spv
    case 1:
        cpu.regs.IX = spv
    case 2:
        cpu.regs.IY = spv
    default:
        fatalError()
    }
}

func addIXY(cpu: z80) {
    let regI = cpu.regs.indexRegsPtrs[cpu.indexIdx]
    let rIdx = (cpu.fetched.opCode >> 4) & 0b11
    let reg: UInt16
    switch rIdx {
    case 0b00:
        reg = cpu.regs.BC
    case 0b01:
        reg = cpu.regs.DE
    case 0b10:
        reg = regI.pointee
    case 0b11:
        reg = cpu.regs.SP
    default:
        fatalError()
    }


    let ix = regI.pointee
    let result = UInt32(ix) + UInt32(reg)
    let lookup = UInt8(((ix & 0x0800) >> 11) | ((reg & 0x0800) >> 10) | ((uint16(result&0xffff) & 0x0800) >> 9))
    regI.pointee = UInt16(result&0xffff)

    cpu.regs.F.N = false
    cpu.regs.F.H = cpu.halfcarryAddTable[Int(lookup)]
    cpu.regs.F.C = (result & 0x10000) != 0
}

func outNa(cpu: z80) {
    let port = UInt16(cpu.fetched.n) + (UInt16(cpu.regs.A)<<8)
    cpu.scheduler.append(out(addr: port, data: cpu.regs.A))
}

var inAn_f :UInt8 = 0

func inAn(cpu: z80) {
    inAn_f = cpu.regs.F.GetByte()
    let port = UInt16(cpu.fetched.n) + (UInt16(cpu.regs.A)<<8)
    cpu.scheduler.append(inOP(from: port, f: inAn_m1))
}

func inAn_m1(cpu: z80, data :UInt8) {
    cpu.regs.A = data
    cpu.regs.F.SetByte(inAn_f)
}

func inRc(cpu: z80) {
    cpu.scheduler.append(inOP(from: cpu.regs.BC, f: inRc_m1))
}

func inRc_m1(cpu: z80, data :UInt8) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    r.pointee = data
    } else {
        fatalError()
    }
}

func inC(cpu: z80) {
    cpu.scheduler.append(inOP(from: cpu.regs.BC, f: {cpu,data in ()}))
}

func outCr(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.scheduler.append(out(addr: cpu.regs.BC, data: r.pointee))
    } else {
        fatalError()
    }
}

func outC0(cpu: z80) {
    cpu.scheduler.append(out(addr: cpu.regs.BC, data: 0))
}

func retCC(cpu: z80) {
    let ccIdx = cpu.fetched.opCode >> 3 & 0b111
    let branch = cpu.checkCondition(ccIdx)
    if branch {
        cpu.popFromStack({cpu,data in
            cpu.regs.PC = data
        })
    }
}

func ret(cpu: z80) {
    cpu.popFromStack({cpu, data in
        cpu.regs.PC = data
    })
}

func rstP(cpu: z80) {
    cpu.pushToStack(cpu.regs.PC, rstP_m1)
}

func rstP_m1(cpu: z80) {
    let newPCs :[UInt16] = [0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38]
    let pIdx = cpu.fetched.opCode >> 3 & 0b111
    cpu.regs.PC = newPCs[Int(pIdx)]
}

func jpCC(cpu: z80) {
    let ccIdx = cpu.fetched.opCode >> 3 & 0b111
    let branch = cpu.checkCondition(ccIdx)
    if branch {
        cpu.regs.PC = cpu.fetched.nn
    }
}

func callCC(cpu: z80) {
    let ccIdx = cpu.fetched.opCode >> 3 & 0b111
    let branch = cpu.checkCondition(ccIdx)
    if branch {
        cpu.scheduler.append(Exec(l: 1, f: callCC_m2))
    }
}

func callCC_m2(cpu: z80) { cpu.pushToStack(cpu.regs.PC, call_m1) }

func call(cpu: z80) {
    cpu.pushToStack(cpu.regs.PC, call_m1)
}

func call_m1(cpu: z80) { cpu.regs.PC = cpu.fetched.nn }

var pushF :(_ cpu: z80)->() = {cpu in ()}

var popData :UInt16 = 0
var popF :(_ cpu: z80, _ data :UInt16)->() = {cpu,data in ()}

func pop_m1(cpu: z80, data :UInt8) { popData = UInt16(data) }

func pop_m2(cpu: z80, data :UInt8) {
    popData |= (uint16(data) << 8)
    cpu.regs.SP = (cpu.regs.SP &+ 2)
    popF(cpu, popData)
}

func popSS(cpu: z80) {
    cpu.popFromStack(popSS_m1)
}

func popSS_m1(_ cpu: z80, _ data :UInt16) {
    let t = cpu.fetched.opCode >> 4 & 0b11
    switch t {
    case 0b00:
        cpu.regs.BC = (data)
    case 0b01:
        cpu.regs.DE = (data)
    case 0b10:
        cpu.regs.HL = (data)
    case 0b11:
        cpu.regs.A = UInt8(data >> 8)
        cpu.regs.F.SetByte(UInt8(data&0xff))
    default:
        fatalError()
    }
}

func pushSS(cpu: z80) {
    let t = cpu.fetched.opCode >> 4 & 0b11
    var data :UInt16
    switch t {
    case 0b00:
        data = cpu.regs.BC
    case 0b01:
        data = cpu.regs.DE
    case 0b10:
        data = cpu.regs.HL
    case 0b11:
        data = UInt16(cpu.regs.A) << 8
        data |= UInt16(cpu.regs.F.GetByte())
    default:
        fatalError()
    }
    cpu.pushToStack(data, {cpu in ()})
}

func ldDDmm(cpu: z80) {
    let t = cpu.fetched.opCode >> 4 & 0b11
    switch t {
    case 0b00:
        cpu.regs.B = cpu.fetched.n2
        cpu.regs.C = cpu.fetched.n
    case 0b01:
        cpu.regs.D = cpu.fetched.n2
        cpu.regs.E = cpu.fetched.n
    case 0b10:
        cpu.regs.H = cpu.fetched.n2
        cpu.regs.L = cpu.fetched.n
    case 0b11:
        cpu.regs.S = cpu.fetched.n2
        cpu.regs.P = cpu.fetched.n
    default:
        fatalError()
    }
}

func ldBCa(cpu: z80) {
    let pos = cpu.regs.BC
    cpu.scheduler.append(mw(pos, cpu.regs.A, {cpu in ()}))
}

func ldDEa(cpu: z80) {
    let pos = cpu.regs.DE
    cpu.scheduler.append(mw(pos, cpu.regs.A, {cpu in ()}))
}

func ldNNhl(cpu: z80) {
    let mm = cpu.fetched.nn
    let mw1 = mw(mm, cpu.regs.L, {cpu in ()})
    let mw2 = mw(mm+1, cpu.regs.H, {cpu in ()})
    cpu.scheduler.append(mw1, mw2)
}

func ldNNIXY(cpu: z80) {
    let reg = cpu.regs.indexRegsPtrs[cpu.indexIdx]
    let mm = cpu.fetched.nn
    let mw1 = mw(mm, UInt8(reg.pointee & 0x00ff), {cpu in ()})
    let mw2 = mw(mm+1, UInt8((reg.pointee & 0xff00) >> 8), {cpu in ()})
    cpu.scheduler.append(mw1, mw2)
}

func ldNNa(cpu: z80) {
    let mm = cpu.fetched.nn
    let mw1 = mw(mm, cpu.regs.A, {cpu in ()})
    cpu.scheduler.append(mw1)
}

var hlv :UInt8 = 0

func rrd(cpu: z80) {
    let mr = mr(cpu.regs.HL, rrd_m1)
    cpu.scheduler.append(mr)
}

func rrd_m1(cpu: z80, data :UInt8) {
    hlv = data
    let mw = mw(cpu.regs.HL, (cpu.regs.A<<4 | hlv>>4), rrd_m2)
    cpu.scheduler.append(Exec(l: 4,f:{cpu in ()}), mw)
}

func rrd_m2(cpu: z80) {
    cpu.regs.A = (cpu.regs.A & 0xf0) | (hlv & 0x0f)
    cpu.regs.F.S = cpu.regs.A&0x80 != 0
    cpu.regs.F.Z = cpu.regs.A == 0
    cpu.regs.F.P = cpu.parityTable[Int(cpu.regs.A)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func rld(cpu: z80) {
    let mr = mr(cpu.regs.HL, rld_m1)
    cpu.scheduler.append(mr)
}

func rld_m1(cpu: z80, data :UInt8) {
    hlv = data
    let mw = mw(cpu.regs.HL, (hlv<<4 | cpu.regs.A&0x0f), rld_m2)
    cpu.scheduler.append(Exec(l: 4), mw)
}

func rld_m2(cpu: z80) {
    cpu.regs.A = (cpu.regs.A & 0xf0) | (hlv >> 4)
    cpu.regs.F.S = cpu.regs.A&0x80 != 0
    cpu.regs.F.Z = cpu.regs.A == 0
    cpu.regs.F.P = cpu.parityTable[Int(cpu.regs.A)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func ldNNdd(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    let mm = cpu.fetched.nn
    let mw1 = mw(mm, UInt8(reg.pointee&0x00ff), {cpu in ()})
    let mw2 = mw(mm+1, UInt8((reg.pointee&0xff00)>>8), {cpu in ()})
    cpu.scheduler.append(mw1, mw2)
}

func ldDDnn(cpu: z80) {
    let mm = cpu.fetched.nn
    let mr1 = mr(mm, ldDDnn_m1)
    let mr2 = mr(mm+1, ldDDnn_m2)
    cpu.scheduler.append(mr1, mr2)
}

func ldDDnn_m1(cpu: z80, data :UInt8) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    reg.pointee = UInt16(data) + reg.pointee&0xff00
}

func ldDDnn_m2(cpu: z80, data :UInt8) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    reg.pointee = UInt16(data)<<8 + reg.pointee&0x00ff
}

func ldAi(cpu: z80) {
    cpu.regs.A = cpu.regs.I
    cpu.regs.F.S = cpu.regs.A&0x80 != 0
    cpu.regs.F.Z = cpu.regs.A == 0
    cpu.regs.F.H = false
    cpu.regs.F.P = cpu.regs.IFF2
    cpu.regs.F.N = false
}

func ldAr(cpu: z80) {
    cpu.regs.A = cpu.regs.R
    cpu.regs.F.S = cpu.regs.R&0x80 != 0
    cpu.regs.F.Z = cpu.regs.R == 0
    cpu.regs.F.H = false
    cpu.regs.F.P = cpu.regs.IFF2
    cpu.regs.F.N = false
}

func ldHLnn(cpu: z80) {
    let mm = cpu.fetched.nn
    let mr1 = mr(mm, ldHLnn_m1)
    let mr2 = mr(mm+1, ldHLnn_m2)
    cpu.scheduler.append(mr1, mr2)
}

func ldHLnn_m1(cpu: z80, data :UInt8) { cpu.regs.L = data }
func ldHLnn_m2(cpu: z80, data :UInt8) { cpu.regs.H = data }

func ldIXYnn(cpu: z80) {
    let mm = cpu.fetched.nn
    let mr1 = mr(mm, ldIXYnn_m1)
    let mr2 = mr(mm+1, ldIXYnn_m2)
    cpu.scheduler.append(mr1, mr2)
}

func ldIXYnn_m1(cpu: z80, data :UInt8) {
    let reg = cpu.regs.indexRegsLPtrs[cpu.indexIdx]
    reg.pointee = data
}

func ldIXYnn_m2(cpu: z80, data :UInt8) {
    let reg = cpu.regs.indexRegsHPtrs[cpu.indexIdx]
    reg.pointee = data
}

func ldAnn(cpu: z80) {
    let mm = cpu.fetched.nn
    let mr1 = mr(mm, ldAnn_n1)
    cpu.scheduler.append(mr1)
}

func ldAnn_n1(cpu: z80, data :UInt8) { cpu.regs.A = data }

func ldHLn(cpu: z80) {
    let mw1 = mw(cpu.regs.HL, cpu.fetched.n, {cpu in ()})
    cpu.scheduler.append(mw1)
}

func ldIXYdN(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mw1 = mw(addr, cpu.fetched.n2, {cpu in ()})
    cpu.scheduler.append(mw1)
}

func ldIXYdR(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    let reg = cpu.regs.regsPtrs[Int(rIdx)]
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mw1 = mw(addr, reg!.pointee, {cpu in ()})
    cpu.scheduler.append(mw1)
}

func incSS(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    var v = reg.pointee
    v &+= 1
    reg.pointee = v
}

func decSS(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    var v = reg.pointee
    v &-= 1
    reg.pointee = v
}

func incR(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.incR(r)
    } else {
        fatalError()
    }
}

func incHL(cpu: z80) {
    let mr = mr(cpu.regs.HL, {cpu, data in
        var r = data
        r &+= 1
        let mw = mw(cpu.regs.HL, r, {cpu in ()})
        cpu.regs.F.S = r&0x80 != 0
        cpu.regs.F.Z = r == 0
        cpu.regs.F.H = r&0x0f == 0
        cpu.regs.F.P = r == 0x80
        cpu.regs.F.N = false
        
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func incIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, {cpu, data in
        var r = data
        r &+= 1
        let mw = mw(addr, r, {cpu in ()})
        cpu.regs.F.S = r&0x80 != 0
        cpu.regs.F.Z = r == 0
        cpu.regs.F.H = r&0x0f == 0
        cpu.regs.F.P = r == 0x80
        cpu.regs.F.N = false
        
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func decR(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    cpu.decR(r)
    } else {
        fatalError()
    }
}

func addAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.addA(r.pointee)
    } else {
        fatalError()
    }
}

func adcAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.adcA(r.pointee)
    } else {
        fatalError()
    }
}

func subAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.subA(r.pointee)
    } else {
        fatalError()
    }
}

func sbcAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.sbcA(r.pointee)
    } else {
        fatalError()
    }
}

func andAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.and(r.pointee)
    } else {
        fatalError()
    }
}

func orAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.or(r.pointee)
    } else {
        fatalError()
    }
}

func xorAr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        cpu.xor(r.pointee)
    } else {
        fatalError()
    }
}

func cpR(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    cpu.cp(r.pointee)
    } else {
        fatalError()
    }
}

func addAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, addAhl_m1)
    cpu.scheduler.append(mr)
}

func addAhl_m1(cpu: z80, data :UInt8) { cpu.addA(data) }

func subAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, subAhl_m1)
    cpu.scheduler.append(mr)
}

func subAhl_m1(cpu: z80, data :UInt8) { cpu.subA(data) }

func sbcAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, sbcAhl_m1)
    cpu.scheduler.append(mr)
}

func sbcAhl_m1(cpu: z80, data :UInt8) { cpu.sbcA(data) }

func adcAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, adcAhl_m1)
    cpu.scheduler.append(mr)
}

func adcAhl_m1(cpu: z80, data :UInt8) { cpu.adcA(data) }

func andAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, andAhl_m1)
    cpu.scheduler.append(mr)
}

func andAhl_m1(cpu: z80, data :UInt8) { cpu.and(data) }

func orAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, orAhl_m1)
    cpu.scheduler.append(mr)
}

func orAhl_m1(cpu: z80, data :UInt8) { cpu.or(data) }

func xorAhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, xorAhl_m1)
    cpu.scheduler.append(mr)
}

func xorAhl_m1(cpu: z80, data :UInt8) { cpu.xor(data) }

func cpHl(cpu: z80) {
    let mr = mr(cpu.regs.HL, cpHl_m1)
    cpu.scheduler.append(mr)
}

func cpHl_m1(cpu: z80, data :UInt8) { cpu.cp(data) }

func decHL(cpu: z80) {
    let mr = mr(cpu.regs.HL,
                {cpu, data in
        var r = data
        cpu.regs.F.H = r&0x0f == 0
        r = r &- 1
        cpu.regs.F.S = r&0x80 != 0
        cpu.regs.F.Z = r == 0
        cpu.regs.F.P = r == 0x7f
        cpu.regs.F.N = true
        
        let mw = mw(cpu.regs.HL, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func decIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr,
                {cpu, data in
        var r = data
        cpu.regs.F.H = r&0x0f == 0
        r &-= 1
        cpu.regs.F.S = r&0x80 != 0
        cpu.regs.F.Z = r == 0
        cpu.regs.F.P = r == 0x7f
        cpu.regs.F.N = true
        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    }
    )
    cpu.scheduler.append(mr)
}

func ldRn(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        r.pointee = cpu.fetched.n
    } else {
        fatalError()
    }
}

func ldRhl(cpu: z80) {
    let mr = mr(cpu.regs.HL, ldR_m1)
    cpu.scheduler.append(mr)
}

func ldRixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, ldR_m1)
    cpu.scheduler.append(mr)
}

func ldR_m1(cpu: z80, data :UInt8) {
    let rIdx = cpu.fetched.opCode >> 3 & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        r.pointee = data
    } else {
        fatalError()
    }
}

func addAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, addAixyD_m1)
    cpu.scheduler.append(mr)
}

func addAixyD_m1(cpu: z80, data :UInt8) { cpu.addA(data) }

func adcAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, adcAixyD_m1)
    cpu.scheduler.append(mr)
}

func adcAixyD_m1(cpu: z80, data :UInt8) { cpu.adcA(data) }

func subAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, subAixyD_m1)
    cpu.scheduler.append(mr)
}

func subAixyD_m1(cpu: z80, data :UInt8) { cpu.subA(data) }

func sbcAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, sbcAixyD_m1)
    cpu.scheduler.append(mr)
}

func sbcAixyD_m1(cpu: z80, data :UInt8) { cpu.sbcA(data) }

func andAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, andAixyD_m1)
    cpu.scheduler.append(mr)
}

func andAixyD_m1(cpu: z80, data :UInt8) { cpu.and(data) }

func xorAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, xorAixyD_m1)
    cpu.scheduler.append(mr)
}

func xorAixyD_m1(cpu: z80, data :UInt8) { cpu.xor(data) }

func cpAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, cpAixyD_m1)
    cpu.scheduler.append(mr)
}

func cpAixyD_m1(cpu: z80, data :UInt8) { cpu.cp(data) }

func orAixyD(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, orAixyD_m1)
    cpu.scheduler.append(mr)
}

func orAixyD_m1(cpu: z80, data :UInt8) { cpu.or(data) }

func ldHLr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        let mr = mw(cpu.regs.HL, r.pointee, {cpu in ()})
        cpu.scheduler.append(mr)
    } else {
        fatalError()
    }
}

func ldIXYHr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    let rH = cpu.regs.indexRegsHPtrs[Int(cpu.indexIdx)]
    
    switch rIdx{
    case 0b100:
        rH.pointee = cpu.regs.indexRegsHPtrs[Int(cpu.indexIdx)].pointee
    case 0b101:
        rH.pointee = cpu.regs.indexRegsLPtrs[Int(cpu.indexIdx)].pointee
    default:
        if let r = cpu.regs.regsPtrs[Int(rIdx)] {
            rH.pointee = r.pointee
        } else {
            fatalError()
        }
    }
}

func ldIXYLr(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    let rL = cpu.regs.indexRegsLPtrs[Int(cpu.indexIdx)]
    
    switch rIdx{
    case 0b100:
        rL.pointee = cpu.regs.indexRegsHPtrs[Int(cpu.indexIdx)].pointee
    case 0b101:
        rL.pointee = cpu.regs.indexRegsLPtrs[Int(cpu.indexIdx)].pointee
    default:
        if let r = cpu.regs.regsPtrs[Int(rIdx)] {
            rL.pointee = r.pointee
        } else {
            fatalError()
        }
    }
}

func incIXH(cpu: z80) {
    cpu.regs.IXH &+= 1
    cpu.regs.F.S = cpu.regs.IXH&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IXH == 0
    cpu.regs.F.H = cpu.regs.IXH&0x0f == 0
    cpu.regs.F.P = cpu.regs.IXH == 0x80
    cpu.regs.F.N = false
}

func decIXH(cpu: z80) {
    cpu.regs.F.H = cpu.regs.IXH&0x0f == 0
    cpu.regs.IXH &-= 1
    cpu.regs.F.S = cpu.regs.IXH&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IXH == 0
    cpu.regs.F.P = cpu.regs.IXH == 0x7f
    cpu.regs.F.N = true
}

func incIXL(cpu: z80) {
    cpu.regs.IXL &+= 1
    cpu.regs.F.S = cpu.regs.IXL&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IXL == 0
    cpu.regs.F.H = cpu.regs.IXL&0x0f == 0
    cpu.regs.F.P = cpu.regs.IXL == 0x80
    cpu.regs.F.N = false
}

func decIXL(cpu: z80) {
    cpu.regs.F.H = cpu.regs.IXL&0x0f == 0
    cpu.regs.IXL &-= 1
    cpu.regs.F.S = cpu.regs.IXL&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IXL == 0
    cpu.regs.F.P = cpu.regs.IXL == 0x7f
    cpu.regs.F.N = true
}

func incIYH(cpu: z80) {
    cpu.regs.IYH &+= 1
    cpu.regs.F.S = cpu.regs.IYH&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IYH == 0
    cpu.regs.F.H = cpu.regs.IYH&0x0f == 0
    cpu.regs.F.P = cpu.regs.IYH == 0x80
    cpu.regs.F.N = false
}

func decIYH(cpu: z80) {
    cpu.regs.F.H = cpu.regs.IYH&0x0f == 0
    cpu.regs.IYH &-= 1
    cpu.regs.F.S = cpu.regs.IYH&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IYH == 0
    cpu.regs.F.P = cpu.regs.IYH == 0x7f
    cpu.regs.F.N = true
}

func incIYL(cpu: z80) {
    cpu.regs.IYL &+= 1
    cpu.regs.F.S = cpu.regs.IYL&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IYL == 0
    cpu.regs.F.H = cpu.regs.IYL&0x0f == 0
    cpu.regs.F.P = cpu.regs.IYL == 0x80
    cpu.regs.F.N = false
}

func decIYL(cpu: z80) {
    cpu.regs.F.H = cpu.regs.IYL&0x0f == 0
    cpu.regs.IYL &-= 1
    cpu.regs.F.S = cpu.regs.IYL&0x80 != 0
    cpu.regs.F.Z = cpu.regs.IYL == 0
    cpu.regs.F.P = cpu.regs.IYL == 0x7f
    cpu.regs.F.N = true
}

func ldRr(cpu: z80) {
    let r1Idx = cpu.fetched.opCode >> 3 & 0b111
    let r2Idx = cpu.fetched.opCode & 0b111
    let r1 = cpu.regs.regsPtrs[Int(r1Idx)]
    let r2 = cpu.regs.regsPtrs[Int(r2Idx)]
    r1!.pointee = r2!.pointee
}

func rlca(cpu: z80) {
    cpu.regs.A = cpu.regs.A<<1 | cpu.regs.A>>7
    cpu.regs.F.C = cpu.regs.A&0x01 != 0
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func rla(cpu: z80) {
    let c = cpu.regs.F.C
    cpu.regs.F.C = cpu.regs.A&0b10000000 != 0
    cpu.regs.A = (cpu.regs.A << 1)
    if c {
        cpu.regs.A |= 1
    }
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

var cbFuncs :[(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>)->()] = [rlc, rrc, rl, rr, sla, sra, sll, srl]

func cbR(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    let fIdx = cpu.fetched.opCode >> 3
    let f = cbFuncs[Int(fIdx)]
        f(cpu, r)
    } else {
        fatalError()
    }
}

func cbHL(cpu: z80) {
    let mr = mr(cpu.regs.HL,
                {cpu, data in
        var b = data
        let fIdx = cpu.fetched.opCode >> 3
        cbFuncs[Int(fIdx)](cpu, &b)
        let mw = mw(cpu.regs.HL, b, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func cbIXYdr(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr, {cpu, data in
        var r = data
        let fIdx = (cpu.fetched.opCode >> 3) & 0b111
        cbFuncs[Int(fIdx)](cpu, &r)

        let rIdx = cpu.fetched.opCode & 0b111
        let reg = cpu.regs.regsPtrs[Int(rIdx)]
        reg!.pointee = r

        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func cbIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let mr = mr(addr,
                {cpu, data in
        var r = data
        let fIdx = (cpu.fetched.opCode >> 3) & 0b111
        cbFuncs[Int(fIdx)](cpu, &r)
        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func bit(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    let b = (cpu.fetched.opCode >> 3) & 0b111
    cpu.bit(b, r.pointee)
    } else {
        fatalError()
    }
}

func bitIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let b = (cpu.fetched.opCode >> 3) & 0b111
    let mr = mr(addr, {cpu, data in
        let r = data
        cpu.bit(b, r)
    })
    cpu.scheduler.append(mr)
}

func bitHL(cpu: z80) {
    let mr = mr(cpu.regs.HL,
                {cpu, data in
        let v = data
        let b = (cpu.fetched.opCode >> 3) & 0b111
        cpu.bit(b, v)
    })
    cpu.scheduler.append(mr)
}

func res(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
    let b = (cpu.fetched.opCode >> 3) & 0b111
    cpu.res(b, r)
    } else {
        fatalError()
    }
}

func resHL(cpu: z80) {
    let mr = mr(cpu.regs.HL,
                {cpu, data in
        var v = data
        let b = (cpu.fetched.opCode >> 3) & 0b111
        cpu.res(b, &v)
        let mw = mw(cpu.regs.HL, v, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func resIXYdR(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let b = (cpu.fetched.opCode >> 3) & 0b111
    let mr = mr(addr, {cpu,data in
        var r = data
        cpu.res(b, &r)

        let rIdx = cpu.fetched.opCode & 0b111
        let reg = cpu.regs.regsPtrs[Int(rIdx)]
        reg!.pointee = r

        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func resIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let b = (cpu.fetched.opCode >> 3) & 0b111
    let mr = mr(addr,
                {cpu, data in
        var r = data
        cpu.res(b, &r)
        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func set(cpu: z80) {
    let rIdx = cpu.fetched.opCode & 0b111
    if let r = cpu.regs.regsPtrs[Int(rIdx)] {
        let b = (cpu.fetched.opCode >> 3) & 0b111
        cpu.set(b, r)
    } else {
        fatalError()
    }
}

func setHL(cpu: z80) {
    let mr = mr(cpu.regs.HL,
                {cpu, data in
        var v = data
        let b = (cpu.fetched.opCode >> 3) & 0b111
        cpu.set(b, &v)
        let mw = mw(cpu.regs.HL, v, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func setIXYdR(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let b = (cpu.fetched.opCode >> 3) & 0b111
    let mr = mr(addr, {cpu, data in
        var r = data
        cpu.set(b, &r)

        let rIdx = cpu.fetched.opCode & 0b111
        let reg = cpu.regs.regsPtrs[Int(rIdx)]
        reg!.pointee = r

        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func setIXYd(cpu: z80) {
    let addr = cpu.getIXYn(cpu.fetched.n)
    let b = (cpu.fetched.opCode >> 3) & 0b111
    let mr = mr(addr,
                {cpu, data in
        var r = data
        cpu.set(b, &r)
        let mw = mw(addr, r, {cpu in ()})
        cpu.scheduler.append(mw)
    })
    cpu.scheduler.append(mr)
}

func rrca(cpu: z80) {
    cpu.regs.F.C = cpu.regs.A&0x01 != 0
    cpu.regs.F.H = false
    cpu.regs.F.N = false
    cpu.regs.A = (cpu.regs.A >> 1) | (cpu.regs.A << 7)
}

func rra(cpu: z80) {
    let c = cpu.regs.F.C
    cpu.regs.F.C = cpu.regs.A&1 != 0
    cpu.regs.A = (cpu.regs.A >> 1)
    if c {
        cpu.regs.A |= 0b10000000
    }
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func exafaf(cpu: z80) {
    (cpu.regs.A, cpu.regs.Aalt) = (cpu.regs.Aalt, cpu.regs.A)
    (cpu.regs.F, cpu.regs.Falt) = (cpu.regs.Falt, cpu.regs.F)
}

func exDEhl(cpu: z80) {
    (cpu.regs.D, cpu.regs.H) = (cpu.regs.H, cpu.regs.D)
    (cpu.regs.E, cpu.regs.L) = (cpu.regs.L, cpu.regs.E)
}

func exx(cpu: z80) {
    (cpu.regs.B, cpu.regs.Balt) = (cpu.regs.Balt, cpu.regs.B)
    (cpu.regs.C, cpu.regs.Calt) = (cpu.regs.Calt, cpu.regs.C)
    (cpu.regs.D, cpu.regs.Dalt) = (cpu.regs.Dalt, cpu.regs.D)
    (cpu.regs.E, cpu.regs.Ealt) = (cpu.regs.Ealt, cpu.regs.E)
    (cpu.regs.H, cpu.regs.Halt) = (cpu.regs.Halt, cpu.regs.H)
    (cpu.regs.L, cpu.regs.Lalt) = (cpu.regs.Lalt, cpu.regs.L)
}

func halt(cpu: z80) {
    cpu.halt = true
    cpu.regs.PC &-= 1
}

func addHLss(cpu: z80) {
    let rIdx = cpu.fetched.opCode >> 4 & 0b11
    let reg = cpu.regs.rRegsPtrs[Int(rIdx)]
    
    let hl = cpu.regs.HL
    let result = UInt32(hl) &+ UInt32(reg.pointee)
    let lookup = UInt8(((hl & 0x0800) >> 11) | ((reg.pointee & 0x0800) >> 10) | ((UInt16(result&0xffff) & 0x0800) >> 9))
    cpu.regs.HL = (UInt16(result&0xffff))
    
    cpu.regs.F.N = false
    cpu.regs.F.H = cpu.halfcarryAddTable[Int(lookup)]
    cpu.regs.F.C = (result & 0x10000) != 0
}

func ldAbc(cpu: z80) {
    let from = cpu.regs.BC
    let mr = mr(from, ldAbc_m1)
    cpu.scheduler.append(mr)
}

func ldAbc_m1(cpu: z80, data :UInt8) { cpu.regs.A = data }

func ldAde(cpu: z80) {
    let from = cpu.regs.DE
    let mr = mr(from, ldAde_m1)
    cpu.scheduler.append(mr)
}

func ldAde_m1(cpu: z80, data :UInt8) { cpu.regs.A = data }

func djnz(cpu: z80) {
    cpu.regs.B &-= 1
    if cpu.regs.B != 0 {
        cpu.scheduler.append(Exec(l: 5, f: jr))
    }
}

func jrnz(cpu: z80) {
    if !cpu.regs.F.Z {
        cpu.scheduler.append(Exec(l: 5, f: jr))
    }
}

func jrnc(cpu: z80) {
    if !cpu.regs.F.C {
        cpu.scheduler.append(Exec(l: 5, f: jr))
    }
}

func jrc(cpu: z80) {
    if cpu.regs.F.C {
        cpu.scheduler.append(Exec(l: 5, f: jr))
    }
}

func jrz(cpu: z80) {
    if cpu.regs.F.Z {
        cpu.scheduler.append(Exec(l: 5, f: jr))
    }
}

func jr(cpu: z80) {
    let jump = UInt8(cpu.fetched.n)
    if cpu.fetched.n & 0b10000000 == 0 {
        cpu.regs.PC &+= UInt16(jump)
    } else {
        cpu.regs.PC &-= UInt16((0xff^jump)+1)
    }
}

func scf(cpu: z80) {
    cpu.regs.F.H = false
    cpu.regs.F.N = false
    cpu.regs.F.C = true
}

func ccf(cpu: z80) {
    cpu.regs.F.H = cpu.regs.F.C
    cpu.regs.F.N = false
    cpu.regs.F.C = !cpu.regs.F.C
}

func daa(cpu: z80) {
    var c = cpu.regs.F.C
    var add = UInt8(0)
    if cpu.regs.F.H || ((cpu.regs.A & 0x0f) > 9) {
        add = 6
    }
    if c || (cpu.regs.A > 0x99) {
        add |= 0x60
    }
    if cpu.regs.A > 0x99 {
        c = true
    }
    if cpu.regs.F.N {
        cpu.subA(add)
    } else {
        cpu.addA(add)
    }
    cpu.regs.F.S = cpu.regs.A&0x80 != 0
    cpu.regs.F.Z = cpu.regs.A == 0
    cpu.regs.F.P = cpu.parityTable[Int(cpu.regs.A)]
    cpu.regs.F.C = c
}

func cpl(cpu: z80) {
    cpu.regs.A = 0xff^cpu.regs.A
    cpu.regs.F.H = true
    cpu.regs.F.N = true
}

func rlc(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    r.pointee = (r.pointee << 1) | (r.pointee >> 7)
    cpu.regs.F.C = r.pointee&1 != 0
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func rrc(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    cpu.regs.F.C = r.pointee&1 != 0
    r.pointee = (r.pointee << 7) | (r.pointee >> 1)
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func sll(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    cpu.regs.F.C = r.pointee&0x80 != 0
    r.pointee = UInt8((r.pointee << 1) | 0x01)
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func srl(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    cpu.regs.F.C = r.pointee&1 != 0
    r.pointee = UInt8(r.pointee >> 1)
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.N = false
    cpu.regs.F.H = false
}

func sla(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    cpu.regs.F.C = r.pointee&0x80 != 0
    r.pointee = (r.pointee << 1)
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func sra(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    cpu.regs.F.C = r.pointee&0x1 != 0
    let b7 = r.pointee & 0b10000000
    r.pointee = (r.pointee >> 1) | b7
    cpu.regs.F.S = r.pointee&0x0080 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func rr(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    let c = cpu.regs.F.C
    cpu.regs.F.C = r.pointee&0x1 != 0
    r.pointee = (r.pointee >> 1)
    if c {
        r.pointee |= 0b10000000
    }
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}

func rl(_ cpu: z80, _ r :UnsafeMutablePointer<UInt8>) {
    let c = cpu.regs.F.C
    cpu.regs.F.C = r.pointee&0x80 != 0
    r.pointee = (r.pointee << 1)
    if c {
        r.pointee |= 0x1
    }
    cpu.regs.F.S = r.pointee&0x80 != 0
    cpu.regs.F.Z = r.pointee == 0
    cpu.regs.F.P = cpu.parityTable[Int(r.pointee)]
    cpu.regs.F.H = false
    cpu.regs.F.N = false
}
