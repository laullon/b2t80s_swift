//
//  48.swift
//  b2t80s
//
//  Created by German Laullon on 29/8/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static let tap = UTType(importedAs: "com.laullon.b2t80s.tap")
}

class zx48k {
    let cpu = z80(ZXBus())
    let ula: ULA
    var cassete: Cassete?
    
    var monitor: Monitor { get {return ula.monitor} set {ula.monitor = newValue} }
    
    init() {
        ula = ULA(cpu: cpu)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FE), manager: ula)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FF), manager: ula)
        
        cpu.RegisterTrap(pc: 0x056B, trap: { [self]z80 in
            if cassete == nil {
                DispatchQueue.main.asyncAndWait(execute: DispatchWorkItem(block: { openFile() }))
            }
            cassete!.loadDataBlock()
        })
        
        //        cpu.RegisterTrap(0x12A9, ula.loadCommand)
        
        //        cpu.RegisterTrap(pc: 0x12A0, trap: {cpu in
        //            cpu.regs.PC = 0x056b
        //        })
        //
        //        cpu.RegisterTrap(pc: 0x056b, trap: {cpu in
        //            cpu.regs.PC = 0x056b
        //        })
    }
    
    private func openFile() {
        let op = NSOpenPanel()
        op.allowedContentTypes = [.tap]
        op.canCreateDirectories = true
        op.isExtensionHidden = false
        op.title = "Save your image"
        op.message = "Choose a folder and a name to store the image."
        op.nameFieldLabel = "Image file name:"
        
        let response = op.runModal()
        if (response == .OK) {
            let url = op.url!
            cassete = Cassete(tap: try! Tap(url),cpu: self.cpu)
        }
        
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
    
    func writeToMemory(_ addr: UInt16, _ data: UInt8) {
        let page = addr >> 14
        let pos = addr & 0x3fff
        men[page,pos] = data
    }
    
    func registerPort(mask: PortMask, manager: PortManager) {
        portsManager[mask] = manager
    }
    
    func readPort() {
        var skip = false
        for (portMask, portManager) in portsManager {
            if (addr & portMask.mask) == portMask.value {
                (data, skip) = portManager.readPort(addr)
            }
        }
        if !skip {
            return
        }
        print("[readPort]-(no PM)-> port:\(addr.toHex())")
        data = 0xff
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
            fatalError("[writePort]-(no PM)-> port:\(addr.toHex()) data:\(data.toHex())")
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
