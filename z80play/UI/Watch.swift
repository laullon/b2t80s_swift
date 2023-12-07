//
//  Watch.swift
//  z80play
//
//  Created by German Laullon on 1/12/23.
//

import SwiftUI

struct Watch: View {
    @ObservedObject var machine: Machine
    
    var body: some View {
        Table(machine.watchedMemory) {
            TableColumn("Label", value: \.label)
            TableColumn("PC", value: \.pc)
            TableColumn("", value: \.data)
        }
    }
}

#Preview {
    let machine = Machine()
    var ops = [WatchEntry]()
    for i in 0..<5 {
        let data = WatchEntry(pc: UInt16(1*0x0100).toHex(),
                              label: "label \(i)",
                              data: Array(repeating: UInt8(0), count: i).dump())
        ops.append(data)
    }
    machine.watchedMemory.append(contentsOf: ops)
    return Watch(machine: machine)
}
