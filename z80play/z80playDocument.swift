//
//  z80playDocument.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI
import UniformTypeIdentifiers

let asm = """
; coment
loop:
    ld hl, data
    ld a, (hl)
    inc a
    daa
    ld (hl), a
    jr loop
data:
    db 0,0,0,0
"""

extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.example.plain-text")
    }
}

struct z80playDocument: FileDocument {
    var text: String
            
    init(text: String = asm) {
        self.text = text
    }
    
    static var readableContentTypes: [UTType] { [.exampleText] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

