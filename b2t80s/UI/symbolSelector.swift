//
//  symbolSelector.swift
//  b2t80s
//
//  Created by German Laullon on 28/9/23.
//

import SwiftUI

struct Symbol: Comparable, Hashable {
    var addr: UInt16
    var name: String
    
    static func < (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.addr < rhs.addr
    }
}

struct SymbolSelector: View {
    @Binding var symbols: [Symbol]
    @Binding var selection: Symbol

    @State private var pop = false
    @State private var listSelection: String = ""

    var body: some View {
        Button() {
            pop.toggle()
        } label: {
            Image(systemName: "list.bullet")
        }
        .popover(isPresented: $pop) {
            List(selection: $listSelection) {
                ForEach(Array(symbols.sorted(by: <)), id: \.self) { symbol in
                    Text("\(symbol.addr.toHex()) - \(symbol.name)")
                        .tag("\(symbol.addr.toHex()) - \(symbol.name)")
                }
            }.onChange(of: listSelection) {
                pop.toggle()
                let comps = listSelection.split(separator: " - ")
                let addr = String(comps[0].trimmingPrefix("0x"))
                let sym = String(comps[1])
                selection = Symbol(addr: UInt16(addr, radix: 16)!, name: sym)
            }
        }
    }
}
