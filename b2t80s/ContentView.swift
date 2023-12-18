//
//  ContentView.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var machine = MachineZX48K()

    @AppStorage("volumen") private var volumen: Double = 0
    
    @State private var inDisplay: Bool = false
    
    private var tapName: String?

    init(tap: String?) {
        self.tapName = tap
    }

    var body: some View {
        HStack {
            Display(machine: machine)
                .onContinuousHover { phase in
                    switch phase {
                    case .active:
                        inDisplay = true
                    case .ended:
                        inDisplay = false
                    }
                }
                .inspector(isPresented: $machine.showDebuger) {
                    Debugger(machine: machine)
                        .inspectorColumnWidth(min: 455, ideal: 455, max: 455)
                }
        }
        .toolbar {
            ToolBar(machine: machine)
        }
        .onAppear() {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown,.keyUp,]) { (e) -> NSEvent? in
                if !inDisplay || e.modifierFlags.contains(.command) {
                    return e;
                }
                if !e.isARepeat{
                    machine.OnKey(e)
                }
                return nil
            }
//            machine.volumen = volumen
            Task {
                if (tapName != nil) {
                    machine.setTap(tap:tapName!)
                }
                await machine.start(fast: false)
            }
        }
        .onChange(of: volumen) {
//            machine.volumen = volumen
        }
        .onAppear() {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
                withAnimation {
                    if inDisplay{
                        NSCursor.setHiddenUntilMouseMoves(true)
                    }
                }
            }
        }
        .navigationTitle("ZX Spectrum 48k")
        .navigationSubtitle(machine.tapName)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(machine: zx48k())
//    }
//}

struct DebuggerDisassembler : View {
    @ObservedObject var debugData: MachineZX48K
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Debuger")
                .padding(.bottom, 5)
            
            Text(debugData.history.prev)
                .lineLimit(10)
            
            Text(debugData.history.next)
                .padding(.top, 3)
                .padding(.bottom, 3)
                .foregroundColor(.blue)
            
            Text(debugData.history.diss)
                .lineLimit(10)
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment:.leading)
    }
}

struct _Debugger : View {
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
//                DebuggerDisassembler(debugData: debugData)
//                    .padding()
                Divider()
                TabView {
                    BreakPointsView(breakPoints: $bp,symbols: $debugData.symbols)
                        .frame(height:200)
                        .tabItem {
                            Text("BreakPoints")
                        }
//                    DebuggerMemory(symbols: debugData.symbols) { start, bytes in
//                        return machine.cpu.bus.getBlock(addr: start, length: bytes)
//                    }.tabItem {
//                        Text("Memory")
//                    }
                    ULAView(bitmap: machine.ula.bitmap)
                        .tabItem {
                            Text("ULA")
                        }
//                    SpritesView(symbols: $debugData.symbols, getData: { bytes in
//                        return machine.cpu.bus.getBlock(addr: 0x08601, length: uint16(bytes))
//                    })
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
    @StateObject var machine: MachineZX48K
    
    var body: some View {
        Image(machine.display.cgImage(), scale:1, label: Text(verbatim: ""))
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
