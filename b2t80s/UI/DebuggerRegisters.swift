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
            Divider()
            Text("Stack")
        }
        .font(Font.system(size: 14,design: .monospaced))
    }
}

#Preview {
    DebuggerRegisters(debugData: RegistersData()).frame(width: 400).padding(50)
}

struct RegView: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack{
            Text(label)
                .lineLimit(1)
                .fixedSize()
                .frame(maxWidth: 40, alignment: .trailing)
            Text(value)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

class RegistersData: ObservableObject{
    @Published var reg8: [String] = Array(repeating: "0x00", count: 12)
    @Published var reg16: [String] = Array(repeating: "0x0000", count: 8)
    @Published var spStack: [String] = Array(repeating: "0x0000", count: 4)
    @Published var flgs = flags()
    
    func update(regs: Registers) {
        flgs = regs.F
        reg8 = [
            regs.A.toHex(),
            regs.F.GetByte().toHex(),
            regs.B.toHex(),
            regs.C.toHex(),
            regs.D.toHex(),
            regs.E.toHex(),
            regs.H.toHex(),
            regs.L.toHex(),
            regs.IXH.toHex(),
            regs.IXL.toHex(),
            regs.IYH.toHex(),
            regs.IYL.toHex(),
        ]
        reg16 = [
            ((UInt16(regs.A)<<8)|UInt16(regs.F.GetByte())).toHex(),
            regs.BC.toHex(),
            regs.DE.toHex(),
            regs.HL.toHex(),
            regs.IX.toHex(),
            regs.IY.toHex(),
            regs.SP.toHex(),
            regs.PC.toHex(),
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
