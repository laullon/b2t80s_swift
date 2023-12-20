//
//  ToolBar.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import SwiftUI

struct ToolBar: View {
    @ObservedObject private var machine: MachinePlay
    
    init(machine: MachinePlay) {
        self.machine = machine
    }
    
    var body: some View {
        HStack {
            Button() {
                Task { await machine.reset() }
            } label: {
                Image(systemName: "backward.end.alt")
            }
            .help("Reset")
            .disabled(machine.status != .paused)
            
            Button() {
                Task { await machine.start(fast: false) }
            } label: {
                Image(systemName: "play")
            }
            .help("Run")
            .disabled(machine.status != .paused)
            
            Button() {
                Task { await machine.start(fast: true) }
            } label: {
                Image(systemName: "forward")
            }
            .help("Run")
            .disabled(machine.status != .paused)
            
            Button() {
                Task { await machine.step() }
            } label: {
                Image(systemName: "forward.frame")
            }
            .help("Step")
            .disabled(machine.status != .paused)
            
            Button() {
                machine.stop()
            } label: {
                Image(systemName: "pause")
            }
            .help("Pause")
            .disabled(machine.status != .runing)
        }
    }
}

//#Preview {
//    ToolBar(machine: Machine())
//}
