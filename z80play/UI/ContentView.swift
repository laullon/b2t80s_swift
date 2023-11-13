//
//  ContentView.swift
//  z80play
//
//  Created by German Laullon on 4/11/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var doc: z80playDocument
    
    var body: some View {
        HStack(alignment: .top) {
            BinCodeViewer(status: doc.machine.status)
            Divider()
            TextEditor(text: $doc.text)
                .lineSpacing(0)
            Divider()
            DebuggerPanel(machine: doc.machine)
        }
        .toolbar {
            ToolBar(machine: doc.machine)
        }
        
        .font(Font.system(size: 14,design: .monospaced))
        .onAppear() {
            Task { await doc.machine.complie(code: doc.text) }
        }
        .onChange(of: doc.text, {
            Task { await doc.machine.complie(code: doc.text) }
        })
        .background(.white)
    }
}

#Preview {
    let doc = z80playDocument()
    return ContentView(doc: .constant(doc))
        .frame(width: 800,height: 600)
}
