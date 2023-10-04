//
//  formatters.swift
//  b2t80s
//
//  Created by German Laullon on 7/9/23.
//

import Foundation

class HexFormatter: Formatter {
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for str: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if let value = UInt16(str.dropFirst(2), radix: 16) {
            obj?.pointee = value as AnyObject
            return true
        }
        return false
    }
    
    override func string(for obj: Any?) -> String? {
        if let v = (obj as? UInt16){
            return v.toHex();
        }else{
            return ""
        }
    }
}

extension UInt16 {
    func toHex() -> String {
        return String(format: "0x%04X", self)
    }
}

extension UInt8 {
    func toHex() -> String {
        return String(format: "0x%02X", self)
    }
    func toHexShort() -> String {
        return String(format: "%02X", self)
    }
}



