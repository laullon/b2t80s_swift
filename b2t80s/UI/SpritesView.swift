//
//  SpritesView.swift
//  b2t80s
//
//  Created by German Laullon on 16/10/23.
//

import SwiftUI

struct SpritesView: View {
    @State var addr: String = ""
    @Binding var symbols: [Symbol]
    @State var newSymbol = Symbol(addr: 0, name: "")
    
    @State private var rows = 8
    @State private var cols = 1
    @State private var sprites = 1
    @State private var data : [Sprite] = []
                           
    var getData : (_ bytes: Int) -> [UInt8]

    var body: some View {
        VStack {
            HStack {
                TextField("0x0000 - label", text: $addr)
            }
            HStack {
                Text("rows:")
                TextField("", value: $rows, formatter: NumberFormatter())
                    .frame(width: 60)
                Text("sprites:")
                TextField("", value: $sprites, formatter: NumberFormatter())
            }
            Table(data) {
                TableColumn("") { sprite in
                    Image(sprite.bitmap.cgImage(), scale:0.1, label: Text(verbatim: ""))
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .padding(2)
                        .border(Color.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                }
                .alignment(.center)
                TableColumn("db hex") { sprite in
                    Text(sprite.data.reduce("", { r,v in r+"\ndb "+v.toHex() }).trimmingCharacters(in: .newlines))
                        .lineLimit(rows)
                }
                TableColumn("db bin") { sprite in
                    Text(sprite.data.reduce("", { r,v in r+"\ndb "+v.toBin() }).trimmingCharacters(in: .newlines))
                        .lineLimit(rows)
                }
            }
        }
        .font(Font.system(.body, design: .monospaced))
        .onSubmit {
            reload()
        }
        .onAppear {
            reload()
        }
    }
    
    func reload() {
        let newData = getData(rows*sprites)
        data = []
        for s in 0..<sprites {
            var d : [UInt8] = []
            for i in 0..<rows {
                d.append(newData[(s*rows)+i])
            }
            data.append(Sprite(rows: rows, data: d))
        }

    }
}

#Preview {
    print("lll")
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]

    let s = Binding<[Symbol]>(
        get: {
            return symbs
        }, set: { val in
            print(val)
        }
    )

    return SpritesView(symbols: s, getData: {bytes in 
        let data : [UInt8] = [0b00111100,
                0b01111110,
                0b11011011,
                0b11111111,
                0b11011011,
                0b11100111,
                0b11111111,
                0b10101010,
                
                0b00000000,
                0b00000000,
                0b00000000,
                0b00000000,
                0b00000000,
                0b00000000,
                0b00000000,
                0b00000000,

                0b11000000,
                0b11100000,
                0b10110000,
                0b11110000,
                0b10110000,
                0b01110000,
                0b11110000,
                0b10100000,

                0b00000011,
                0b00000111,
                0b00001101,
                0b00001111,
                0b00001101,
                0b00001110,
                0b00001111,
                0b00001010,
        ]
        return Array(data[0..<bytes])
    })
}

struct Sprite :Identifiable {
    var id = UUID()
    var data: [UInt8]
    var bitmap: Bitmap
    
    init(id: UUID = UUID(), rows: Int, data: [UInt8]) {
        self.id = id
        self.data = data
        self.bitmap = Bitmap(width: 8, height: rows, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
        for y in 0..<rows {
            var row = data[y]
            for x in 0..<8 {
                if (row&0x80) != 0 {
                    bitmap[x,y] = BitmapColor(r: 0, g: 0, b: 0, a: 0xff)
                } else {
                    bitmap[x,y] = BitmapColor(r: 0xff, g: 0xff, b: 0xff, a: 0xff)
                }
                row = row<<1
            }
        }
    }
}
