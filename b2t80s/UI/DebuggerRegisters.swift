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
        Grid(alignment: .leading) {
            GridRow {
                Text("A:")
                    .lineLimit(1)
                    .fixedSize()
                Text(debugData.reg8[0])
                    .lineLimit(1)
                    .fixedSize()
                Text("F:")
                    .lineLimit(1)
                    .fixedSize()
                Text(debugData.reg8[1])
                    .lineLimit(1)
                    .fixedSize()
                FDetail(debugData: debugData).gridCellColumns(2)
                Text("SP: \(debugData.reg16[0])")
                    .lineLimit(1)
                    .fixedSize()
            }
            GridRow {
                Text("B:")
                Text(debugData.reg8[2])
                Text("C:")
                Text(debugData.reg8[3])
                Text("BC:")
                Text(debugData.reg16[1])
                    .lineLimit(1)
                    .fixedSize()
                Text("----------")
            }
            GridRow {
                Text("D:")
                Text(debugData.reg8[4])
                Text("E:")
                Text(debugData.reg8[5])
                Text("DE:")
                Text(debugData.reg16[2])
                Text(debugData.spStack[0])
            }
            GridRow {
                Text("H:")
                Text(debugData.reg8[6])
                Text("L:")
                Text(debugData.reg8[7])
                Text("HL:")
                Text(debugData.reg16[3])
                Text(debugData.spStack[1])
            }
            GridRow {
                Text("").gridCellColumns(4)
                Text("IX:")
                Text(debugData.reg16[4])
                Text(debugData.spStack[2])
            }
            GridRow {
                Text("").gridCellColumns(4)
                Text("IY:")
                Text(debugData.reg16[5])
                Text(debugData.spStack[3])
            }
        }        
        .font(Font.system(size: 14,design: .monospaced))
    }
}

#Preview {
    DebuggerRegisters(debugData: RegistersData())
}

class RegistersData: ObservableObject{
    @Published var reg8: [String] = Array(repeating: "0x00", count: 8)
    @Published var reg16: [String] = Array(repeating: "0x00", count: 6)
    @Published var spStack: [String] = Array(repeating: "0x00", count: 4)
    @Published var flgs = flags()
    
    func update(regs: Registers) {
        reg8 = [
            regs.A.toHex(),
            regs.F.GetByte().toHex(),
            regs.B.toHex(),
            regs.C.toHex(),
            regs.D.toHex(),
            regs.E.toHex(),
            regs.H.toHex(),
            regs.L.toHex(),
        ]
        reg16 = [
            regs.SP.toHex(),
            regs.BC.toHex(),
            regs.DE.toHex(),
            regs.HL.toHex(),
            regs.IX.toHex(),
            regs.IY.toHex(),
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
