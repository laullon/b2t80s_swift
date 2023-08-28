//
//  registers.swift
//  b2t80s
//
//  Created by German Laullon on 27/8/23.
//

import Foundation

private enum regs8idx {
    static let a = 1
    static let f = 0
    static let b = 3
    static let c = 2
    static let d = 5
    static let e = 4
    static let h = 7
    static let l = 6
    static let ixh = 9
    static let ixl = 8
    static let iyh = 11
    static let iyl = 10
    static let s = 13
    static let p = 12
}

private enum regs16idx {
    static let af = 0
    static let bc = 1
    static let de = 2
    static let hl = 3
    static let ix = 4
    static let iy = 5
    static let sp = 6
}


class Registers {
    let rawPointers: UnsafeMutableRawPointer
    let rawPointers8: UnsafeMutablePointer<UInt8>
    let rawPointers16: UnsafeMutablePointer<UInt16>
    
    let aPtr, bPtr, cPtr, dPtr, ePtr, hPtr, lPtr, sPtr, pPtr, ixhPtr, ixlPtr, iyhPtr, iylPtr: UnsafeMutablePointer<UInt8>
    let bcPtr, dePtr, hlPtr, spPtr, ixPtr, iyPtr: UnsafeMutablePointer<UInt16>
    
    var A: UInt8 { get { return aPtr.pointee } set { aPtr.pointee = newValue } }
    
    var F: flags = flags()
    
    var B: UInt8 { get { return bPtr.pointee } set { bPtr.pointee = newValue } }
    var C: UInt8 { get { return cPtr.pointee } set { cPtr.pointee = newValue } }
    var BC: UInt16 { get { return bcPtr.pointee } set { bcPtr.pointee = newValue } }
    
    var D: UInt8 { get { return dPtr.pointee } set { dPtr.pointee = newValue } }
    var E: UInt8 { get { return ePtr.pointee } set { ePtr.pointee = newValue } }
    var DE: uint16 { get { return dePtr.pointee } set { dePtr.pointee = newValue } }
    
    var H: UInt8 { get { return hPtr.pointee } set { hPtr.pointee = newValue } }
    var L: UInt8 { get { return lPtr.pointee } set { lPtr.pointee = newValue } }
    var HL: uint16 { get { return hlPtr.pointee } set { hlPtr.pointee = newValue } }
    
    var IXH: UInt8 { get { return ixhPtr.pointee } set { ixhPtr.pointee = newValue } }
    var IXL: UInt8 { get { return ixlPtr.pointee } set { ixlPtr.pointee = newValue } }
    var IX: uint16 { get { return ixPtr.pointee } set { ixPtr.pointee = newValue } }
    
    var IYH: UInt8 { get { return iyhPtr.pointee } set { iyhPtr.pointee = newValue } }
    var IYL: UInt8 { get { return iylPtr.pointee } set { iylPtr.pointee = newValue } }
    var IY: uint16 { get { return iyPtr.pointee } set { iyPtr.pointee = newValue } }
    
    var S: UInt8 { get { return sPtr.pointee } set { sPtr.pointee = newValue } }
    var P: UInt8 { get { return pPtr.pointee } set { pPtr.pointee = newValue } }
    var SP: uint16 { get { return spPtr.pointee } set { spPtr.pointee = newValue } }
    
    var PC: uint16 = 0
    
    var I: UInt8 = 0
    var R: UInt8 = 0x01
    var R7: UInt8 = 0
    
    var IFF1: Bool = false
    var IFF2: Bool = false
    var M1: Bool = false
    
    
    var Aalt: UInt8 = 0
    var Falt:flags = flags()
    var Balt: UInt8 = 0
    var Calt: UInt8 = 0
    var Dalt: UInt8 = 0
    var Ealt: UInt8 = 0
    var Halt: UInt8 = 0
    var Lalt: UInt8 = 0
    
    var InterruptsMode: UInt8 = 0
    
