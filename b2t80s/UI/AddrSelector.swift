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
    @ObservedObject var model: DebuggerMemoryModel
    
    @State private var pop = false
    @State private var listSelection: String = ""
    @State private var text = "0x0000"
    
    @State private var searchText = ""
    
    var searchResults: [Symbol] {
        if searchText.isEmpty {
            return model.symbols.sorted(by: <)
        } else {
            return model.symbols.sorted(by: <).filter { "\($0.addr.toHex())\($0.name)".contains(searchText) }
        }
    }
    
    
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
                    TextField("name:",text: $searchText).textFieldStyle(.roundedBorder)
                        ForEach(searchResults, id: \.self) { symbol in
                            Text("\(symbol.addr.toHex()) \(symbol.name)")
                                .tag("\(symbol.addr.toHex()) \(symbol.name)")
                        }
                }
                .searchable(text: $searchText, prompt: Text("Search"))
                .onChange(of: listSelection) {
                    pop.toggle()
                    text = listSelection
                    let comps = text.split(separator: " ")
                    model.start.addr = UInt16(asm: String(comps[0])) ?? 0
                    if comps.count == 2 {
                        model.start.name = String(comps[1])
                    }
                }
            }
        }.onChange(of: model.start.addr) { oldValue, newValue in
            text = model.start.addr.toHex()
        }.onSubmit {
            let comps = text.split(separator: " ")
            model.start.addr = UInt16(asm: String(comps[0])) ?? 0
            if comps.count == 2 {
                model.start.name = String(comps[1])
            }
        }
    }
}

#Preview {
    let model = DebuggerMemoryModel()
    model.symbols = [
        Symbol(addr: 0x1234, name: "aaa"),
        Symbol(addr: 0x1235, name: "bbb"),
        Symbol(addr: 0x1236, name: "ccc"),
    ]
    model.start = Symbol(addr: 0, name: "")
    
    return AddrSelector(model: model)
        .padding(10)
}

