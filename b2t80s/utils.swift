//
//  utils.swift
//  b2t80s
//
//  Created by German Laullon on 18/8/23.
//

import Foundation

extension UInt16 {
    func toHex() -> String {
        return String(format: "0x%04X", self)
    }
}

extension UInt8 {
    func toHex() -> String {
        return String(format: "0x%02X", self)
    }
}
