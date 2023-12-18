//
//  Machine.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    var pc: String
    var inst: String = ""
    var ops: [String] = []
}

struct WatchEntry: Identifiable {
    let id = UUID()
    var pc: String
    var label: String
    var data: String
}

@MainActor
class MachinePlay: Machine {
    @Published var status = Status.ready
    @Published var registersData = RegistersData()
    @Published var nextPc = UInt16(0)
    @Published var symbols : [Symbol] = []
    @Published var ops: [Op] = []
    @Published var log: [LogEntry] = []
    @Published var bitmap: Bitmap?
    @Published var watchedMemory: [WatchEntry] = []
    
    private var engine = MachineEngine()
    private var done = false
    
    var memDebugger = DebuggerMemoryModel()
    var spriteDebugger = DebuggerMemoryModel()
    
    init() {
        memDebugger.updater = dumpMemory
        spriteDebugger.updater = dumpMemory
    }
    
    func dumpMemory(_ start: UInt16, _ count:UInt16) -> [UInt8] {
        engine.cpu.bus.getBlock(addr: start, length: count)
    }
    
    func stop() {
        done = true
    }
    
    func reset() async {
        engine.cpu.regs.PC = 0
        engine.resetMemory()
        resetLog()
        await updateUI()
    }

    func start(fast: Bool) async {
        status = .runing
        done = false
        repeat {
            let nextPc = await doStep()
            if let nextop = ops.first(where: { op in op.pc == nextPc }) {
                if ((nextop.inst as? Inst)?.breakPoint ?? false) {
                    done = true
                } else {
                    if !fast {
                        do { try await Task.sleep(for: .seconds(1)) } catch { }
                    }
                }
            } else {
                done = true
            }
        } while !done
        done = false
        status = .ready
    }
    
    func step() async {
        status = .runing
        _ = await doStep()
        status = .ready
    }

    private func doStep() async -> UInt16 {
        let (pc, le) = await self.engine.doStep()
        appendLog(le)
        await updateUI()
        return pc
    }
    
    func complie(code: String) async {
        status = .bussy
        
        stop()
        await reset()
        
        let (ops,symbols) = engine.compile(code: code)
                
        status = .ready
        updateCode(ops, symbols: symbols)
        await updateUI()
    }
    
    private func updateUI() async {
        let stack = dumpMemory(engine.cpu.regs.SP, 8*2)
        setNextPc(engine.cpu.regs.PC)
        updateRegs(engine.cpu.regs,stack: stack)
        bitmap = await engine.getScreen()
        updateWatchedMemory()
    }

    func updateWatchedMemory() {
        var watched = [WatchEntry]()
        ops.filter { $0.inst is DB }.forEach { op in
            if let db = op.inst as? DB {
                if db.watch {
                    watched.append(WatchEntry(pc: op.pc.toHex(),
                                              label: symbols.first(where: {$0.addr==op.pc})!.name,
                                              data: memDebugger.updater!(op.pc, op.length).dump()))
                }
            }
        }
        watchedMemory = watched
    }
    
    func updateCode(_ ops:[Op], symbols : [Symbol]) {
        self.ops = ops
        self.symbols = symbols
        memDebugger.update()
        spriteDebugger.update()
    }
    
    func setNextPc(_ nextPc: UInt16){
        self.nextPc = nextPc
        memDebugger.update()
        spriteDebugger.update()
    }
    
    func updateRegs(_ regs: Registers, stack: [UInt8]) {
        registersData.update(regs: regs, stack: stack)
    }
    
    func appendLog(_ le: LogEntry) {
        log.append(le)
    }
    
    func resetLog() {
        log.removeAll()
    }
}

class MachineEngine {
    
    private var frame = UInt8(0)
    
    var cpu: z80
    private var bus = SimpleBus()
    
    private var compiler = Z80Compiler()
    
    private var done = false
    let compilerQueue = DispatchQueue(label: "compilerQueue")

    init() {
        self.cpu = z80(bus)
    }
    

    private func dumpMemory(_ start: UInt16, count: UInt16) -> [UInt8] {
        return Array(bus.men[(Int(start))..<(Int(start+count))])
    }
    
