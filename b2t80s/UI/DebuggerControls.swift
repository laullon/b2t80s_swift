//
//  debuggerControls.swift
//  b2t80s
//
//  Created by German Laullon on 27/9/23.
//

import SwiftUI

struct DebuggerControls: View {
    @Binding var waitOnNext: Bool
    @Binding var waitOnNextInterruption: Bool
    @Binding var wait: Bool

    var body: some View {
        HStack{
            Button("Stop") {
                waitOnNext = true
            }.disabled(wait)
            Button("Step") {
                wait = false
                waitOnNext = true
                waitOnNextInterruption = false
            }.disabled(!wait)
            Button("Step Interruption") {
                wait = false
                waitOnNext = false
                waitOnNextInterruption = true
            }.disabled(!wait)
            Button("continue") {
                wait = false
                waitOnNext = false
                waitOnNextInterruption = false
            }.disabled(!wait)
        }
    }
}

#Preview {
    @State var waitOnNextInterruption: Bool = false
    @State var waitOnNext: Bool = false
    @State var wait: Bool = false
    return DebuggerControls(waitOnNext: $waitOnNext,waitOnNextInterruption: $waitOnNextInterruption, wait: $wait)
}
