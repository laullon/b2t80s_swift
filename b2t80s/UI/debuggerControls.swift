//
//  debuggerControls.swift
//  b2t80s
//
//  Created by German Laullon on 27/9/23.
//

import SwiftUI

struct debuggerControls: View {
    @Binding var waitOnNext: Bool
    @Binding var wait: Bool

    var body: some View {
        HStack{
            Button("Stop") {
                waitOnNext = true
            }.disabled(wait || waitOnNext)
            Button("Step") {
                wait = false
                waitOnNext = true
            }.disabled(!wait)
            Button("continue") {
                waitOnNext = false
                wait = false
            }.disabled(!wait)
        }
    }
}

#Preview {
    @State var waitOnNext: Bool = false
    @State var wait: Bool = false
    return debuggerControls(waitOnNext: $waitOnNext, wait: $wait)
}