    func compile(code: String) -> ([Op], [Symbol]) {
        let (ops,symbols) = compiler.compile(code)
        ops.forEach { op in
            if op.valid {
                op.bytes.enumerated().forEach { byte in
                    bus.men[Int(op.pc)+byte.offset] = byte.element
                }
            }
        }
        return (ops,symbols)
    }

    func doStep() async -> (UInt16, LogEntry) {
        var le = LogEntry(pc: cpu.regs.PC.toHex())
        
        cpu.wait = false
        cpu.waitOnNext = true
        repeat {
            cpu.tick()
        } while !cpu.wait
        
        if let l = cpu.log.last {
            le.inst = l.op.disassemble(l)
        }
        
        return (cpu.regs.PC, le)
    }
    
    func resetMemory() {
        for i in 0...0xffff {
            bus.men[i] = 0
        }
    }
    
    func getScreen() async -> Bitmap {
        let display = bus.getBlock(addr: 0x4000, length: 0x4000)
        var bm = Bitmap(width: 256, height: 192, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
        for row in 0..<192 {
            for col in stride(from: 0, to: 256, by: 8) {
                var addr = 0
                addr |= (row&0b11000000)<<5
                addr |= (row&0b00000111)<<8
                addr |= (row&0b00111000)<<2
                addr |= (col&0b11111000)>>3
                
                let pixles = display[addr]
                
                var attrAddr = 0x1800
                attrAddr |= (row&0b11111000)<<2
                attrAddr |= (col&0b11111000)>>3
                let attr = display[attrAddr]
                
                for (i, c) in getPixelsColors(attr: attr, pixles: pixles).enumerated() {
                    bm[col+i, row] = c
                }
            }
        }
        return bm
    }
    
    private func getPixelsColors(attr :UInt8, pixles: UInt8) -> [BitmapColor] {
        let flash = (attr & 0x80) == 0x80
        let brg = (attr & 0x40) >> 6
        let paper = palette[Int(((attr&0x38)>>3)+(brg*8))]
        let ink = palette[Int((attr&0x07)+(brg*8))]
        
        var colors = Array(repeating: palette[0], count: 8)
        for b in 0..<8 {
            var data = pixles
            data = data << b
            data &= 0b10000000
            if flash && (frame&0x10 != 0) {
                if data != 0 {
                    colors[b] = paper
                } else {
                    colors[b] = ink
                }
            } else if data != 0 {
                colors[b] = ink
            } else {
                colors[b] = paper
            }
        }
        return colors
    }
}

class SimpleBus: Bus {
    var men = Men()
    var addr :UInt16 = 0
    var data :UInt8 = 0
    
    func readMemory() {
        data = men[Int(addr)]
        //        print("MR",addr.toHex(),data.toHex())
    }
    
    func writeMemory() {
        men[Int(addr)] = data
        //        print("MW",addr.toHex(),data.toHex())
    }
    
    func writeToMemory(_ addr: UInt16, _ data: UInt8) { fatalError() }
    func readVideoMemory(_ addr: UInt16) -> UInt8 { fatalError() }
    func release() {}
    func registerPort(mask: PortMask, manager: PortManager) {}
    func readPort() {}
    func writePort() {}
    func getBlock(addr: UInt16, length: UInt16) -> [UInt8] {
        var res = Array(repeating: UInt8(0), count: Int(length))
        for idx in 0..<length {
            res[Int(idx)] = men[Int(addr&+idx)]
        }
        return res
    }
}

struct Men {
    var lock = NSLock()
    var men = Array(repeating: UInt8(0), count: Int(0x10000))
    
    subscript(index: Int) -> UInt8 {
        get {
            lock.lock()
            defer { lock.unlock() }
            return men[index]
        }
        set(newValue) {
            lock.lock()
            defer { lock.unlock() }
            men[index] = newValue
        }
    }

    subscript(range: Range<Int>) -> [UInt8] {
        lock.lock()
        defer { lock.unlock() }
        return Array(men[range])
    }
}
