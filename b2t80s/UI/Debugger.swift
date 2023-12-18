//
//  Debugger.swift
//  b2t80s
//
//  Created by German Laullon on 7/12/23.
//

import SwiftUI

struct Debugger : View {
    @ObservedObject var machine: MachineZX48K

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Collapsible {
                    Text("CPU State")
                } content: {
                    DebuggerRegisters(debugData: machine.registersData)
                }
                Collapsible {
                    Text("CPU State")
                } content: {
                    DebuggerDisassembler(debugData: machine)
                }
                Collapsible {
                    Text("Memory")
                } content: {
                    DebuggerMemory(model: machine.memDebugger)
                }
//                Collapsible {
//                    Text("Sprites")
//                } content: {
//                    SpritesView(model: machine.spriteDebugger)
//                }
            }
        }
        .font(Font.system(size: 14,design: .monospaced))
    }
}

//#Preview {
//    Debugger()
//}
