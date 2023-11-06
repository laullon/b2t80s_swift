//
//  formatters.swift
//  b2t80s
//
//  Created by German Laullon on 7/9/23.
//

import Foundation

public extension UInt16 {
    struct FormatStyle: Foundation.ParseableFormatStyle {
        public func format(_ value: UInt16) -> String {
            return String(format: "0x%04X", value)
        }
        public var parseStrategy: UInt16.ParseStrategy {
            return UInt16.ParseStrategy()
        }
    }
    
    struct ParseStrategy: Foundation.ParseStrategy {
        public func parse(_ value: String) throws -> UInt16 {
            return 10
        }
    }
}

public extension FormatStyle where Self == UInt16.FormatStyle {
         static var hexNumber: UInt16.FormatStyle {
        UInt16.FormatStyle()
    }
}


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



