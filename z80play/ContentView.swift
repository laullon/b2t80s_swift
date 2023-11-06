//
//  ContentView.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: z80playDocument
    @ObservedObject var machine: Machine
        
    var body: some View {
        VStack{
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    ForEach(document.ops) { op in
                        if op.valid {
                            if op.inst is Inst {
                                let dump = op.bytes.map({$0.toHexShort()}).joined(separator: " ")
                                let dis = z80InstructionSet.shared.disassembler(data: op.bytes)
                                Text("\(op.pc.toHex()) \(dump)")
                                    .help("\(dis)\n\(op.description)")
                                    .background((document.machine.nextPc == op.pc) ? .green : .clear)
                            } else if op.inst is DB {
                                let dump = op.bytes.map({$0.toHexShort()}).joined(separator: " ")
                                Text("\(op.pc.toHex()) \(dump)")
                                    .help(dump.subSequences(of:3*10).joined(separator: "\n"))
                            } else {
                                Text(" ")
                            }
                        } else {
                            Text("error")
                                .background(.red)
                                .help("\(op.description)")
                        }
                    }
                    .padding(.leading,5)
                    .frame(width: 170, alignment: .leading)
                    .lineLimit(1)
                }
                Divider()
                TextEditor(text: $document.text)
                    .lineSpacing(0)
            }
            Divider()
            HStack(alignment: .top) {
                DebuggerMemory(symbols: []) { start, bytes in
                    document.machine.dumpMemory(start, count: bytes)
                }
                Divider()
                DebuggerRegisters(debugData: document.machine.registersData)
                    .fixedSize()
            }
        }
        .toolbar {
            ToolBar(machine: document.machine)
        }
        
        .font(Font.system(size: 14,design: .monospaced))
        .onAppear() {
            document.complie()
        }
        .onChange(of: document.text, {
            document.complie()
        })
        .background(.white)
    }
}

#Preview {
    var doc = z80playDocument()
    return ContentView(document: .constant(doc), machine: doc.machine)
        .frame(height: 600)
}

struct ToolBar: View {
    @ObservedObject var machine: Machine
    
    var body: some View {
        Button() {
            machine.reset()
        } label: {
            Image(systemName: "backward.end.alt")
        }
        .help("Reset")
        .disabled(machine.runing)
        
        Button() {
            machine.start(fast: false)
        } label: {
            Image(systemName: "play")
        }
        .help("Run")
        .disabled(machine.runing)
        
        Button() {
            machine.start(fast: true)
        } label: {
            Image(systemName: "forward")
        }
        .help("Run")
        .disabled(machine.runing)

        Button() {
            machine.step()
        } label: {
            Image(systemName: "forward.frame")
        }
        .help("Step")
        .disabled(machine.runing)
        
        Button() {
            machine.stop()
        } label: {
            Image(systemName: "pause")
        }
        .help("Pause")
        .disabled(!machine.runing)
    }
}
