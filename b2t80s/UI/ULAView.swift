//
//  ULAView.swift
//  b2t80s
//
//  Created by German Laullon on 17/10/23.
//

import SwiftUI

struct ULAView: View {
    var bitmap: Bitmap
    @StateObject private var monitor: Monitor = Monitor()
    
    var body: some View {
        Image(bitmap.cgImage(), scale:1, label: Text(verbatim: ""))
            .interpolation(.none)
            .aspectRatio(contentMode: .fit)
            .padding(2)
            .border(Color.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .frame(width: 448, height: 312)
            .onAppear(perform: {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
                    monitor.image = Image(bitmap.cgImage(), scale: 1, label: Text(verbatim: ""))
                }
            })
    }
}

#Preview {
    let bitmap = Bitmap(width: 10, height: 10, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
    return ULAView(bitmap: bitmap)
}


