//
//  z80Tests.swift
//  b2t80sTests
//
//  Created by German Laullon on 18/8/23.
//

import XCTest
@testable import b2t80s

final class z80Tests: XCTestCase {
    var tests :[cpuTest] = []
    var results :[String:cpuTestResult] = [:]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    
    func testRegPair() {
        var mem:[UInt8] = []
        let cpu = z80(DummyBus(mem: &mem))
        cpu.regs.B = 0x0A
        cpu.regs.C = 0x0B
        XCTAssert(uint16(0x0A0B) == cpu.regs.BC, "BC is \(cpu.regs.BC)")
        
        cpu.regs.DE = 0xddee
        XCTAssertEqual(uint16(0xddee), cpu.regs.DE, "DE is \(cpu.regs.DE.toHex())")

        let reg = cpu.regs.rRegsPtrs[1]
        reg.pointee = 0xFFFF
        XCTAssertEqual(uint16(0xffff), cpu.regs.DE, "DE is \(cpu.regs.DE.toHex())")
        
        cpu.regs.SP = 0xddee
        XCTAssertEqual(uint16(0xddee), cpu.regs.SP, "DE is \(cpu.regs.SP.toHex())")

    }
    
    func testOPCodes() throws {
        try readTests()
        try readTestsResults()
        
        for test in tests {
            var mem:[UInt8] = Array(repeating: 0, count: 0xffff+1)
            let cpu = z80(DummyBus(mem: &mem))
            // cpu.SetDebuger(&dumpDebbuger{cpu: cpu.(*z80), log: false})
            
            if let result = results[test.name] {
                
                //                logger.Clear()
                // TODO make this test work
                if test.name.hasPrefix("dd00") ||
                    test.name.hasPrefix("ddfd00") { //???
                    continue
                }
                
                setRegistersStr(cpu, test.registers, test.otherRegs)
                
                for mem in test.memory {
                    for (i, b) in mem.bytes.enumerated() {
                        cpu.bus.addr = mem.start + UInt16(i)
                        cpu.bus.data = b
                        cpu.bus.WriteMemory()
                    }
                }
                
//                print("\n")
//                print("\n-------------------------")
//                print("ready to test:", test.name)
//                print("-------------------------\n")
//                print(hex.Dump(bus.mem[0:16]))
//                print("regs:", test.registers)
//                print("start test?", test.name, "endpc:",result.endPC)
//                // fmt.Printf("start test '%v' (endPC:%v)\n", test.name, result.endPC)
                
                for _ in  0..<result.otherRegs.TS {
                    cpu.tick()
                }
                
                XCTAssertEqual(result.endPC, cpu.regs.PC, "test \(test.name) cpu.PC fail")
                XCTAssertEqual(result.otherRegs.I, cpu.regs.I, "test \(test.name) cpu.I fail")
                XCTAssertEqual(result.otherRegs.R, cpu.regs.R, "test \(test.name) cpu.R fail")
                XCTAssertEqual(result.otherRegs.IFF1, cpu.regs.IFF1, "test \(test.name) cpu.IFF1 fail")
                XCTAssertEqual(result.otherRegs.IFF2, cpu.regs.IFF2, "test \(test.name) cpu.IFF2 fail")
                XCTAssertEqual(result.otherRegs.IM, cpu.regs.InterruptsMode, "test \(test.name) cpu.IM fail")


//                log.Printf("%s", hex.Dump(bus.mem[0:16]))
//                log.Printf("done test '%v'", test.name)
                
                for ms in result.memory {
                    let cpuMen = cpu.bus.GetBlock(addr: ms.start, length: uint16(ms.bytes.count))
                    if (Set(ms.bytes).subtracting(Set(cpuMen))).count != 0 {
                        print(cpuMen.reduce("res:") { String(format: "\($0) %02X", $1) })
                        print(ms.bytes.reduce("exp:") { String(format: "\($0) %02X", $1) })
                        XCTFail("test \(test.name) Memory fail")
                    }

//                    for (idx, b) in ms.bytes.enumerated() {
//                        if b != cpu.bus.mem[ms.start+uint16(idx)] {
//                            XCTFail(String(format:"error on byte %d", idx))
//                                hex.Dump(ms.bytes),
//                                hex.Dump(mem[ms.start : ms.start+uint16(len(ms.bytes))])
//                        }
//                    }
//
//
//                    err, expt, org := ms.check(bus.mem)
//                    t := assert.Nil(t, err, "test '%s' memory fail", test.name)
//                    if !t {
//                        log.Printf("0x%04X  mem: %s", ms.start, org)
//                        log.Printf("       expt: %s", expt)
//                        logger.Dump()
//                        return
//                    }
                }
//
                let registers = String(format:
                    "%02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %02x%02x %04x %04x",
                                       cpu.regs.A, cpu.regs.F.GetByte()&0b11010111, cpu.regs.B, cpu.regs.C, cpu.regs.D, cpu.regs.E, cpu.regs.H, cpu.regs.L,
                                       cpu.regs.Aalt, cpu.regs.Falt.GetByte()&0b11010111, cpu.regs.Balt, cpu.regs.Calt, cpu.regs.Dalt, cpu.regs.Ealt, cpu.regs.Halt, cpu.regs.Lalt,
                                       cpu.regs.IXH, cpu.regs.IXL, cpu.regs.IYH, cpu.regs.IYL,
                                       cpu.regs.SP, cpu.regs.PC)

                cpu.tick()

//                print(result.registers)
//                print(registers)
                XCTAssertEqual(result.registers, registers, "test '\(test.name)' registers fail")
//                if !t {
//                    logger.Dump()
//                    return
//                }
            } else {
                fatalError(String(format:"result for test '%s' not found", test.name))
            }
        }
    }
    
//    func check(mem []byte) (error, string, string) {
//        for idx, b := range ms.bytes {
//            if b != mem[ms.start+uint16(idx)] {
//                return fmt.Errorf("error on byte %d", idx),
//                    hex.Dump(ms.bytes),
//                    hex.Dump(mem[ms.start : ms.start+uint16(len(ms.bytes))])
//            }
//        }
//        return nil, "", ""
//    }

