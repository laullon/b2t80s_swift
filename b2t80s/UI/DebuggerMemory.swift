//
//  DebuggerMemory.swift
//  b2t80s
//
//  Created by German Laullon on 19/10/23.
//

import SwiftUI

struct DebuggerMemory : View {
    var symbols: [Symbol]
    var getData : (_ start: UInt16,_ bytes: UInt16) -> [UInt8]
    
    @State private var menStart: UInt16 =  0
    @State private var mem = ""
    @State private var addr = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Button("<<") {
                    menStart &-= 16 * 16
                }
                Button("<") {
                    menStart &-= 16
                }
                AddrSelector(symbols: symbols, selection: $addr)
                Button(">") {
                    menStart &+= 16
                }
                Button(">>") {
                    menStart &+= 16 * 16
                }
            }
            Text(mem)
                .lineLimit(16)
                .fixedSize()
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment:.leading)
        .onChange(of: menStart) { oldValue, newValue in
            reload()
        }
        .onChange(of: addr) {
            let comps = addr.split(separator: " ")
            menStart = UInt16(asm: String(comps[0]))!
            reload()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
                reload()
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }
    
    func reload() {
        let data = getData(menStart, 0x100)
        var addr = menStart
        var str = ""
        for r in 0..<16 {
            str = "\(str)\(addr.toHex())"
            for c in 0..<16 {
                str = "\(str) \(data[(r*16)+c].toHexShort())"
                addr &+= 1
            }
            str = "\(str)\n"
        }
        mem = str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]
    return DebuggerMemory(symbols: symbs, getData: { start, count in
        return Array(repeating: UInt8(start&0xff), count: 0x100)
    }).padding(10).frame(height: 400)
}
