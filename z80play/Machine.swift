//
//  Machine.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import Foundation

enum Status {
    case ready, error, runing, bussy
}

struct LogEntry: Identifiable {
    let id = UUID()
    var pc: String
    var inst: String = ""
    var ops: [String] = []
}

@MainActor class BusDebugger: DebuggerMemoryModel {
    var bus: Bus
    
    init(bus: Bus) {
        self.bus = bus
        super.init()
    }
    
    override func update() {
        //        Task {
        //            data = bus.getBlock(addr: start.addr, length: count)
        //        }
    }
}

class MachineStatus: ObservableObject{
    @MainActor @Published var registersData = RegistersData()
    @MainActor @Published var nextPc = UInt16(0)
    @MainActor @Published var symbols : [Symbol] = []
    @MainActor @Published var ops: [Op] = []
    @MainActor @Published var log: [LogEntry] = []
    @MainActor @Published var status = Status.ready
    @MainActor @Published var bitmap: Bitmap?
    var memDebugger = DebuggerMemoryModel()
    var spriteDebugger = DebuggerMemoryModel()
    
    @MainActor func setStatus(_ status: Status) {
        self.status = status
    }
    
    @MainActor func setBitmap(_ bitmap: Bitmap) {
        self.bitmap = bitmap
    }
    
    @MainActor func updateCode(_ ops:[Op], symbols : [Symbol]) {
        self.ops = ops
        self.symbols = symbols
        memDebugger.update()
        spriteDebugger.update()
    }
    
    @MainActor func setNextPc(_ nextPc: UInt16){
        self.nextPc = nextPc
        memDebugger.update()
        spriteDebugger.update()
    }
    
    @MainActor func updateRegs(_ regs: Registers) {
        registersData.update(regs: regs)
    }
    
    @MainActor func appendLog(_ le: LogEntry) {
        log.append(le)
    }
    
    @MainActor func resetLog() {
        log.removeAll()
    }
}

class Machine {
    var status: MachineStatus
    
    private var frame = UInt8(0)
    
    private var cpu: z80
    private var bus = SimpleBus()
    
    private var compiler = Z80Compiler()
    
    private var done = false
    let compilerQueue = DispatchQueue(label: "compilerQueue")

    init() {
        self.cpu = z80(bus)
        
        self.status = MachineStatus()
        self.status.memDebugger.updater = dumpMemory(_:count:)
        self.status.spriteDebugger.updater = dumpMemory(_:count:)
    }
    

    private func dumpMemory(_ start: UInt16, count: UInt16) -> [UInt8] {
        return Array(bus.men[(Int(start))..<(Int(start+count))])
    }
    
    func complie(code: String) async  {
        await status.setStatus(.bussy)
        
        stop()
        await reset()
        resetMemory()
        
        let (ops,symbols) = compiler.compile(code)
        
        ops.forEach { op in
            if op.valid {
                if op.inst is Inst {
                    op.bytes.enumerated().forEach { byte in
                        bus.men[Int(op.pc)+byte.offset] = byte.element
                    }
                }
            }
        }
        
        await status.setStatus(.ready)
        await status.setBitmap(draw(display:bus.getBlock(addr: 0x4000, length: 0x4000)))
        await status.updateCode(ops, symbols: symbols)
    }
        
    func step() async {
        await status.setStatus(.runing)
        await doStep()
        await status.setStatus(.ready)
    }
    
    func start(fast: Bool) async {
        await status.setStatus(.runing)
        done = false
        repeat {
            await self.doStep()
            if !fast {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    
                }}
        } while !done
        done = false
        await status.setStatus(.ready)
    }
    
    func stop() {
        done = true
    }
    
    func reset() async {
        cpu.regs.PC = 0
        await status.setNextPc(0)
        await status.setNextPc(cpu.regs.PC)
        await status.resetLog()
    }
    
    private func doStep() async {
        var le = LogEntry(pc: cpu.regs.PC.toHex())
        
        cpu.wait = false
        cpu.waitOnNext = true
        repeat {
            cpu.tick()
        } while !cpu.wait
        
        if let l = cpu.log.last {
            le.inst = l.op.disassemble(l)
        }
        
        await status.setNextPc(cpu.regs.PC)
        await status.updateRegs(cpu.regs)
        await status.appendLog(le)
        await status.setBitmap(draw(display:bus.getBlock(addr: 0x4000, length: 0x4000)))
    }
    
    func resetMemory() {
        for i in 0...0xffff {
            bus.men[i] = 0
        }
    }
    
    func draw(display: [UInt8]) -> Bitmap {
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
    
    func getPixelsColors(attr :UInt8, pixles: UInt8) -> [BitmapColor] {
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
