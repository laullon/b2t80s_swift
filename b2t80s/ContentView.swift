//
//  ContentView.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    var machine: zx48k
    
    @AppStorage("volumen") private var volumen: Double = 0
    @AppStorage("showDebuger") private var showDebuger = false
    
    @State private var inDisplay: Bool = false
    @State private var showOverlay: Bool = false
    @State private var showOverlayStarted = Date.now;
    @State private var tapName = "pp";
    
    var body: some View {
        HStack {
            Display(monitor: machine.monitor)
                .overlay(ControlsOverlay(volumen: $volumen,
                                         showDebuger: $showDebuger,
                                         reset: machine.reset,
                                         openFile: machine.openFile)
                    .opacity(showOverlay ? 1 : 0), alignment: .bottomLeading)
                .onContinuousHover { phase in
                    switch phase {
                    case .active:
                        inDisplay = true
                        showOverlay = true
                        showOverlayStarted = Date.now
                    case .ended:
                        inDisplay = false
                        showOverlay = false
                    }
                }
            if showDebuger {
                Spacer()
                Debugger(machine: machine)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .onAppear() {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown,.keyUp,]) { (e) -> NSEvent? in
                if !inDisplay || e.modifierFlags.contains(.command) {
                    return e;
                }
                if !e.isARepeat{
                    machine.ula.OnKey(e)
                }
                return nil
            }
            machine.volumen = volumen
        }
        .onChange(of: volumen) {
            machine.volumen = volumen
        }
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
                if showOverlayStarted.timeIntervalSinceNow < -5 {
                    withAnimation {
                        showOverlay = false
                        if inDisplay{
                            NSCursor.setHiddenUntilMouseMoves(true)
                        }
                    }
                }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(machine: zx48k())
//    }
//}

struct DebuggerDisassembler : View {
    @ObservedObject var debugData: DebugData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Debuger")
                .padding(.bottom, 5)
            
            Text(debugData.prev)
                .lineLimit(10)
            
            Text(debugData.next)
                .padding(.top, 3)
                .padding(.bottom, 3)
                .foregroundColor(.blue)
            
            Text(debugData.diss)
                .lineLimit(10)
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment:.leading)
    }
}

struct Debugger : View {
    var machine: zx48k
    
    @StateObject var debugData:DebugData = DebugData()
    @State private var menStart = UInt16(0x4000)
    @AppStorage("BreakPoints") private var bp: [BreakPoint] = []
    
    let wait: Binding<Bool>
    let waitOnNext: Binding<Bool>
    let waitOnNextInterruption: Binding<Bool>
    
    init(machine: zx48k){
        self.machine = machine
        wait = Binding<Bool>(
            get: {
                return machine.cpu.wait
            }, set: { val in
                machine.cpu.wait = val
            }
        )
        
        waitOnNext = Binding<Bool>(
            get: {
                return machine.cpu.waitOnNext
            }, set: { val in
                machine.cpu.waitOnNext = val
            }
        )
        
        waitOnNextInterruption = Binding<Bool>(
            get: {
                return machine.cpu.waitOnNextInterruption
            }, set: { val in
                machine.cpu.waitOnNextInterruption = val
            }
        )
    }
    
    var body: some View {
        VStack{
            DebuggerControls(waitOnNext: waitOnNext, waitOnNextInterruption: waitOnNextInterruption, wait: wait)
                .padding()
            Divider()
//            DebuggerRegisters(debugData: debugData)
//                .padding()
            Divider()
            ScrollView {
                DebuggerDisassembler(debugData: debugData)
                    .padding()
                Divider()
                TabView {
                    BreakPointsView(breakPoints: $bp,symbols: $debugData.symbols)
                        .frame(height:200)
                        .tabItem {
                            Text("BreakPoints")
                        }
                    DebuggerMemory(symbols: debugData.symbols) { start, bytes in
                        return machine.cpu.bus.getBlock(addr: start, length: bytes)
                    }.tabItem {
                        Text("Memory")
                    }
                    ULAView(bitmap: machine.ula.bitmap)
                        .tabItem {
                            Text("ULA")
                        }
                    SpritesView(symbols: $debugData.symbols, getData: { bytes in
                        return machine.cpu.bus.getBlock(addr: 0x08601, length: uint16(bytes))
                    })
                    .frame(height:200)
                    .tabItem {
                        Text("Sprites")
                    }
                }
            }
            Divider()
            Text("FPS: \(debugData.fps)")
        }
        .font(Font.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [self] timer in
                var ops = machine.cpu.disassembler(11, from: machine.cpu.regs.PC)
                debugData.next = [ops.removeFirst()].dump()
                debugData.diss = ops.dump()
                debugData.fps = "\(machine.lastFrameTime)"
                debugData.prev = machine.cpu.log.dump()
                debugData.f = machine.cpu.regs.F
                debugData.reg8 = [
                    machine.cpu.regs.A.toHex(),
                    machine.cpu.regs.F.GetByte().toHex(),
                    machine.cpu.regs.B.toHex(),
                    machine.cpu.regs.C.toHex(),
                    machine.cpu.regs.D.toHex(),
                    machine.cpu.regs.E.toHex(),
                    machine.cpu.regs.H.toHex(),
                    machine.cpu.regs.L.toHex(),
                ]
                debugData.reg16 = [
                    machine.cpu.regs.SP.toHex(),
                    machine.cpu.regs.BC.toHex(),
                    machine.cpu.regs.DE.toHex(),
                    machine.cpu.regs.HL.toHex(),
                    machine.cpu.regs.IX.toHex(),
                    machine.cpu.regs.IY.toHex(),
                ]
                
                debugData.spStack = [
                    ((UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP))<<8)    | UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+1))).toHex(),
                    ((UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+2))<<8) | UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+3))).toHex(),
                    ((UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+4))<<8) | UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+5))).toHex(),
                    ((UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+6))<<8) | UInt16(machine.cpu.bus.readVideoMemory(machine.cpu.regs.SP&+7))).toHex(),
                ]
                
                var str = ""
                var addr = menStart
                for _ in 0..<16 {
                    str = "\(str)\(addr.toHex())"
                    for _ in 0..<16 {
                        str = "\(str) \(machine.cpu.bus.readVideoMemory(addr).toHexShort())"
                        addr &+= 1
                    }
                    str = "\(str)\n"
                }
                debugData.memory = str
                debugData.symbols = machine.symbols
            }
        }.onChange(of: bp) {
            machine.breakPoints = bp.map({ bp in
                bp.addr
            })
        }
    }
}

struct Display : View {
    @StateObject var monitor: Monitor
    
    var placeholder: Image = Image(systemName: "globe")
    var body: some View {
        ( monitor.image == nil ? placeholder : monitor.image!)
            .interpolation(.none)
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

class DebugData: ObservableObject {
    @Published var prev = ""
    @Published var next = ""
    @Published var diss = ""
    @Published var fps = ""
    @Published var f = flags()
    @Published var reg8: [String] = Array(repeating: "", count: 8)
    @Published var reg16: [String] = Array(repeating: "", count: 6)
    @Published var spStack: [String] = Array(repeating: "", count: 4)
    
    @Published var memory: String = ""
    @Published var symbols: [Symbol] = []
}
