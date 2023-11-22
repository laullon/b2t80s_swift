//
//  DebuggerMemory.swift
//  b2t80s
//
//  Created by German Laullon on 19/10/23.
//

import SwiftUI

class DebuggerMemoryModel:ObservableObject {
    @Published var symbols: [Symbol] = []
    @Published var data: [UInt8] = []
    @Published var start: Symbol = Symbol(addr: 0, name: "")
    var count: UInt16 = 0
    var updater: ((_ start: UInt16, _ count:UInt16)->[UInt8])?
    
    func update() {
        data = (updater ?? empty)(start.addr, 0x100)
    }
    
    private func empty(_ start: UInt16, _ count:UInt16) -> [UInt8] {
        return Array(repeating: 0, count: Int(count))
    }
}

private extension Array where Element == UInt8 {
    func dump(addr: UInt16) -> String {
        var res = ""
        self.unfoldSubSequences(limitedTo: 16).enumerated().forEach( {(idx,data) in
            res += "\n\((addr &+ UInt16(idx*0x10)).toHex())"
            res = data.reduce(res) { "\($0) \($1.toHexShort())" }
        })
        return res
    }
}

struct DebuggerMemory : View {
    @ObservedObject var model: DebuggerMemoryModel

    var body: some View {
        VStack {
            HStack{
                Button("<<") {
                    model.start.addr &-= 16 * 16
                }
                Button("<") {
                    model.start.addr &-= 16
                }
                AddrSelector(model: model)
                Button(">") {
                    model.start.addr &+= 16
                }
                Button(">>") {
                    model.start.addr &+= 16 * 16
                }
            }
            Text(model.data.dump(addr: model.start.addr))
                .lineLimit(16)
                .fixedSize()
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment:.leading)
        .font(Font.system(.body, design: .monospaced))
        .onAppear(perform: {
            model.update()
        })
        .onChange(of: model.start.addr) { oldValue, newValue in
            model.update()
        }
    }
}

#Preview {
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]

    let model = DebuggerMemoryModel()
    model.symbols = symbs
    model.data = Array(repeating: 0, count: Int(0x100))
    
    return DebuggerMemory(model: model).padding(10).frame(height: 400)
}
