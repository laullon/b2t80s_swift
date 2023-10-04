//
//  controlsOverlay.swift
//  b2t80s
//
//  Created by German Laullon on 3/10/23.
//

import SwiftUI

struct ControlsOverlay: View {
    @Binding var volumen: Double
    @Binding var showDebuger: Bool
    var reset: () -> Void
    var openFile: () -> Void

    @State private var collapsed: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Button() {
                withAnimation {
                    showDebuger.toggle()
                }
            } label: {
                Image(systemName: showDebuger ? "ladybug.fill" : "ladybug") .imageScale(.large)
            }
            
            Button() {
                openFile()
            } label: {
                Image(systemName: "recordingtape") .imageScale(.large)
            }
            
            
            Button() {
                reset()
            } label: {
                Image(systemName: "repeat").imageScale(.large)
            }
            
            HoverPanel {
                AnyView(
                    Image(systemName: "speaker.wave.3", variableValue: volumen)
                        .symbolRenderingMode(.multicolor)
                        .imageScale(.large)
                        .frame(width: 35,height: 25)
                )
            } content: {
                AnyView(
                    Slider(value: $volumen, in: 0...1)
                        .controlSize(.mini)
                        .frame(maxWidth: 200)
                )
            }
        }
        .buttonStyle(CustomButtonStyle())
        .padding(.all,5)
    }
}

#Preview {
    @State var vol = Double(0)
    @State var sd = true
    
    return ControlsOverlay(
        volumen: $vol,
        showDebuger: $sd,
        reset: {print("- reset -")},
        openFile: {print("- openFile -")}
    ).frame(width: 250)
}

struct HoverPanel<Content: View>: View {
    var icon: () -> Content
    var content: () -> Content
    
    @State private var collapsed: Bool = true
    
    init(@ViewBuilder icon: @escaping () -> Content, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        HStack{
            icon()
                .frame(width: 35,height: 25)
            if !collapsed {
                content()
            }
        }
        .padding(.all,5)
        .background(.white)
        .cornerRadius(20)
        .onContinuousHover { phase in
            withAnimation {
                switch phase {
                case .active:
                    collapsed = false
                case .ended:
                    collapsed = true
                }
            }
        }
    }
}

struct CustomButtonStyle: ButtonStyle {
    @State var hover = false
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .frame(width: 35,height: 25)
                .opacity(hover ? 1 : 0.5)
        }
        .buttonStyle(.borderless)
        .padding(.all,5)
        .background(.white)
        .cornerRadius(20)
        .focusable(false)
        .onContinuousHover { phase in
            withAnimation {
                switch phase {
                case .active:
                    hover = true
                case .ended:
                    hover = false
                }
            }
        }
    }
}

