//
//  bitmap.swift
//  b2t80s
//
//  Created by German Laullon on 29/8/23.
//

import Foundation
import SwiftUI

struct BitmapColor {
    var r, g, b, a: UInt8
}

struct Bitmap {
    var width: Int
    var pixels: [BitmapColor]
    
    var height: Int {
        pixels.count / width
    }
    
    init(width: Int, height: Int, color: BitmapColor) {
        self.width = width
        pixels = Array(repeating: color, count: width * height)
    }
    
    subscript(x: Int, y: Int) -> BitmapColor {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }
    
    func cgImage() -> CGImage {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<BitmapColor>.stride
        let bytesPerRow = width * bytesPerPixel
        
        guard let providerRef = CGDataProvider(data: Data(bytes: pixels, count: height * bytesPerRow) as CFData) else {
            fatalError()
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: bytesPerPixel * 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            fatalError()
        }
        return cgImage
    }
}
