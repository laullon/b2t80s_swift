//
//  cassete.swift
//  b2t80s
//
//  Created by German Laullon on 2/9/23.
//

import Foundation

class Cassete {
    var tap: Tap
    var cpu: z80
    var nextBlogIdx = 0
    
    init(tap: Tap, cpu: z80) {
        self.tap = tap
        self.cpu = cpu
    }
    
    func nextDataBlock() -> Data {
        if nextBlogIdx == tap.blocks.count {
            return Data()
        }
        
        let b = tap.blocks[nextBlogIdx]
        nextBlogIdx += 1
        return tap.data.subdata(in: b.range)
    }
    
    func loadDataBlock() {
        let data = nextDataBlock()
        if data.count == 0 {
            return //emulator.CONTINUE
        }
        
        let requestedLength = self.cpu.regs.DE
        let startAddress = self.cpu.regs.IX
        print("Loading block to \(startAddress.toHex()) (\(data.count)")
        
//        prvint(data[0..<16].reduce("") {"\($0) \($1.toHex())"})
        
        cpu.wait = true
        let a = data[0]
        print(self.cpu.regs.Aalt ,"==", a,":",self.cpu.regs.Aalt == a)
        print("requestedLength:",requestedLength)
        if self.cpu.regs.Aalt == a {
            if self.cpu.regs.Falt.C {
                var checksum = data[0]
                for i in 0 ..< Int(requestedLength) {
                    let loadedByte = data[i+1]
                    self.cpu.bus.writeToMemory(startAddress&+UInt16(i), loadedByte)
                    checksum = (checksum ^ loadedByte)
                }
                print(checksum ,"==", data[Int(requestedLength)+1],":",checksum == data[Int(requestedLength)+1])
                self.cpu.regs.F.C = checksum == data[Int(requestedLength)+1]
            } else {
                self.cpu.regs.F.C = true
            }
            print("done")
        } else {
            self.cpu.regs.F.C = false
            print("BAD Block")
        }
        
        self.cpu.regs.PC = 0x05e2
        self.cpu.wait = false
        print("Done\n--------")
        
        return
    }
}
