//
//  ToolBar.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import SwiftUI

struct ToolBar: View {
    var machine: Machine
    @ObservedObject var status: MachineStatus

    init(machine: Machine) {
        self.machine = machine
        self.status = machine.status
    }
    
    var body: some View {
        HStack {
            Button() {
                Task { await machine.reset() }
            } label: {
                Image(systemName: "backward.end.alt")
            }
            .help("Reset")
            .disabled(status.status != .ready)
            
            Button() {
                Task { await machine.start(fast: false) }
            } label: {
                Image(systemName: "play")
            }
            .help("Run")
            .disabled(status.status != .ready)
            
            Button() {
                Task { await machine.start(fast: true) }
            } label: {
                Image(systemName: "forward")
            }
            .help("Run")
            .disabled(status.status != .ready)
            
            Button() {
                Task { await machine.step() }
            } label: {
                Image(systemName: "forward.frame")
            }
            .help("Step")
            .disabled(status.status != .ready)
            
            Button() {
                machine.stop()
            } label: {
                Image(systemName: "pause")
            }
            .help("Pause")
            .disabled(status.status != .runing)
        }
    }
}
    
    #Preview {
        ToolBar(machine: Machine())
    }
