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
        let m = zx48k()
        machine = m
        if NSClassFromString("XCTestCase") == nil {
            DispatchQueue(label: "machine").async {
                m.run()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(monitor: machine.monitor, machine:machine)
        }
    }
}
