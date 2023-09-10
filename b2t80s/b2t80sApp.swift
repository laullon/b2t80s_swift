//
//  b2t80sApp.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import SwiftUI

@main
struct b2t80sApp: App {
    var machine: zx48k
    
    init() {
        print(CommandLine.arguments)
        var tap: String? = nil
        if let idx = CommandLine.arguments.lastIndex(of: "-tap"){
            tap = CommandLine.arguments[idx+1]
}
        let m = zx48k(tap: tap)
        machine = m
        if NSClassFromString("XCTestCase") == nil {
            DispatchQueue(label: "machine").async {
                m.run()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(machine:machine)
        }
    }
}
