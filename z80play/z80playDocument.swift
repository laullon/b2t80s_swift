//
//  z80playDocument.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI
import UniformTypeIdentifiers

let asm = """
; coment
loop:
    ld hl, data
    ld a, (hl)
    inc a
    daa
    ld (hl), a
    jr loop
data:
    db 0,0,0,0
"""

extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.example.plain-text")
    }
}

struct z80playDocument: FileDocument {
    var text: String
    var ops: [Op] = []
    var machine = Machine()
        
    private var compiler = Z80Compiler()
    
    init(text: String = asm) {
        self.text = text
    }
    
    static var readableContentTypes: [UTType] { [.exampleText] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
    
    mutating func complie() {
        ops = compiler.compile(text)
        machine.resetMemory(code: ops)
        machine.stop()
        machine.reset()
    }
    
}

class Machine: ObservableObject {
    @Published var registersData = RegistersData()
    @Published var nextPc = UInt16(0)
    @Published var runing = false
    
    private var cpu: z80
    private var bus = SimpleBus(men: Array(repeating: UInt8(0), count: Int(0x10000)))
    private var timer :Timer?
    
    init() {
        cpu = z80(bus)
    }
    
    func dumpMemory(_ start: UInt16, count: UInt16) -> [UInt8] {
        return Array(bus.men[(Int(start))..<(Int(start+count))])
    }
    
    func start(fast: Bool) {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: fast ? 0.1 : 1, repeats: true) { _ in
                self.step()
            }
            runing = true
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        runing = false
    }
    
    func reset() {
        nextPc = 0
        cpu.doReset = true
        registersData.update(regs: cpu.regs)
    }
    
    func step() {
        cpu.wait = false
        cpu.waitOnNext = true
        repeat {
            cpu.tick()
        } while !cpu.wait
        nextPc = cpu.regs.PC
        registersData.update(regs: cpu.regs)
        print("nextPc:",nextPc)
    }
    
    func resetMemory(code: [Op]) {
        for i in 0...0xffff {
            bus.men[i] = 0
        }
        code.forEach { op in
            if op.valid {
                op.bytes.enumerated().forEach { byte in
                    bus.men[Int(op.pc)+byte.offset] = byte.element
                }
            }
        }
    }
    
}

class SimpleBus: Bus {
    var men :[UInt8]
    var addr :UInt16 = 0
    var data :UInt8 = 0
    
    init(men: [UInt8]) {
        self.men = men
    }
    
    func readMemory() {
        data = men[Int(addr)]
        print("MR",addr.toHex(),data.toHex())
    }
    
    func writeMemory() {
        men[Int(addr)] = data
        print("MW",addr.toHex(),data.toHex())
    }
    
    func writeToMemory(_ addr: UInt16, _ data: UInt8) { fatalError() }
    func readVideoMemory(_ addr: UInt16) -> UInt8 { fatalError() }
    func release() {}
    func registerPort(mask: PortMask, manager: PortManager) {}
    func readPort() {}
    func writePort() {}
    func getBlock(addr: UInt16, length: UInt16) -> [UInt8] { fatalError() }
}