    var rRegsPtrs :[UnsafeMutablePointer<UInt16>] = []
    var indexRegsPtrs :[UnsafeMutablePointer<UInt16>] = []
    var indexRegsHPtrs :[UnsafeMutablePointer<UInt8>] = []
    var indexRegsLPtrs :[UnsafeMutablePointer<UInt8>] = []
    var regsPtrs :[UnsafeMutablePointer<UInt8>?] = []
    
    
    init() {
        self.rawPointers = UnsafeMutableRawPointer.allocate(byteCount: 32, alignment: MemoryLayout<UInt8>.alignment)
        self.rawPointers8 = self.rawPointers.bindMemory(to: UInt8.self, capacity: 32)
        self.rawPointers16 = self.rawPointers.bindMemory(to: UInt16.self, capacity: 16)
        
        self.aPtr = self.rawPointers8.advanced(by: regs8idx.a)
        self.bPtr = self.rawPointers8.advanced(by: regs8idx.b)
        self.cPtr = self.rawPointers8.advanced(by: regs8idx.c)
        self.dPtr = self.rawPointers8.advanced(by: regs8idx.d)
        self.ePtr = self.rawPointers8.advanced(by: regs8idx.e)
        self.hPtr = self.rawPointers8.advanced(by: regs8idx.h)
        self.lPtr = self.rawPointers8.advanced(by: regs8idx.l)
        self.sPtr = self.rawPointers8.advanced(by: regs8idx.s)
        self.pPtr = self.rawPointers8.advanced(by: regs8idx.p)
        self.ixhPtr = self.rawPointers8.advanced(by: regs8idx.ixh)
        self.ixlPtr = self.rawPointers8.advanced(by: regs8idx.ixl)
        self.iyhPtr = self.rawPointers8.advanced(by: regs8idx.iyh)
        self.iylPtr = self.rawPointers8.advanced(by: regs8idx.iyl)
        
        self.bcPtr = self.rawPointers16.advanced(by: regs16idx.bc)
        self.dePtr = self.rawPointers16.advanced(by: regs16idx.de)
        self.hlPtr = self.rawPointers16.advanced(by: regs16idx.hl)
        self.spPtr = self.rawPointers16.advanced(by: regs16idx.sp)
        self.ixPtr = self.rawPointers16.advanced(by: regs16idx.ix)
        self.iyPtr = self.rawPointers16.advanced(by: regs16idx.iy)
        
        regsPtrs.append(bPtr)
        regsPtrs.append(cPtr)
        regsPtrs.append(dPtr)
        regsPtrs.append(ePtr)
        regsPtrs.append(hPtr)
        regsPtrs.append(lPtr)
        regsPtrs.append(nil)
        regsPtrs.append(aPtr)
        
        rRegsPtrs.append(bcPtr)
        rRegsPtrs.append(dePtr)
        rRegsPtrs.append(hlPtr)
        rRegsPtrs.append(spPtr)
        
        indexRegsPtrs.append(hlPtr)
        indexRegsPtrs.append(ixPtr)
        indexRegsPtrs.append(iyPtr)
        
        indexRegsHPtrs.append(hPtr)
        indexRegsHPtrs.append(ixhPtr)
        indexRegsHPtrs.append(iyhPtr)

        indexRegsLPtrs.append(lPtr)
        indexRegsLPtrs.append(ixlPtr)
        indexRegsLPtrs.append(iylPtr)

    }
}

extension Registers: CustomStringConvertible {
    var description: String {
        return "A:\(A.toHex()) F:\(F.GetByte().toHex()) BC:\(BC.toHex()) DE:\(DE.toHex()) HL:\(HL.toHex()) SP:\(SP.toHex())"
    }
}

class flags {
    var C  :Bool = true
    var N  :Bool = true
    var P  :Bool = true
    var F3 :Bool = true
    var H  :Bool = true
    var F5 :Bool = true
    var Z  :Bool = true
    var S  :Bool = true
    
    func GetByte() -> UInt8 {
        var res = UInt8(0)
        if C {
            res |= 0b00000001
        }
        if N {
            res |= 0b00000010
        }
        if P {
            res |= 0b00000100
        }
        if F3 {
            res |= 0b00001000
        }
        if H {
            res |= 0b00010000
        }
        if F5 {
            res |= 0b00100000
        }
        if Z {
            res |= 0b01000000
        }
        if S {
            res |= 0b10000000
        }
        return res
    }
    
    func SetByte(_ b :UInt8) {
        C = b&0b00000001 != 0
        N = b&0b00000010 != 0
        P = b&0b00000100 != 0
        F3 = b&0b00001000 != 0
        H = b&0b00010000 != 0
        F5 = b&0b00100000 != 0
        Z = b&0b01000000 != 0
        S = b&0b10000000 != 0
    }
}
