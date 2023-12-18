//
//  48.swift
//  b2t80s
//
//  Created by German Laullon on 29/8/23.
//

import Foundation
import SwiftUI

class DissamblerInfo {
    var prev = ""
    var next = ""
    var diss = ""
}

class MachineZX48K: Machine, ULAListener {
    @AppStorage("showDebuger") var showDebuger = false
    
    @Published var status = Status.paused
    @Published var display = Bitmap(width: 352, height: 296, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
    @Published var registersData = RegistersData()
    @Published var history = DissamblerInfo()
    @Published var tapName = ""

    var memDebugger = DebuggerMemoryModel()
    var spriteDebugger = DebuggerMemoryModel()
    
    init() {
        memDebugger.updater = dumpMemory
        spriteDebugger.updater = dumpMemory
    }
    
    func dumpMemory(_ start: UInt16, _ count:UInt16) -> [UInt8] {
        engine.cpu.bus.getBlock(addr: start, length: count)
    }
    
    private var engine = zx48k()
    
    func start(fast: Bool) async {
        status = .runing
        engine.ula.listener = self
        engine.start()
    }
    
    func step() async {
        status = .runing
        engine.step()
        status = .paused
        updateDebbuger()
    }
    
    func stop() {
        engine.stop()
        status = .paused
        updateDebbuger()
    }
    
    func reset() async {
    }
        
    var frame = 0
    func frameDone(bitmap: Bitmap) {
        Task{
            await MainActor.run {
                self.display = bitmap
            }
        }
        if showDebuger && ((frame%3) == 0){
            updateDebbuger()
        }
        frame &+= 1
    }
    
    func updateDebbuger() {
        Task{
            var ops = engine.cpu.disassembler(11, from: engine.cpu.regs.PC)
            let h = DissamblerInfo()
            h.prev = engine.cpu.log.dump()
            h.next = [ops.removeFirst()].dump()
            h.diss = ops.dump()

            let r = RegistersData(regs: engine.cpu.regs, stack: getStack(),prev: self.registersData)
            await MainActor.run {
                self.registersData = r
                self.history = h
            }
        }
        Task{
            let data = engine.cpu.bus.getBlock(addr: self.memDebugger.start.addr, length: 0x100)
            await MainActor.run {
                self.memDebugger.data = data
            }
        }
    }
    
    func OnKey(_ e: NSEvent) {
        engine.ula.OnKey(e)
    }
    
    func getStack() -> [UInt8] {
        return engine.cpu.bus.getBlock(addr: self.engine.cpu.regs.SP, length: 8*2)
    }
    
    func setTap(tap: String) {
        self.tapName = engine.setTap(tap: tap)
        self.memDebugger.symbols = engine.symbols
    }
}

class zx48k {
    let cpu = z80(ZXBus())
    let ula: ULA
    var cassete: Cassete
    var t: DispatchSourceTimer
    var lastFrameTime: Double = 0
    let ticks = 3_500_000 / 1000
    
    var symbols: [Symbol] = []
    
    let loadKeys: [(UInt16,UInt8)] = [(0xFFFF,0x78),(0xFFFF,0x78),(0xFFFF,0x78),(0xFFFF,0x78),(0xFF09,0x78),
                                      (0xFFFF,0x78),(0x1822,0x6A),(0xFFFF,0x78),(0xFFFF,0x78),(0xFFFF,0x78),
                                      (0xFFFF,0x78),(0x1822,0x6A),(0xFFFF,0x78),(0xFF21,0x50)]
    
    var keysToPress: [(UInt16,UInt8)]?
    
    var volumen: Double {
        get {
            return ula.sound.volumen
        }
        set {
            ula.sound.volumen = newValue
        }
    }
    
    var breakPoints: [UInt16] {
        get {
            return cpu.breakPoints
        }
        set {
            cpu.breakPoints = newValue
        }
    }
    
    //    var monitor: Monitor { get {return ula.monitor} set {ula.monitor = newValue} }
    
    init(tap: String? = nil) {
        ula = ULA(cpu: cpu)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FE), manager: ula)
        cpu.bus.registerPort(mask: PortMask(mask: 0x00FF, value: 0x00FF), manager: ula)
        cassete = Cassete(cpu: self.cpu)
        
        t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now(),repeating: .milliseconds(1),leeway: .never)
        t.setEventHandler(handler: { [self] in
            let clock = ContinuousClock()
            let result = clock.measure {
                for _ in 0..<ticks{
                    self.ula.tick()
                }
            }
            lastFrameTime = (Double(result.components.attoseconds)/(1000000000000000))
        })
        cpu.wait = true

        cpu.RegisterTrap(pc: 0x056B, trap: { [self]z80 in
            if cassete.tap == nil {
                DispatchQueue.main.asyncAndWait(execute: DispatchWorkItem(block: { self.openFile() }))
            }
            cassete.loadDataBlock()
        })
        
        cpu.RegisterTrap(pc: 0x028E) { cpu in
            if self.keysToPress != nil {
                if self.keysToPress!.count != 0{
                    let v = self.keysToPress!.removeFirst()
                    cpu.regs.DE = v.0
                    cpu.regs.F.SetByte(v.1)
                    cpu.regs.PC = 0x02BE
                }
            }
        }

        t.activate()
    }
    
    func reset() {
        cpu.doReset = true
        cassete.rewind()
        keysToPress = loadKeys
    }
    
    func openFile() {
        let op = NSOpenPanel()
        op.allowedContentTypes = [.tapType]
        op.canCreateDirectories = true
        op.isExtensionHidden = false
        op.title = "Save your image"
        op.message = "Choose a folder and a name to store the image."
        op.nameFieldLabel = "Image file name:"
        
        let response = op.runModal()
        if (response == .OK) {
            let url = op.url!
            cassete.tap = try! Tap(url,symbols: &symbols)
        }
    }
    
    func setTap(tap: String) -> String {
        let url = URL(filePath: tap)
        do {
            cassete.tap = try Tap(url, symbols: &symbols)
            keysToPress = loadKeys
        } catch {
            print("Unexpected error: \(error).")
            return "error"
        }
        return url.lastPathComponent
    }
        
    func step() {
        cpu.waitOnNext = true
        cpu.wait = false
    }
        
    func start() {
        cpu.waitOnNext = false
        cpu.wait = false
    }
    
    func stop() {
        cpu.waitOnNext = true
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
            print("[writePort]-(no PM)-> port:\(addr.toHex()) data:\(data.toHex())")
        }
    }
    
    func getBlock(addr: uint16, length: uint16) -> [UInt8] {
        var res:[UInt8] = []
        var a = addr
        while a != (addr&+length) {
            res.append(readVideoMemory(a))
            a &+= 1
        }
        return res
    }
}

private class Memory {
    private var mem = Array(repeating: Array(repeating: UInt8(0), count: 0x4000), count: 4)
    var lock = NSLock()
    
    init() {
        do {
            let filePath = Bundle.main.url(forResource: "48k", withExtension: "rom")!
            let data = try Data(contentsOf: filePath)
            for (i,d) in data.enumerated() {
                lock.lock()
                defer { lock.unlock() }
                mem[0][i] = d
            }
        } catch {
            fatalError("Unexpected error: \(error).")
        }
    }
    
    subscript(page: UInt16, addr: UInt16) -> UInt8 {
        get {
            lock.lock()
            defer { lock.unlock() }
            return mem[Int(page)][Int(addr)]
        }
        set(newValue) {
            if page>0 {
                lock.lock()
                defer { lock.unlock() }
                mem[Int(page)][Int(addr)] = newValue
            }
        }
    }
}
