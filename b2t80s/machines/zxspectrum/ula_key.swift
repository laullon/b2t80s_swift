//
//  ula_key.swift
//  b2t80s
//
//  Created by German Laullon on 31/8/23.
//

import Foundation
import AppKit

struct Keycode {
    static let enter                     : UInt16 = 0x24
    static let delete                    : UInt16 = 0x33
    static let leftArrow                 : UInt16 = 0x7B
    static let rightArrow                : UInt16 = 0x7C
    static let downArrow                 : UInt16 = 0x7D
    static let upArrow                   : UInt16 = 0x7E
}

extension ULA {
    //package zx
    //
    //import (
    //    "sync"
    //    "time"
    //
    //    "github.com/veandco/go-sdl2/sdl"
    //)
    //
    func OnKey(_ e: NSEvent) {
        let keyDown :Bool = (e.type == .keyDown)
        
        if e.modifierFlags.contains(.shift) {
            setBit(0,1,keyDown)
        }
        if e.modifierFlags.contains(.control) {
            setBit(7,2,keyDown)
        }
        switch e.charactersIgnoringModifiers?.uppercased() {
            
        case "1":
            setBit(3,1,keyDown)
        case "2":
            setBit(3,2,keyDown)
        case "3":
            setBit(3,3,keyDown)
        case "4":
            setBit(3,4,keyDown)
        case "5":
            setBit(3,5,keyDown)
            
        case "0":
            setBit(4,1,keyDown)
        case "9":
            setBit(4,2,keyDown)
        case "8":
            setBit(4,3,keyDown)
        case "7":
            setBit(4,4,keyDown)
        case "6":
            setBit(4,5,keyDown)
            
        case "Q":
            setBit(2,1,keyDown)
        case "W":
            setBit(2,2,keyDown)
        case "E":
            setBit(2,3,keyDown)
        case "R":
            setBit(2,4,keyDown)
        case "T":
            setBit(2,5,keyDown)
            
        case "P":
            setBit(5,1,keyDown)
        case "O":
            setBit(5,2,keyDown)
        case "I":
            setBit(5,3,keyDown)
        case "U":
            setBit(5,4,keyDown)
        case "Y":
            setBit(5,5,keyDown)
            
        case "A":
            setBit(1,1,keyDown)
        case "S":
            setBit(1,2,keyDown)
        case "D":
            setBit(1,3,keyDown)
        case "F":
            setBit(1,4,keyDown)
        case "G":
            setBit(1,5,keyDown)
            
        case "L":
            setBit(6,2,keyDown)
        case "K":
            setBit(6,3,keyDown)
        case "J":
            setBit(6,4,keyDown)
        case "H":
            setBit(6,5,keyDown)
            
        case "Z":
            setBit(0,2,keyDown)
        case "X":
            setBit(0,3,keyDown)
        case "C":
            setBit(0,4,keyDown)
        case "V":
            setBit(0,5,keyDown)
            
        case "SPACE":
            setBit(7,1,keyDown)
        case "M":
            setBit(7,3,keyDown)
        case "N":
            setBit(7,4,keyDown)
        case "B":
            setBit(7,5,keyDown)
            
        default:
            switch e.keyCode {
            case Keycode.enter:
                setBit(6,1,keyDown)
            case Keycode.upArrow:
                setBit(0,1,keyDown)
                setBit(4,4,keyDown)
            case Keycode.downArrow:
                setBit(0,1,keyDown)
                setBit(4,5,keyDown)
            case Keycode.delete:
                setBit(0,1,keyDown)
                setBit(4,1,keyDown)
            default:
                ()
            }
        }
    }
    //
    //var onlyOnce sync.Once
    //
    //func (ula *ula) LoadCommand() {
    //    go onlyOnce.Do(func() {
    //        time.Sleep(time.Second)
    //        OnKey("J")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("J")
    //        OnKey("LCTRL")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("P")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("P")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("P")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("P")
    //        OnKey("LCTRL")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("RETURN")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("RETURN")
    //    })
    //}
    //
    //func (ula *ula) LoadCommand128() {
    //    go onlyOnce.Do(func() {
    //        time.Sleep(time.Second)
    //        OnKey("RETURN")
    //        time.Sleep(150 * time.Millisecond)
    //        OnKey("    //    })
    //}
    
    func setBit(_ row: Int,_ bit: Int, _ set: Bool) {
        let b = UInt8(1) << (bit - 1)
        var val = keyboardRow[row]
        if set {
            val &= 0xff ^ b
        } else {
            val |= b
        }
        keyboardRow[row] = val
    }
}