    func setRegistersStr(_ cpu: z80 , _ line: String, _ otherReg: auxRegs) {
        let regs = line.split(separator: " ")
        (cpu.regs.A, _) = setRRstr(String(regs[0]))
        (cpu.regs.B, cpu.regs.C) = setRRstr(String(regs[1]))
        (cpu.regs.D, cpu.regs.E) = setRRstr(String(regs[2]))
        (cpu.regs.H, cpu.regs.L) = setRRstr(String(regs[3]))
        
        (cpu.regs.Aalt, _) = setRRstr(String(regs[4]))
        (cpu.regs.Balt, cpu.regs.Calt) = setRRstr(String(regs[5]))
        (cpu.regs.Dalt, cpu.regs.Ealt) = setRRstr(String(regs[6]))
        (cpu.regs.Halt, cpu.regs.Lalt) = setRRstr(String(regs[7]))
        
        (cpu.regs.IXH, cpu.regs.IXL) = setRRstr(String(regs[8]))
        (cpu.regs.IYH, cpu.regs.IYL) = setRRstr(String(regs[9]))
        
        let (s, p) = setRRstr(String(regs[10]))
        cpu.regs.SP = uint16(s)<<8 | uint16(p)
        
        let (p2, c) = setRRstr(String(regs[11]))
        cpu.regs.PC = uint16(p2)<<8 | uint16(c)
        
        let (_, f) = setRRstr(String(regs[0]))
        cpu.regs.F.SetByte(f)
        let (_, _f) = setRRstr(String(regs[4]))
        cpu.regs.Falt.SetByte(_f)
        
        cpu.regs.I = otherReg.I
        cpu.regs.R = otherReg.R
        cpu.regs.IFF1 = otherReg.IFF1
        cpu.regs.IFF2 = otherReg.IFF2
        cpu.regs.InterruptsMode = otherReg.IM
    }
        
    func setRRstr(_ hl: String) -> (UInt8, UInt8) {
        if let decoded = hl.data {
            return (decoded[0], decoded[1])
        } else {
            fatalError(hl)
        }
    }
    
