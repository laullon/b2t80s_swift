//
//  Screen.swift
//  z80play
//
//  Created by German Laullon on 10/11/23.
//

import SwiftUI

var palette: [BitmapColor] =  [
    BitmapColor(r:0x00, g:0x00, b:0x00, a:0xff),
    BitmapColor(r:0x20, g:0x30, b:0xc0, a:0xff),
    BitmapColor(r:0xc0, g:0x40, b:0x10, a:0xff),
    BitmapColor(r:0xc0, g:0x40, b:0xc0, a:0xff),
    BitmapColor(r:0x40, g:0xb0, b:0x10, a:0xff),
    BitmapColor(r:0x50, g:0xc0, b:0xb0, a:0xff),
    BitmapColor(r:0xe0, g:0xc0, b:0x10, a:0xff),
    BitmapColor(r:0xc0, g:0xc0, b:0xc0, a:0xff),
    BitmapColor(r:0x00, g:0x00, b:0x00, a:0xff),
    BitmapColor(r:0x30, g:0x40, b:0xff, a:0xff),
    BitmapColor(r:0xff, g:0x40, b:0x30, a:0xff),
    BitmapColor(r:0xff, g:0x70, b:0xf0, a:0xff),
    BitmapColor(r:0x50, g:0xe0, b:0x10, a:0xff),
    BitmapColor(r:0x50, g:0xe0, b:0xff, a:0xff),
    BitmapColor(r:0xff, g:0xe8, b:0x50, a:0xff),
    BitmapColor(r:0xff, g:0xff, b:0xff, a:0xff),
]

struct Screen: View {
    @ObservedObject var machine: MachinePlay

    var body: some View {
        image(machine.bitmap)
    }
    
    @ViewBuilder func image(_ bitmap: Bitmap?) -> some View {
        if bitmap != nil {
            Image(bitmap!.cgImage(), scale:1, label: Text(verbatim: ""))
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .padding(10)
                .border(Color.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        } else {
            Image(systemName: "globe")
        }
    }
}

#Preview {
    Screen(machine: MachinePlay())
}
