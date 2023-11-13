//
//  BinCodeViewer.swift
//  z80play
//
//  Created by German Laullon on 13/11/23.
//

import SwiftUI

struct BinCodeViewer: View {
    @ObservedObject var status: MachineStatus

    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                    ForEach(status.ops) { op in
                        if op.valid {
                            if op.inst is Inst {
                                let dump = op.bytes.map({$0.toHexShort()}).joined(separator: " ")
                                let dis = z80InstructionSet.shared.disassembler(data: op.bytes)
                                Text("\(op.pc.toHex()) \(dump)")
                                    .help("\(dis)\n\(op.description)")
                                    .background((status.nextPc == op.pc) ? .green : .clear)
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
                    .lineLimit(1)
            }
            .frame(width: 170, alignment: .leading)
        }
    }
}

#Preview {
    let doc = z80playDocument()
    return BinCodeViewer(status: doc.machine.status)
}
