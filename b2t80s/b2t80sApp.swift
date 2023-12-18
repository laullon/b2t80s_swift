//
//  b2t80sApp.swift
//  b2t80s
//
//  Created by German Laullon on 17/8/23.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    public static let tapType = UTType(importedAs: "com.laullon.b2t80s.tap")
}

@main
struct b2t80sApp: App {
    var tap: String? = nil
    
    init() {
        if let idx = CommandLine.arguments.lastIndex(of: "-tap"){
            tap = CommandLine.arguments[idx+1]
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(tap: tap)
        }
    }
}
