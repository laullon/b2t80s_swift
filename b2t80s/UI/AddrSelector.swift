//
//  symbolSelector.swift
//  b2t80s
//
//  Created by German Laullon on 28/9/23.
//

import SwiftUI

extension String {
    struct AddrFormatStyle: Foundation.ParseableFormatStyle {
        public func format(_ value: String) -> String {
            return value
        }
        
        public var parseStrategy: String.AddrParseStrategy {
            return String.AddrParseStrategy()
        }
    }
    
    struct AddrParseStrategy: Foundation.ParseStrategy {
        public func parse(_ value: String) throws -> String {
            let regex = /0?x?([0-9a-fA-F]{0,4})\s?(.*)/

            let res = try regex.wholeMatch(in: value)!
            return "0x\(res.1) \(res.2)".trimmingCharacters(in: .whitespaces)
        }
    }
}

extension FormatStyle where Self == String.AddrFormatStyle {
    static var addr: String.AddrFormatStyle {
        String.AddrFormatStyle()
    }
}

struct Symbol: Comparable, Hashable {
    var addr: UInt16
    var name: String
    
    static func < (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.addr < rhs.addr
    }
}

struct AddrSelector: View {
    let symbols: [Symbol]
    @Binding var selection: String
    
    @State private var pop = false
    @State private var listSelection: String = ""
    @State private var text = "0x0000"
    
    var body: some View {
        HStack {
            TextField("",value: $text, format: .addr)
            Button() {
                pop.toggle()
            } label: {
                Image(systemName: "list.bullet")
            }
            .popover(isPresented: $pop) {
                List(selection: $listSelection) {
                    ForEach(Array(symbols.sorted(by: <)), id: \.self) { symbol in
                        Text("\(symbol.addr.toHex()) \(symbol.name)")
                            .tag("\(symbol.addr.toHex()) \(symbol.name)")
                    }
                }
                .onChange(of: listSelection) {
                    pop.toggle()
                    text = listSelection
                    selection = text
                }
            }
        }.onSubmit {
            selection = text
        }
    }
}

#Preview {
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]
    @State var newAddr: String = ""
    
    return AddrSelector(symbols: symbs, selection: $newAddr).padding(10)
}
