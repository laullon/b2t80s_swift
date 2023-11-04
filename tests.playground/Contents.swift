let asm = """
    ld hl, 0x0000
    ld a, (hl)
    inc a
    daa
    ld (hl), a
    jr s
"""

//text.split(whereSeparator: \.isNewline).forEach { str in
//    str.split(whereSeparator: \.isWhitespace)
//}

"(HL),".trimmingCharacters(in: .init(charactersIn: ","))

class Token {
    var name: String
    init(name: String) {
        self.name = name
    }
}

class Code: Token {}
class Register: Token {}
class Argument: Token {}

extension Token: CustomStringConvertible {
    var description: String {
        return "\(type(of: self)):\(name)"
    }
}

let validTokens: [String] = [
    "A","B","C","D","E","F","H","L",
    "AF","BC","DE","HL","IX","IY","SP","PC",
    "AF'",
    "NZ","Z","NC","C","PO","PE","P","M"]

var validOps: Set<Op> = []

class Op: Hashable {
    let code: Code
    let length: Int
    var args:[Token]=[]
    
    init(code: Code, length: Int) {
        self.code = code
        self.length = length
    }
    
    static func == (lhs: Op, rhs: Op) -> Bool {
        var l_hasher = Hasher()
        var r_hasher = Hasher()
        lhs.hash(into: &l_hasher)
        rhs.hash(into: &r_hasher)

        return l_hasher.finalize() == r_hasher.finalize()
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(code.description)
        args.forEach { arg in
            hasher.combine(arg.description)
        }
    }
}

extension Op: CustomStringConvertible {
    var description: String {
        return "\(code) \(args)"
    }
}

// ---------------------------

var cpu = z80(DummyBus())
cpu.lookup.forEach { opCode in
    let line = dis(opCode,FetchedData(op: opCode))
    let op = compile(line)
    let byte = opCode.code
    validOps.insert(op)
    print(byte.toHex(), op)
}

print("-------")

asm.split(whereSeparator: \.isNewline)
    .map {String($0)}
    .forEach { line in
        print(line)
        let op = compile(line)
        print(op,validOps.contains(op))

    }
//---------------------------

func compile(_ line: String) -> Op {
    let info = line.split(whereSeparator: \.isWhitespace)
        .map {
            String($0.uppercased().trimmingCharacters(in: .init(charactersIn: ",")))
        }
    
    print(info)
    let code = String(info[0])
    
    let op = Op(code: Code(name: code), length: info.count)
    if info.count>1 {
        info[1...].map({ str in
            String(str)
        }).forEach { arg in
            if validTokens.contains(arg) {
                op.args.append(Register(name: arg))
            } else if arg.hasPrefix("(") && arg.hasSuffix(")") && validTokens.contains(arg.trimmingCharacters(in: .punctuationCharacters)) {
                op.args.append(Register(name: arg))
            } else if arg == UInt8(0).toHex().uppercased() {
                op.args.append(Argument(name: "n"))
            } else if arg == UInt16(0).toHex().uppercased() {
                op.args.append(Argument(name: "nn"))
            } else if arg.hasPrefix("(") && arg.hasSuffix(")") && arg.trimmingCharacters(in: .punctuationCharacters) == UInt8(0).toHex().uppercased() {
                op.args.append(Argument(name: "(n)"))
            } else if arg.hasPrefix("(") && arg.hasSuffix(")") && arg.trimmingCharacters(in: .punctuationCharacters) == UInt16(0).toHex().uppercased() {
                op.args.append(Argument(name: "(nn)"))
            } else {
                fatalError("[\(arg)]")
            }
        }
    }
    return op
}

class DummyBus:Bus {
    var addr :UInt16 = 0
    var data :UInt8 = 0
    func writeToMemory(_ addr: UInt16, _ data: UInt8) { fatalError() }
    func readVideoMemory(_ addr: UInt16) -> UInt8 { fatalError() }
    func readMemory() {    }
    func writeMemory() {}
    func release() {}
    func registerPort(mask: PortMask, manager: PortManager) {}
    func readPort() {}
    func writePort() {}
    func getBlock(addr: UInt16, length: UInt16) -> [UInt8] { fatalError() }
}
