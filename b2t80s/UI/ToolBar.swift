//
//  ToolBar.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import SwiftUI

struct ToolBar: ToolbarContent {
    @ObservedObject var machine: MachineZX48K
    
    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button() {
                Task { await machine.reset() }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .help("Reset")
            
            Button() {
                Task {
                    await machine.start(fast: false)
                }
            } label: {
                Image(systemName: "play")
            }
            .help("Run")
            .disabled(machine.status != .paused)
            
            Button() {
                Task { await machine.step() }
            } label: {
                Image(systemName: "forward.frame")
            }
            .help("Step")
            .disabled((machine.status != .paused) || (!machine.showDebuger))
            
            Button() {
                machine.stop()
            } label: {
                Image(systemName: "pause")
            }
            .help("Pause")
            .disabled(machine.status != .runing)
            
            Button() {
                machine.showDebuger.toggle()
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Pause")
        }
        
        ToolbarItem(placement: .navigation) {
            Text("hola")
        }
    }
}

//#Preview {
//    return ToolBar(machine: MachineZX48K())
//}
