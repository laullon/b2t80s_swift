//
//  DebuggerPanel.swift
//  z80play
//
//  Created by German Laullon on 7/11/23.
//

import SwiftUI

struct DebuggerPanel: View {
    @ObservedObject var machine: MachinePlay
    
    init(machine: MachinePlay) {
        self.machine = machine
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            DebuggerRegisters(debugData: machine.registersData)
                .fixedSize()
            Divider()
            Watch(machine: machine)
            Divider()
            TabView {
                DebuggerMemory(model: machine.memDebugger)
                    .tabItem {
                        Text("Memory")
                    }
                SpritesView(model: machine.spriteDebugger)
                    .tabItem {
                        Text("Sprites")
                    }
                Screen(machine: machine)
                    .tabItem {
                        Text("Screen")
                    }
                Table(machine.log) {
                    TableColumn("PC", value: \.pc)
                    TableColumn("Ins", value: \.inst)
                }
                .tabItem {
                    Text("Log")
                }
            }
        }.padding(5)
    }
}

#Preview {
    return DebuggerPanel(machine: MachinePlay()).frame(height: 500)
}
