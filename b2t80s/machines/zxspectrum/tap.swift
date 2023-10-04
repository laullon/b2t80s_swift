//
//  tap.swift
//  b2t80s
//
//  Created by German Laullon on 2/9/23.
//

import Foundation

struct loopBlock {
    var id:     UInt8
    var count:  Int
    var blocks: [Any]
}

struct loopEndBlock {
    var id: UInt8
}

struct DataBlock {
    var id:   UInt8 = 0
    var flag: UInt8 = 0
    var range: Range<Data.Index>
    var pilot:UInt = 0
    var pilotLen:UInt = 0
    var sync1:UInt = 0
    var sync2:UInt = 0
    var zero:UInt = 0
    var one:UInt = 0
    var pause: UInt = 0
    var lastBiteLen: Int8 = 0
}

struct pulseSeqBlock  {
    var id     :UInt8
    var pulses :[UInt] = []
}

class Tap {
    var blocks :[DataBlock] = []
    var actualBlock: Int = 0
    var data: Data
    var name: String
    
    init(_ url: URL, symbols: inout [Symbol]) throws {
//        let filePath = Bundle.main.url(forResource: "pacman", withExtension: "tap")!
        name = url.lastPathComponent
        data = try Data(contentsOf: url)
        
        let header = String(decoding: data.subdata(in: 0..<7),as: UTF8.self)
        if header == "ZXTape!" {
            fatalError()
            //            var loop *loopBlock
            //            var inLoop bool
            
//            let file = data.subdata(in: data.startIndex.advanced(by: 7) ..< data.endIndex)
//            while file.count > 0 {
//                block, l := readTzxBlock(file)
//                file = file[l+1:]
//
//                if b, ok := block.(*loopBlock); ok {
//                    inLoop = true
//                    loop = b
//                } else if _, ok = block.(*loopEndBlock); ok {
//                    for i := 0; i < loop.count; i++ {
//                        tap.blocks = append(tap.blocks, loop.blocks...)
//                    }
//                    inLoop = false
//                } else if block != nil {
//                    if inLoop {
//                        loop.blocks = append(loop.blocks, block)
//                    } else {
//                        tap.blocks = append(tap.blocks, block)
//                    }
//                }
//            }
        } else {
            var start = 0
            repeat {
                let block = readDefaultBlock(data,start: start)
                blocks.append(block)
                start = block.range.endIndex
            } while data.count > start
        }
        
        do {
            let symUurl = url.deletingPathExtension().appendingPathExtension("symbol")
            let data = try String(contentsOf: symUurl)
            let lines = data.components(separatedBy: .newlines)
            for line in lines {
                let comps = line.replacingOccurrences(of: "\t", with: " ").split(separator: " ")
                if comps.count > 0 {
                    let sym = String(comps[0])
                    if !sym.hasPrefix("0") {
                        let addr = UInt16(comps[2].trimmingCharacters(in: CharacterSet(charactersIn: "H")), radix: 16)!
                        symbols.append(Symbol(addr: addr, name: sym))
                    }
                }
            }
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    private func readDefaultBlock(_ file: Data, start: Data.Index) -> DataBlock {
        let length = Int(file[start+0]) | (Int(file[start+1]) << 8)
        let flag = file[start+0x02]
        var pilotLen = UInt(8063)
        if flag > 128 {
            pilotLen = 3223
        }
//        let str = String(decoding: data[start+3..<start+13], as: UTF8.self)
//        print("name:", str)

        var block = DataBlock(range: start+2..<(start+length+2))
        block.flag =        flag
        block.pilot =       2168
        block.pilotLen =    pilotLen
        block.sync1 =       667
        block.sync2 =       735
        block.zero =        855
        block.one =         1710
        block.pause =       3000
        block.lastBiteLen = 8
        return block
    }
    
//    func readTzxBlock(_ data: Data) -> (Any, Int) {
//        var id = data[0]
//        var file = data.subdata(in: 1 ..< data.endIndex)
//
//        switch id {
//        case 0x10:
//            let len = Int(file[0x02]) | (Int(file[0x03])<<8)
//            let flag = file[0x04]
//            var pilotLen = UInt(8063)
//            if flag > 128 {
//                pilotLen = 3223
//            }
//            var block = DataBlock(
//                id:          id,
//                flag:        flag,
//                data:        file.subdata(in: 4..<(len+4)),
//                pilot:       2168,
//                pilotLen:    pilotLen,
//                sync1:       667,
//                sync2:       735,
//                zero:        855,
//                one:         1710,
//                pause:       (UInt(file[0x00]) | UInt(file[0x01])<<8),
//                lastBiteLen: 8
//            )
//            return (block, len + 0x04)
//
//        case 0x11:
//            let len = Int(file[0x0f]) | (Int(file[0x10])<<8) | (Int(file[0x11])<<16)
//            let block = DataBlock(
//                id:          id,
//                flag:        file[0x12],
//                data:        file.subdata(in: 0x12..<(len+0x12)),
//                pilot:       UInt(file[0x00]) | (UInt(file[0x01])<<8),
//                pilotLen:    UInt(file[0x0A]) | (UInt(file[0x0B])<<8),
//                sync1:       UInt(file[0x02]) | (UInt(file[0x03])<<8),
//                sync2:       UInt(file[0x04]) | (UInt(file[0x05])<<8),
//                zero:        UInt(file[0x06]) | (UInt(file[0x07])<<8),
//                one:         UInt(file[0x08]) | (UInt(file[0x09])<<8),
//                pause:       UInt(file[0x0D]) | (UInt(file[0x0E])<<8),
//                lastBiteLen: Int8(file[0x0C])
//            )
//            return (block, len + 0x12)
//
//        case 0x12: // Pure Tone
//            let block = DataBlock(
//                id:       id,
//                pilot:    (UInt(file[0x00]) | UInt(file[0x01])<<8),
//                pilotLen: (UInt(file[0x02]) | UInt(file[0x03])<<8)
//            )
//            return (block, 4)
//
//        case 0x13: // Pulse sequence
//            let len = Int(file[0])
//            var block = pulseSeqBlock(id: id)
//            for i in stride(from: 0, to: len*2, by: 2) {
//                block.pulses.append(UInt(file[0x01+i])|UInt(file[0x02+i])<<8)
//            }
//            return (block, Int(len*2 + 1))
//
//        case 0x14:
//            let len = Int(file[0x07]) | (Int(file[0x08])<<8) | (Int(file[0x09])<<16)
//            let block = DataBlock(
//                id:          id,
//                data:        file.subdata(in: 0x0a..<len+0x0a),
//                zero:        UInt(file[0x00]) | (UInt(file[0x01])<<8),
//                one:         UInt(file[0x02]) | (UInt(file[0x03])<<8),
//                pause:       UInt(file[0x05]) | (UInt(file[0x06])<<8),
//                lastBiteLen: Int8(file[0x04])
//            )
//            return (block, len + 0x0a)
//
//        case 0x20: // Pause (silence) or 'Stop the Tape' command
//            let block = DataBlock(
//            id:    id,
//            pause: UInt(file[0x00]) | (UInt(file[0x01])<<8)
//            )
//            return (block, 2)
            
//        case 0x21: // Group start
//            len := uint32(file[0])
//            return nil, 1 + len
//
//        case 0x22: // Group end
//            return nil, 0
//
//        case 0x24: // Loop start
//            block := &loopBlock{
//            id:    id,
//            count: (int(file[0x00]) | int(file[0x01])<<8),
//            }
//            // println("Loop:", loop)
//            return block, 2
//
//        case 0x25: // TODO: Text description
//            return &loopEndBlock{}, 0
//
//        case 0x30: // TODO: Text description
//            len := uint32(file[0])
//            return nil, 1 + len
//
//        case 0x32: // TODO: Archive info
//            len := uint32(file[0x00]) | uint32(file[0x01])<<8
//            return nil, 2 + len
//
//        case 0x35: // TODO: Custom info block
//            len := uint32(file[0x10]) | uint32(file[0x11])<<8 | uint32(file[0x12])<<16 | uint32(file[0x13])<<24
//            return nil, 0x14 + len
//
//        default:
//            fatalError("id: \(id.toHex())")
//        }
//    }
    
//    func (b *pulseSeqBlock) String() string {
//        return fmt.Sprintf("(0x%02X) Pulse Seq. Block - pulses:%d", b.id, len(b.pulses))
//    }
//
//    func (b *dataBlock) String() string {
//        name := b.name()
//        return fmt.Sprintf("(0x%02X)(0x%02X) name: '%-9s' - datalen:%d - pilot:%d(%d) - sync:%d(%d) - zero:%d one:%d - pause:%d", b.id, b.flag, name, len(b.data), b.pilot, b.pilotLen, b.sync1, b.sync2, b.zero, b.one, b.pause)
//    }
//
//    func (b *dataBlock) name() string {
//        if (b.flag == 0 || b.flag == 0x2c) && len(b.data) > 0 {
//            return string(b.data[1:11])
//        }
//        return "Data"
//    }
}
