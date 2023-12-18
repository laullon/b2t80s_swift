//
//  DebuggerRegisters.swift
//  b2t80s
//
//  Created by German Laullon on 6/11/23.
//

import SwiftUI

struct DebuggerRegisters: View {
    @ObservedObject var debugData: RegistersData
    
    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Text("Registers")
                Divider()
                HStack{
                    Grid(alignment: .leading) {
                        GridRow {
                            RegView(label: "A:", value: debugData.reg8[0])
                            RegView(label: "F:", value: debugData.reg8[1])
                        }
                        GridRow {
                            RegView(label: "B:", value: debugData.reg8[2])
                            RegView(label: "C:", value: debugData.reg8[3])
                        }
                        GridRow {
                            RegView(label: "D:", value: debugData.reg8[4])
                            RegView(label: "E:", value: debugData.reg8[5])
                        }
                        GridRow {
                            RegView(label: "H:", value: debugData.reg8[6])
                            RegView(label: "L:", value: debugData.reg8[7])
                        }
                        GridRow {
                            RegView(label: "IXL:", value: debugData.reg8[8])
                            RegView(label: "IXH:", value: debugData.reg8[9])
                        }
                        GridRow {
                            RegView(label: "IYH:", value: debugData.reg8[10])
                            RegView(label: "IYL:", value: debugData.reg8[11])
                        }
                        GridRow {
                            Divider().gridCellColumns(4).gridCellUnsizedAxes(.horizontal)
                        }
                        GridRow {
                            HStack{
                                Text("Flags:")
                                FDetail(debugData: debugData)
                            }.gridCellColumns(4)
                        }
                    }
                    VStack {
                        RegView(label: "AF:", value: debugData.reg16[0])
                        RegView(label: "BC:", value: debugData.reg16[1])
                        RegView(label: "DE:", value: debugData.reg16[2])
                        RegView(label: "HL:", value: debugData.reg16[3])
                        RegView(label: "IX:", value: debugData.reg16[4])
                        RegView(label: "IY:", value: debugData.reg16[5])
                        RegView(label: "SP:", value: debugData.reg16[6])
                        RegView(label: "PC:", value: debugData.reg16[7])
                    }
                }
            }
            Divider()
            VStack {
                Text("Stack")
                Divider()
                ForEach(Array(debugData.spStack.enumerated()), id: \.0) { idx, data in
                    Text("\((debugData.sp&+UInt16((idx*2))).toHex()) \(data)")
                }
            }
        }
    }
}

#Preview {
    DebuggerRegisters(debugData: RegistersData()).frame(width: 400).padding(50)
}

struct RegView: View {
    var label: String
    private var value: (String, Bool)
    
    init(label: String, value: (UInt8, Bool)) {
        self.label = label
        self.value = (value.0.toHex(), value.1)
    }
    
    init(label: String, value: (UInt16, Bool)) {
        self.label = label
        self.value = (value.0.toHex(), value.1)
    }
    
    var body: some View {
        HStack{
            Text(label)
                .lineLimit(1)
                .fixedSize()
                .frame(maxWidth: 40, alignment: .trailing)
            Text(value.0)
                .lineLimit(1)
                .fixedSize()
                .foregroundColor(value.1 ? .blue : .black)
        }
    }
}

class RegistersData: ObservableObject {
    var reg8: [(UInt8, Bool)]
    var reg16: [(UInt16, Bool)]
    var spStack: [String]
    var flgs: flags
    var sp: UInt16
    
    init() {
        reg8 = Array(repeating: (0, false), count: 12)
        reg16 = Array(repeating: (0, false), count: 8)
        spStack = Array(repeating: "0x0000", count: 4)
        flgs = flags()
        sp = UInt16(0)
    }
    
    init(regs: Registers, stack s: [UInt8], prev: RegistersData) {
        let stack = s.enumerated()
            .map{ idx, data in (idx,data) }
            .reduce(into: Array(repeating: UInt16(0), count: 8)) { (res, arg1) in
                let (idx, data) = arg1
                res[idx/2] += idx%2==0 ? UInt16(data) : UInt16(data)<<8
            }
        
        flgs = regs.F
        sp = regs.SP
        spStack = stack.map {$0.toHex()}
        let AF = ((UInt16(regs.A)<<8)|UInt16(regs.F.GetByte()))
        reg8 = [
            (regs.A, prev.reg8[0].0 != regs.A),
            (regs.F.GetByte(), prev.reg8[1].0 != regs.F.GetByte()),
            (regs.B, prev.reg8[2].0 != regs.B),
            (regs.C, prev.reg8[3].0 != regs.C),
            (regs.D, prev.reg8[4].0 != regs.D),
            (regs.E, prev.reg8[5].0 != regs.E),
            (regs.H, prev.reg8[6].0 != regs.H),
            (regs.L, prev.reg8[7].0 != regs.L),
            (regs.IXH, prev.reg8[8].0 != regs.IXH),
            (regs.IXL, prev.reg8[9].0 != regs.IXL),
            (regs.IYH, prev.reg8[10].0 != regs.IYH),
            (regs.IYL, prev.reg8[11].0 != regs.IYL),
        ]
        reg16 = [
            (AF, prev.reg16[0].0 != AF),
            (regs.BC, prev.reg16[1].0 != regs.BC),
            (regs.DE, prev.reg16[2].0 != regs.DE),
            (regs.HL, prev.reg16[3].0 != regs.HL),
            (regs.IX, prev.reg16[4].0 != regs.IX),
            (regs.IY, prev.reg16[5].0 != regs.IY),
            (regs.SP, prev.reg16[6].0 != regs.SP),
            (regs.PC, prev.reg16[7].0 != regs.PC),
        ]
    }
}

struct FDetail : View {
    @ObservedObject var debugData: RegistersData
    
    var body: some View {
        Group{
            Text("S").foregroundColor(debugData.flgs.S ? Color.blue : Color.gray) +
            Text("Z").foregroundColor(debugData.flgs.Z ? Color.blue : Color.gray) +
            Text("5").foregroundColor(Color.gray) +
            Text("H").foregroundColor(debugData.flgs.H ? Color.blue : Color.gray) +
            Text("3").foregroundColor(Color.gray) +
            Text("P").foregroundColor(debugData.flgs.P ? Color.blue : Color.gray) +
            Text("N").foregroundColor(debugData.flgs.N ? Color.blue : Color.gray) +
            Text("C").foregroundColor(debugData.flgs.C ? Color.blue : Color.gray)
        }
    }
}
