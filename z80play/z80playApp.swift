//
//  z80playApp.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI

@main
struct z80playApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: z80playDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
