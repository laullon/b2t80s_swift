import Cocoa

var greeting = "Hello, playground"

var m = zx48k()

var ops = m.cpu.lookup
ops.append(contentsOf: m.cpu.lookupCB)
ops.append(contentsOf: m.cpu.lookupDD)
ops.append(contentsOf: m.cpu.lookupED)
ops.append(contentsOf: m.cpu.lookupFD)
ops.append(contentsOf: m.cpu.lookupDDCB)
ops.append(contentsOf: m.cpu.lookupFDCB)

var opsNames = Set(ops.map { $0.name.replacing(",", with: " ") })


var tokens:[String] = Array()

opsNames.forEach { name in
    tokens.append(contentsOf: name.split(separator: " ").map {String($0)} )
}

print(Set(tokens).filter { $0 == $0.lowercased()}.sorted().joined(separator: "\n"))

