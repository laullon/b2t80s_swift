//
//  48.swift
//  b2t80s
//
//  Created by German Laullon on 29/8/23.
//

import Foundation

class zx48k {
    let cpu = z80(ZXBus())
    let ula: ULA
    
    var monitor: Monitor { get {return ula.monitor} set {ula.monitor = newValue} }
    
    init() {
        ula = ULA(cpu: cpu)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FE), manager: ula)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FF), manager: ula)
    }
    
    func run() {
        while true {
            ula.tick()
        }
    }
}

private class ZXBus: Bus {
    var addr: UInt16 = 0
    var data: UInt8 = 0
    var portsManager: [PortMask:PortManager] = [:]
    
    private var men = Memory()
    
    func release() {
        addr = 0xffff;
        data = 0xff
    }
    
    func readMemory() {
        let page = addr >> 14
        let pos = addr & 0x3fff
        data = men[page,pos]
    }
    
    func writeMemory() {
        let page = addr >> 14
        let pos = addr & 0x3fff
        men[page,pos] = data
    }
    
    func readVideoMemory(_ addr: UInt16) -> UInt8 {
        let page = addr >> 14
        let pos = addr & 0x3fff
        return men[page,pos]
    }
    
    func registerPort(mask: PortMask, manager: PortManager) {
        portsManager[mask] = manager
    }
    
    func readPort() {
        var ok = false
        for (portMask, portManager) in portsManager {
            if (addr & portMask.mask) == portMask.value {
                (data, ok) = portManager.readPort(addr)
            }
        }
        if !ok {
            fatalError(String(format:"[ReadPort]-(no PM)-> port:0x%04X data:0x%04X\n", addr, data))
        }
    }
    
    func writePort() {
        var ok = false
        for (portMask, portManager) in portsManager {
            if (addr & portMask.mask) == portMask.value {
                portManager.writePort(addr, data)
                ok = true
            }
        }
        if !ok {
            fatalError(String(format:"[writePort]-(no PM)-> port:0x%04X data:0x%04X\n", addr, data))
        }
    }
    
    func getBlock(addr: uint16, length: uint16) -> [UInt8] {
        var res:[UInt8] = []
        for a in addr..<(addr+length) {
            res.append(readVideoMemory(a))
        }
        return res
    }
}

private class Memory {
    private var mem = Array(repeating: Array(repeating: UInt8(0), count: 0x4000), count: 4)
    
    init() {
        do {
            let filePath = Bundle.main.url(forResource: "48k", withExtension: "rom")!
            let data = try Data(contentsOf: filePath)
            for (i,d) in data.enumerated() {
                mem[0][i] = d
            }
        } catch {
            fatalError("Unexpected error: \(error).")
        }
    }
    
    subscript(page: UInt16, addr: UInt16) -> UInt8 {
        get {
            return mem[Int(page)][Int(addr)]
        }
        set(newValue) {
            if page>0 {
                mem[Int(page)][Int(addr)] = newValue
            }
        }
    }
}
