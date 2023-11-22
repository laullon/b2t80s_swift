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
        HStack {
            Editor(text: $doc.text, machine: doc.machine.status)
                .inspector(isPresented: .constant(true), content: {
                    DebuggerPanel(machine: doc.machine)
                        .inspectorColumnWidth(455)
                })
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

struct myLayout: Layout {
    struct Cache {
        var sizes: [CGSize] = []
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return Cache(sizes: sizes)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        return proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let rigth_size = CGSize(width: cache.sizes.last!.width, height: bounds.height)
        let rigth = CGPoint(x: bounds.width - cache.sizes.last!.width, y: 0)
        subviews.last?.place(at: rigth, proposal: ProposedViewSize(width: rigth_size.width, height: .infinity))
        
        let left_size = CGSize(width: cache.sizes.last!.width, height: bounds.height)
        let left = CGPointZero
        subviews.first?.place(at: left, proposal: ProposedViewSize(left_size))
    }
    
}

#Preview {
    let doc = z80playDocument()
    return ContentView(doc: .constant(doc))
        .frame(width: 800,height: 600)
}