    func readTests() throws {
        let packageRootPath = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let file = URL(filePath: "tests.in", relativeTo: packageRootPath)
        let data = try Data(contentsOf: file)
        let lines = String(decoding: data, as: UTF8.self).components(separatedBy: .newlines)
        
        var line = 0
        var test = cpuTest()
        for str in lines {
            if str == "-1" {
                line = 0
                tests.append(test)
                test = cpuTest()
                continue
            }
            
            if str.count == 0 {
                continue
            }
            
            switch line {
            case 0:
                test.name = str
                
            case 1:
                test.registers = str
                
            case 2:
                let regs = str.split(separator: /\s+/)
                test.otherRegs.I = UInt8(regs[0],radix:16) ?? 0
                test.otherRegs.R = UInt8(regs[1],radix:16) ?? 0
                test.otherRegs.IFF1 = UInt8(regs[2],radix:16) ?? 0 == 1
                test.otherRegs.IFF2 = UInt8(regs[3],radix:16) ?? 0 == 1
                test.otherRegs.IM = UInt8(regs[4],radix:16) ?? 0
                test.otherRegs.HALT = UInt8(regs[5],radix:16) ?? 0 == 1
                test.otherRegs.TS = UInt(regs[6]) ?? 0
                
            default:
                test.memory.append(parseMemoryState(str))
            }
            line += 1
        }
    }
    
    func readTestsResults() throws {
        let packageRootPath = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let file = URL(filePath: "tests.out", relativeTo: packageRootPath)
        let data = try Data(contentsOf: file)
        let lines = String(decoding: data, as: UTF8.self).components(separatedBy: .newlines)

        var line = 0
        var result = cpuTestResult()
        for str in lines {
            if str.count == 0 {
                line = 0
                results[result.name] = result
                result = cpuTestResult()
                continue
            }
            
            if str.hasPrefix("  ") {
                continue
            }
            
            switch line {
            case 0:
                result.name = str
            case 1:
                let fstr = str[2..<4]
                let f = fstr.data![0] & 0b11010111
                
                let _fstr = str[22..<24]
                let _f = _fstr.data![0] & 0b11010111

                let regsStr = String(format: "\(str[0..<2])%02x\(str[4..<22])%02x\(str[24...])", f,_f)
                
                result.registers = regsStr
                let regs = str.split(separator: " ")
                let pc = regs[regs.count-1]
                
                if let pcVal = UInt16(pc, radix: 16) {
                    result.endPC = uint16(pcVal)
                } else {
                    fatalError(String(format: "str: '%i'(%s)", line, str))
                }
                
            case 2:
                let regs = str.split(separator: /\s+/)
                result.otherRegs.I = UInt8(regs[0],radix:16) ?? 0
                result.otherRegs.R = UInt8(regs[1],radix:16) ?? 0
                result.otherRegs.IFF1 = UInt8(regs[2],radix:16) ?? 0 == 1
                result.otherRegs.IFF2 = UInt8(regs[3],radix:16) ?? 0 == 1
                result.otherRegs.IM = UInt8(regs[4],radix:16) ?? 0
                result.otherRegs.HALT = UInt8(regs[5],radix:16) ?? 0 == 1
                result.otherRegs.TS = UInt(regs[6]) ?? 0
                
            default:
                result.memory.append(parseMemoryState(str))
            }
            line += 1
        }
        results[result.name] = result
    }
    
    
    struct cpuTest  {
        var name      :String = ""
        var registers :String = ""
        var otherRegs :auxRegs = auxRegs()
        var tStates   :UInt = 0
        var memory    :[memoryState] = []
    }
    
    struct cpuTestResult  {
        var name      :String = ""
        var registers :String = ""
        var otherRegs :auxRegs = auxRegs()
        var memory    :[memoryState] = []
        var endPC     :UInt16 = 0
    }
    
    struct auxRegs  {
        var I    :UInt8 = 0
        var R    :UInt8 = 0
        var IFF1 :Bool = false
        var IFF2 :Bool = false
        var IM   :UInt8 = 0
        var HALT :Bool = false
        var TS   :UInt = 0
    }
    
