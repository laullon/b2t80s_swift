//
//  Collapsible.swift
//  b2t80s
//
//  https://gist.github.com/sanzaru/83a6dc8d8c93f267d4a1a258a7a92329
//

import SwiftUI

struct Collapsible<Content: View>: View {
    var label: () -> Text
    var content: () -> Content

    @State private var collapsed: Bool = false
    @State private var show: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Button() {
                    if collapsed {
                        show = true
                        withAnimation {
                          collapsed = false
                        }
                    } else {
                        withAnimation {
                          collapsed = true
                        } completion: {
                            show = false
                        }

                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(collapsed ? .degrees(-90) : .zero )
                    self.label()
                }.focusable(false)
            }
            .buttonStyle(.plain)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

            if (show) {
                self.content()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
                    .clipped()
                    .zIndex(0)
                    .padding(.leading,10)
            }
            Divider()
        }
    }
}
