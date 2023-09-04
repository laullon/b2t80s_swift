import Cocoa

var greeting = Data([0,1,2,3,4,5,6,7,8,9,10])

greeting[1]

let startIndex = greeting.startIndex
let endIndex = greeting.endIndex

var range3 = startIndex.advanced(by: 2) ..< endIndex

pp(greeting.subdata(in: range3))

func pp (_ data: Data) {
    data[0]
}


//var m = zx48k()
//
//var ops = m.cpu.lookup
//ops.append(contentsOf: m.cpu.lookupCB)
//ops.append(contentsOf: m.cpu.lookupDD)
//ops.append(contentsOf: m.cpu.lookupED)
//ops.append(contentsOf: m.cpu.lookupFD)
//ops.append(contentsOf: m.cpu.lookupDDCB)
//ops.append(contentsOf: m.cpu.lookupFDCB)
//
//var opsNames = Set(ops.map { $0.name.replacing(",", with: " ") })
//
//
//var tokens:[String] = Array()
//
//opsNames.forEach { name in
//    tokens.append(contentsOf: name.split(separator: " ").map {String($0)} )
//}
//
//print(Set(tokens).filter { $0 == $0.lowercased()}.sorted().joined(separator: "\n"))
//
