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

protocol ULAListener {
    func frameDone(bitmap: Bitmap)
}

class ULA: PortManager {
    var listener: ULAListener?
    
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
    
    var floatingBus: UInt8 = 0
    //
    //    cassette       cassette.Cassette
    var ear = false
    var earActive = false
    var buzzer = false
    //    out            []*emulator.SoundData
    //    mux            sync.Mutex
    //
    
//    var monitor = Monitor()
    let width = 448
    let height = 312
    var bitmap = Bitmap(width: 352, height: 296, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
    
    let sound = SoundEngine()
    var soundFrame = 0
    
    let screenH = (0...255)
    let screenV = (0...191)
    
    var data: [BitmapColor]
    var screenData: UInt8 = 0
    var attrData: UInt8 = 0
    var screenData_2: UInt8 = 0
    var attrData_2: UInt8 = 0
    var content = false
    var ts = 0


    init(cpu: z80) {
        data = Array(repeating: borderColour, count: 8)
        
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
        tsPerRow = 448 / 2
        scanlines = 312
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
    
    func getAttrAddr() -> UInt16 {
        var attrAddr = 0x5800
        attrAddr |= (row&0b11111000)<<2
        attrAddr |= (col&0b11111000)>>3
        return UInt16(attrAddr)
    }

    func getScreenAddr() -> UInt16 {
        //       _____ ________   ________ ______________
        // 0 1 0 Y7 Y6 Y2 Y1 YO | Y5 Y4 Y3 X4 X3 X2 X1 X0
        var addr = 0b010_00_000_000_00000
        addr |= (row&0b11000000)<<5
        addr |= (row&0b00000111)<<8
        addr |= (row&0b00111000)<<2
        addr |= (col&0b11111000)>>3
        return UInt16(addr)
    }
    
    func tick() {
        if cpu.wait {
            return
        }
        
        //        // EAR
        //        if cassette != nil {
        //            ear = cassette.Ear()
        //        }
        
        // Sound
        soundFrame += 1
        if soundFrame == 50 {
            soundFrame = 0
            sound.tick(buzzer)
        }

        let inScreen = screenH.contains(col) && screenV.contains(row)
        content = inScreen
        if inScreen {
            switch ts%8 {
            case 0:
                screenData = cpu.bus.readVideoMemory(getScreenAddr())
                floatingBus = screenData
                
            case 1:
                attrData = cpu.bus.readVideoMemory(getAttrAddr())
                floatingBus = attrData
                
            case 2:
                screenData_2 = cpu.bus.readVideoMemory(getScreenAddr()+1)
                floatingBus = screenData_2
                
            case 3:
                attrData_2 = cpu.bus.readVideoMemory(getAttrAddr()+1)
                floatingBus = attrData_2

            case 4:
                data.append(contentsOf: getPixelsColors(attr: attrData, pixles: screenData))
                floatingBus = 0xff

            case 5:
                data.append(contentsOf: getPixelsColors(attr: attrData_2, pixles: screenData_2))

            case 6,7:
                content = false

            default:
                fatalError()
            }
        } else {
            if (ts%8 == 3) || (ts%8 == 7) {
                data.append(contentsOf: Array(repeating:borderColour, count: 8))
            }
        }
        
        if content {
            if ((cpu.bus.addr&0xc000) != 0x4000) && ((cpu.bus.addr&0xff) != 0xfe) {
                cpu.tick()
            }
        } else {
            cpu.tick()
        }
        
//        print(ts,ts%8,inScreen,data.count)
        ts&+=1

        for _ in 0..<2{
            let (x,y) = getXY(col,row)
            bitmap[x,y] = data.removeFirst()
                        
            col += 1
            if col == 448 {
                col = 0
                row += 1
                if row == 312 {
                    row = 0
                    ts = 0
                    FrameDone()
                }
            }
            
            if  (row == (312-64)) && (col<64) {
                cpu.doInterrupt = true
            } else {
                cpu.doInterrupt = false
            }
        }
    }
    
    func getXY(_ col:Int, _ row:Int) -> (Int,Int) {
        var x = col+24
        var y = row+48
        if x >= width {
            x -= width
            y += 1
        }
        if y >= height {
            y -= height
        }
        return (x,y)
    }
        
    func FrameDone() {
        frame = (frame + 1) & 0x1f
        listener?.frameDone(bitmap: bitmap)
//        monitor.image = Image(bitmap.cgImage(), scale: 1, label: Text(verbatim: ""))
        bitmap = Bitmap(width: 352, height: 296, color: BitmapColor(r: 0xff, g: 0, b: 0, a: 0xff))
    }
    
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
