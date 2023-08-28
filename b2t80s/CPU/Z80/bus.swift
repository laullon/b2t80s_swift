//
//  bus.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

protocol Bus {
    var addr :UInt16 {get set}
    var data :UInt8 {get set}
    
    func Release()
    
    mutating func ReadMemory()
    mutating func WriteMemory()
    
    func RegisterPort(mask: PortMask, manager: PortManager)
    func ReadPort()
    func WritePort()
    
    func GetBlock(addr: uint16, length: uint16) -> [UInt8]
}

struct PortMask  {
    let mask  :UInt16
    let value :UInt16
}

protocol PortManager {
    func ReadPort(_: UInt16) -> (UInt8, Bool)
    func WritePort(_: UInt16, data: UInt8)
}
