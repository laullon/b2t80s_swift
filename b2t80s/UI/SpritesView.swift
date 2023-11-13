//
//  SpritesView.swift
//  b2t80s
//
//  Created by German Laullon on 16/10/23.
//

import SwiftUI

enum Flow: String, CaseIterable, Identifiable {
    case down
    case right
    var id: String { rawValue }
}

struct SpritesView: View {
    @ObservedObject var model: DebuggerMemoryModel

    @State private var newSymbol = Symbol(addr: 0, name: "")
    @State private var menStart: UInt16 =  0
    
    @AppStorage("SPView.rows") private var rows = 8
    @AppStorage("SPView.cols") private var cols = 1
    @AppStorage("SPView.sprites") private var sprites = 1
    @AppStorage("SPView.flow") private var flow = Flow.down
    @State private var spritesList : [Sprite] = []
    
    var body: some View {
        VStack {
            AddrSelector(model: model)
            HStack {
                Text("Cols:")
                    .fixedSize()
                TextField("", value: $cols, formatter: NumberFormatter())
                    .frame(width: 60)
                
                Text("Rows:")
                    .fixedSize()
                
                TextField("", value: $rows, formatter: NumberFormatter())
                    .frame(width: 60)
                
                Picker("Flow:", selection: $flow) {
                    Image(systemName: "arrow.down").tag(Flow.down)
                    Image(systemName: "arrow.right").tag(Flow.right)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                
                Text("sprites:")
                    .fixedSize()
                
                TextField("", value: $sprites, formatter: NumberFormatter())
            }
            Table(spritesList) {
                TableColumn("") { sprite in
                    Image(sprite.bitmap.cgImage(), scale:0.1, label: Text(verbatim: ""))
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
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
        .onAppear(perform: {
            reload()
        })
        .onChange(of: model.start.addr) { oldValue, newValue in
            reload()
        }
        .onChange(of: model.data) { oldValue, newValue in
            reload()
        }
        .onChange(of: flow) {
            reload()
        }
        .onSubmit {
            reload()
        }
        .onAppear {
            reload()
        }
    }
    
    func reload() {
        model.count = UInt16(cols*rows*sprites)
        spritesList = []
        model.update()
        let data = model.data.unfoldSubSequences(limitedTo: cols*rows)
        data.forEach { data in
            spritesList.append(Sprite(rows: rows, cols: cols, data: Array(data), flow: flow))
        }
    }
}

struct Sprite :Identifiable {
    var id = UUID()
    var data: [UInt8]
    var bitmap: Bitmap
    
    init(rows: Int, cols: Int, data: [UInt8], flow: Flow) {
        self.data = data
        self.bitmap = Bitmap(width: 8*cols, height: rows, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
        if flow == .right {
            for y in 0..<rows {
                for col in 0..<cols{
                    var row = data[y*cols+col]
                    for x in 0..<8 {
                        if (row&0x80) != 0 {
                            bitmap[x+(8*col),y] = BitmapColor(r: 0, g: 0, b: 0, a: 0xff)
                        } else {
                            bitmap[x+(8*col),y] = BitmapColor(r: 0xff, g: 0xff, b: 0xff, a: 0xff)
                        }
                        row = row<<1
                    }
                }
            }
        } else {
            for y in 0..<rows {
                for col in 0..<cols{
                    var row = data[(rows*col)+y]
                    for x in 0..<8 {
                        if (row&0x80) != 0 {
                            bitmap[x+(8*col),y] = BitmapColor(r: 0, g: 0, b: 0, a: 0xff)
                        } else {
                            bitmap[x+(8*col),y] = BitmapColor(r: 0xff, g: 0xff, b: 0xff, a: 0xff)
                        }
                        row = row<<1
                    }
                }
            }
        }
    }
}

#Preview {
    let symbs = [Symbol(addr: 0x1234, name: "aaa")]
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
                          
                          0b00000011,0b11000000,
                          0b00000111,0b11100000,
                          0b00001101,0b10110000,
                          0b00001111,0b11110000,
                          0b00001101,0b10110000,
                          0b00001110,0b01110000,
                          0b00001111,0b11110000,
                          0b00001010,0b10100000,
    ]

    let model = DebuggerMemoryModel()
    model.symbols = symbs
    model.data = data

    return SpritesView(model: model).padding(10).frame(height: 400)
}
