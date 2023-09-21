//
//  swift
//  b2t80s
//
//  Created by German Laullon on 29/8/23.
//

import Foundation
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

class ULA: PortManager {
    
    
    //    memory *memory
    //    bus    z80.Bus
    var cpu: z80
    //
    var keyboardRow = Array(repeating: UInt8(0), count: 8)
    var borderColour = BitmapColor(r: 0xff, g: 0xff, b: 0xff, a: 0xff)
    //
    var frame = UInt8(0)
    //    display *gui.Display
    //    monitor emulator.Monitor
    
    var col = 0
    var row = 0
    var tsPerRow: Int
    var scanlines: Int
    var displayStart: Int
    
    var floatingBus: UInt8 = 0
    //
    //    cassette       cassette.Cassette
    var ear = false
    var earActive = false
    var buzzer = false
    //    out            []*emulator.SoundData
    //    mux            sync.Mutex
    //
    
    var monitor = Monitor()
    var bitmap = Bitmap(width: 448, height: 312, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))

    let sound = SoundEngine()
    var soundFrame = 0
    
    init(cpu: z80) {
        self.cpu = cpu
        //    func NewULA(mem *memory, bus z80.Bus, plus bool) *ula {
        //        ula := &ula{
        //        memory:          mem,
        //        bus:             bus,
        //        keyboardRow:     make([]UInt8, 8),
        //        borderColour:    palette[0],
        //        x: make([][]color.RGBA, 313),
        //        pixlesData:      make([][]UInt8, 192),
        //        pixlesAttr:      make([][]UInt8, 192),
        //        display:         gui.NewDisplay(gui.Size{352, 296}),
        //        }
        //
        //        monitor = emulator.NewMonitor(display)
        //
        //        if !plus {
        //            // 48k
        tsPerRow = 224
        scanlines = 312
        displayStart = 64
        //        } else {
        //            // 128k
        //            tsPerRow = 228
        //            scanlines = 311
        //            displayStart = 63
        //        }
        //
        
        keyboardRow[0] = 0x1f
        keyboardRow[1] = 0x1f
        keyboardRow[2] = 0x1f
        keyboardRow[3] = 0x1f
        keyboardRow[4] = 0x1f
        keyboardRow[5] = 0x1f
        keyboardRow[6] = 0x1f
        keyboardRow[7] = 0x1f
    }
    
    func tick() {
        //        // EAR
        //        if cassette != nil {
        //            ear = cassette.Ear()
        //        }
        
        // Sound
        if soundFrame == 0 {
            sound.tick(buzzer)
        }
        soundFrame += 1
        if soundFrame == 50 {
            soundFrame = 0
        }
        
        // SCREEN
        var draw = false
        var io = false
        if col < 128 && row >= displayStart && row < displayStart+192 {
            io = (col % 8) < 6
            draw = col%4 == 0
        } else {
            floatingBus = 0xff
        }
        
        let rx = col * 2
        let ry = row
        var border = false
        
        if (ry < displayStart) || (ry >= (displayStart+192)) {
            border = true
        } else if rx < 48 || rx > 47+256 {
            border = true
        }
        
        if border && (col%4 == 0){
            let x = Int(col) / 4
            let px = (x*8)
            for i in 0..<8 {
                bitmap[px+i,row] = borderColour
            }
        }
        
        // CPU CLOCK
        if io {
            if (cpu.bus.addr >> 14) != 1 {
                cpu.tick()
            }
        } else {
            cpu.tick()
        }
        
        if draw {
            let y = Int(row - displayStart)
            let x = Int(col) / 4
            var addr = Int(0)
            addr |= ((y & 0b00000111) | 0b01000000) << 8
            addr |= ((y >> 3) & 0b00011000) << 8
            addr |= ((y << 2) & 0b11100000)
            let pixles = cpu.bus.readVideoMemory(UInt16(addr + x))
            floatingBus = pixles

            let attrAddr = UInt16(((y >> 3) * 32) + 0x5800)
            let attr = cpu.bus.readVideoMemory(attrAddr + UInt16(x))
            
            let px = (x*8)+48
            for (i, c) in getPixelsColors(attr: attr, pixles: pixles).enumerated() {
                bitmap[px+i,row] = c
            }
        }
        
        col += 1
        if col == tsPerRow {
            col = 0
            row += 1
            if row == scanlines {
                row = 0
                col = 24
                cpu.doInterrupt = true
                FrameDone()
            }
        }
    }
    //
    func FrameDone() {
        frame = (frame + 1) & 0x1f
        monitor.image = Image(bitmap.cgImage(), scale: 1, label: Text(verbatim: ""))
        
        //            monitor.FrameDone()
    }
    //
    
    func readPort(_ port: UInt16) -> (UInt8, Bool) {
        if port&0xff == 0xfe {
            var data = UInt8(0b00011111)
            let readRow = port >> 8
            for row in 0..<8 {
                if (readRow & (1 << row)) == 0 {
                    data &= keyboardRow[row]
                }
            }
            if earActive && ear {
                data |= 0b11100000
            } else {
                data |= 0b10100000
            }
            return (data, false)
        }
        return (floatingBus, false)
    }
    
    func writePort(_ port: UInt16, _ data: UInt8) {
        if port&0xff == 0xfe {
            //            if borderColour != palette[Int(data&0x07)] {
            borderColour = palette[Int(data&0x07)]
            // println("------", col, row)
            //            }
            buzzer = ((data & 16) >> 4) != 0
            earActive = (data & 24) != 0
//            print("buzzer:", buzzer,"\t soundFrame:",soundFrame)
        } else {
            // log.Printf("[write] port:0x%02x data:0b%08b", port, data)
        }
        // log.Printf("[write] port:0x%02x data:0b%08b", port, data)
        // keyboardRow[port] = data
    }

    func getPixelsColors(attr :UInt8, pixles: UInt8) -> [BitmapColor] {
        let flash = (attr & 0x80) == 0x80
        let brg = (attr & 0x40) >> 6
        let paper = palette[Int(((attr&0x38)>>3)+(brg*8))]
        let ink = palette[Int((attr&0x07)+(brg*8))]
        
        var colors = Array(repeating: palette[0], count: 8)
        for b in 0..<8 {
            var data = pixles
            data = data << b
            data &= 0b10000000
            if flash && (frame&0x10 != 0) {
                if data != 0 {
                    colors[b] = paper
                } else {
                    colors[b] = ink
                }
            } else if data != 0 {
                colors[b] = ink
            } else {
                colors[b] = paper
            }
        }
        return colors
    }
}
