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
    
    func release()
    
    func readMemory()
    func writeMemory()
    func readVideoMemory(_ addr: UInt16) -> UInt8
    func writeToMemory(_ addr: UInt16,_ data: UInt8) 
    func registerPort(mask: PortMask, manager: PortManager)
    func readPort()
    func writePort()
    
    func getBlock(addr: uint16, length: uint16) -> [UInt8]
}

struct PortMask: Hashable  {
    let mask  :UInt16
    let value :UInt16
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mask)
        hasher.combine(value)
    }
}

protocol PortManager {
    func readPort(_ port: UInt16) -> (UInt8, Bool)
    func writePort(_ port: UInt16, _ data: UInt8)
}
