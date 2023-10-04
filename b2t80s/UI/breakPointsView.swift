//
//  bookmarks.swift
//  b2t80s
//
//  Created by German Laullon on 26/9/23.
//

import SwiftUI

struct BreakPoint :Identifiable, Equatable, Comparable, Codable {
    var id = UUID()
    
    var active: Bool
    var addr: UInt16
    var symbol: String
    
    static func < (lhs: BreakPoint, rhs: BreakPoint) -> Bool {
        return lhs.addr < rhs.addr
    }
}

struct BreakPointsView: View {
    @Binding var breakPoints: [BreakPoint]
    @Binding var symbols: [Symbol]
    @State var newSymbol = Symbol(addr: 0, name: "")
    @State var newBreakPoint: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("0x0000 - label", text: $newBreakPoint)
                SymbolSelector(symbols: $symbols, selection: $newSymbol)
            }
            Table(breakPoints.sorted(by: <)){
                TableColumn("") { mark in
                    Toggle("", isOn: Binding<Bool>(
                        get: {
                            return mark.active
                        },
                        set: {
                            if let index = breakPoints.firstIndex(where: { $0.id == mark.id }) {
                                self.breakPoints[index].active = $0
                            }
                        }
                    ))
                }
                .width(15)
                TableColumn("addr") { mark in Text(mark.addr.toHex()) }
                TableColumn("symbol", value: \.symbol)
                TableColumn("") { mark in Image(systemName: "trash")
                        .onTapGesture(count: 1) {
                            if let index = breakPoints.firstIndex(where: { $0.id == mark.id }) {
                                self.breakPoints.remove(at: index)
                            }
                        }
                }
                .width(15)
            }
        }
        .onChange(of: newSymbol) {
            breakPoints.append(BreakPoint(active: true, addr: newSymbol.addr, symbol: newSymbol.name))
        }
        .onChange(of: newBreakPoint) {
            let comps = newBreakPoint.split(separator: " - ")
            let addr = String(comps[0].trimmingPrefix("0x"))
            let sym = String(comps[optional: 1] ?? "")
            breakPoints.append(BreakPoint(active: true, addr: UInt16(addr, radix: 16)!, symbol: sym))
        }
    }
}

#Preview {
    let bps = [
        BreakPoint(active: true,addr: 0x1234,symbol: "a"),
        BreakPoint(active: false,addr: 0x4321,symbol: "b"),
        BreakPoint(active: true,addr: 0xabcd,symbol: "c"),
    ]
    
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]
    
    let m = Binding<[BreakPoint]>(
        get: {
            return bps
        }, set: { val in
            print(val)
        }
    )
    
    let s = Binding<[Symbol]>(
        get: {
            return symbs
        }, set: { val in
            print(val)
        }
    )
    
    return BreakPointsView(breakPoints: m,symbols: s)
}

