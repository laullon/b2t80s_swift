//
//  ContentView.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: z80playDocument
    @State var ops: [Op] = []
    @State var debug: String = ""
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                ForEach(ops) { op in
                    if op.valid {
                        if op.inst is Inst {
                            let dump = op.bytes.map({$0.toHexShort()}).joined(separator: " ")
                            let dis = z80InstructionSet.shared.disassembler(data: op.bytes)
                            Text("\(op.pc.toHex()) \(dump)")
                                .help("\(dis)\n\(op.description)")
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
                .frame(width: 160,alignment: .leading)
                .lineLimit(1)
            }
            Divider()
            TextEditor(text: $document.text)
                .lineSpacing(0)
        }
        .font(Font.system(size: 14,design: .monospaced))
        .onAppear() {
            ops = document.complie()
        }
        .onChange(of: document.text, {
            ops = []
            ops = document.complie()
        })
        .background(.white)
    }
}

#Preview {
    ContentView(document: .constant(z80playDocument()))
}

