//
//  ContentView.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    var monitor: Monitor
    var machine: zx48k
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Display(monitor: monitor)
                Divider()
                Debugger(cpu: machine.cpu)
            }
            Divider()
            Text("FPS").fixedSize()
        }.onAppear() {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown,.keyUp]) { (e) -> NSEvent? in
                if e.modifierFlags.contains(.command) {
                    return e;
                }
                if !e.isARepeat{
                    machine.ula.OnKey(e)
                }
                return nil
            }
        }
    }
}

struct Debugger : View {
    var cpu: z80
    @StateObject var debugerUpdater:DebugerUpdater
    
    init(cpu: z80){
        self.cpu = cpu
        _debugerUpdater = StateObject(wrappedValue: DebugerUpdater(cpu: cpu))
        
    }
    
    var body: some View {
        VStack{
            HStack{
                Button("Stop") {
                    cpu.waitOnNext = true
                }.disabled(cpu.wait || cpu.waitOnNext)
                Button("Step") {
                    cpu.wait = false
                    cpu.waitOnNext = true
                }.disabled(!cpu.wait)
                Button("continue") {
                    cpu.waitOnNext = false
                    cpu.wait = false
                }.disabled(!cpu.wait)
            }
            Grid(alignment: .leading) {
                GridRow {
                    Text("A:")
                    Text(cpu.regs.A.toHex())
                    Text("F:")
                    Text(cpu.regs.F.GetByte().toHex())
                    FDetail(f: cpu.regs.F).gridCellColumns(2)
                    Text("SP: \(cpu.regs.SP.toHex())")
                }
                GridRow {
                    Text("B:")
                    Text(cpu.regs.B.toHex())
                    Text("C:")
                    Text(cpu.regs.C.toHex())
                    Text("BC:")
                    Text(cpu.regs.BC.toHex())
                    Text("----------")
                }
                GridRow {
                    Text("D:")
                    Text(cpu.regs.D.toHex())
                    Text("E:")
                    Text(cpu.regs.E.toHex())
                    Text("DE:")
                    Text(cpu.regs.DE.toHex())
                    Text(((UInt16(cpu.bus.readVideoMemory(cpu.regs.SP))<<8) | UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+1))).toHex())
                }
                GridRow {
                    Text("H:")
                    Text(cpu.regs.H.toHex())
                    Text("L:")
                    Text(cpu.regs.L.toHex())
                    Text("HL:")
                    Text(cpu.regs.HL.toHex())
                    Text(((UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+2))<<8) | UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+3))).toHex())
                }
                GridRow {
                    Text("").gridCellColumns(4)
                    Text("IX:")
                    Text(cpu.regs.IX.toHex())
                    Text(((UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+4))<<8) | UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+5))).toHex())
                }
                GridRow {
                    Text("").gridCellColumns(4)
                    Text("IY:")
                    Text(cpu.regs.IY.toHex())
                    Text(((UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+6))<<8) | UInt16(cpu.bus.readVideoMemory(cpu.regs.SP&+7))).toHex())
                }
                GridRow {
                    Divider()
                        .gridCellColumns(7)
                        .gridCellUnsizedAxes(.horizontal)
                }
                GridRow {
                    VStack(alignment: .leading) {
                        Text(cpu.log.dump())
                            .lineLimit(10)
                        Text(debugerUpdater.next).padding(.top).padding(.bottom).foregroundColor(.blue)
                        Text(debugerUpdater.diss)
                            .lineLimit(10)
                        
                    }.gridCellColumns(7)
                        .fixedSize()
                }
            }
            .font(Font.system(size: 18).monospaced())
        }
        .fixedSize()
        .padding()
    }
}

struct FDetail : View {
    var f: flags
    var body: some View {
        Group{
            Text("S").foregroundColor(f.S ? Color.blue : Color.gray) +
            Text("Z").foregroundColor(f.Z ? Color.blue : Color.gray) +
            Text("5").foregroundColor(Color.gray) +
            Text("H").foregroundColor(f.H ? Color.blue : Color.gray) +
            Text("3").foregroundColor(Color.gray) +
            Text("P").foregroundColor(f.P ? Color.blue : Color.gray) +
            Text("N").foregroundColor(f.N ? Color.blue : Color.gray) +
            Text("C").foregroundColor(f.C ? Color.blue : Color.gray)
        }
    }
}

struct Display : View {
    @StateObject var monitor: Monitor
    var placeholder: Image = Image(systemName: "globe")
    var body: some View {
        ( monitor.image == nil ? placeholder : monitor.image!)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

class Monitor: ObservableObject {
    var image: Image? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}

class DebugerUpdater: ObservableObject {
    var cpu: z80
    var next = ""
    var diss = ""
    
    init(cpu: z80){
        self.cpu = cpu
        start()
    }
    
    func start() {
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [self] timer in
            var ops = cpu.disassembler(11, from: cpu.regs.PC)
            next = [ops.removeFirst()].dump()
            diss = ops.dump()
            objectWillChange.send()
        }
    }
}

private class FackeBus: Bus{
    func writeToMemory(_ addr: UInt16, _ data: UInt8) {
    }
    
    var addr: UInt16=0
    
    var data: UInt8=0
    
    func release() {
        
    }
    
    func readMemory() {
        
    }
    
    func writeMemory() {
        
    }
    
    func readVideoMemory(_ addr: UInt16) -> UInt8 {
        return 0
    }
    
    func registerPort(mask: PortMask, manager: PortManager) {
        
    }
    
    func readPort() {
        
    }
    
    func writePort() {
        
    }
    
    func getBlock(addr: uint16, length: uint16) -> [UInt8] {
        return []
    }
    
    
}