    struct memoryState  {
        var start :UInt16 = 0
        var bytes :[UInt8] = []
    }
    
    func parseMemoryState(_ line :String) -> memoryState {
        var str = line.replacingOccurrences(of: " ", with: "")
        str = str.replacingOccurrences(of: "-1", with: "") // halt
        var ms :memoryState
        
        if var bytes = str.data {
            ms = memoryState (start: UInt16(bytes[0])<<8 | UInt16(bytes[1]))
            bytes.removeFirst()
            bytes.removeFirst()
            for i in bytes {
                ms.bytes.append(i)
            }
        } else {
            fatalError()
        }
        return ms
    }
    
    
    
    func testZEXDoc() throws {
//        return
        //        if testing.Short() {
        //            t.Skip("skipping test in short mode.")
        //        }
        
        let packageRootPath = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let file = URL(filePath: "zexdocsmall.cim", relativeTo: packageRootPath)
        let data = try Data(contentsOf: file)
        
        var mem:[UInt8] = Array(repeating: 0, count: 0x0100)
        mem.append(contentsOf: data)
        mem.append(contentsOf:Array(repeating: 0, count: 0x10000-mem.count))
        
        var screen: [UInt8] = []
        let cpu = z80(DummyBus(mem: &mem))
        // cpu.SetDebuger(&dumpDebbuger{cpu: cpu.(*z80)})
        cpu.regs.PC = uint16(0x100)
        cpu.RegisterTrap(pc: 0x5, trap: { cpu in
            printChar(&screen, cpu)
            
            cpu.bus.addr = cpu.regs.SP
            cpu.bus.ReadMemory()
            var newPC = UInt16(cpu.bus.data)
            cpu.bus.addr = cpu.regs.SP &+ 1
            cpu.bus.ReadMemory()
            newPC |= UInt16(cpu.bus.data) << 8

            cpu.regs.SP = (cpu.regs.SP &+ 2)
            cpu.regs.PC = newPC
        })
        
        
        while true {
            cpu.tick()
            if cpu.regs.PC == 0 {
                if let string = String(bytes: screen, encoding: .ascii) {
                    XCTAssertFalse(string.contains("ERROR"))
                } else {
                    XCTFail("not a valid UTF-8 sequence")
                }
            }
        }
    }
    
}

func printChar(_ cpmScreen: inout [UInt8], _ cpu: z80) {
    switch cpu.regs.C {
    case 2:
        cpmScreen.append(cpu.regs.E)
        print(String(bytes: [cpu.regs.E], encoding: .ascii)!, terminator: "")
    case 9:
        var addr = cpu.regs.DE
        var done = false
        while !done{
            cpu.bus.addr = addr
            cpu.bus.ReadMemory()
            let ch = cpu.bus.data
            if ch == 36 { // "$"
                done = true
            } else {
                cpmScreen.append(ch)
                addr += 1
                print(String(bytes: [ch], encoding: .ascii)!, terminator: "")
            }
        }
    default:
        ()
    }
}

class DummyBus:Bus{
    var mem  :[UInt8]
    var addr :UInt16 = 0
    var data :UInt8 = 0
    
    init(mem: inout [UInt8]) {
        self.mem = mem
    }
    
    func ReadMemory() {
        data = mem[Int(addr)]
//        print("[MR] \(addr.toHex()) => \(data.toHex())")
    }
    
    func WriteMemory() {
        mem[Int(addr)] = data
//        print("[MW] \(addr.toHex()) <= \(data.toHex())")
    }

    func Release() {
    }
    

    func RegisterPort(mask: b2t80s.PortMask, manager: b2t80s.PortManager) {}
    
    func ReadPort() { self.data = UInt8(self.addr >> 8) }
    
    func WritePort() {}
    
    func GetBlock(addr: uint16, length: uint16) -> [UInt8] {
        return Array(mem[Int(addr)..<Int(addr+length)])
    }
}

extension String {
    var data: Data? {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        guard data.count > 0 else { return nil }
        return data
    }
    
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }
    
    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
}
