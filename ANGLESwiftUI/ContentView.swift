//
//  ContentView.swift
//  ANGLESwiftUI
//
//  Created by Levin Li on 2023/6/9.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SUIRenderView()
    }
}

#if os(macOS)
struct SUIRenderView: NSViewRepresentable {
    typealias NSViewType = RenderView

    func makeNSView(context: Context) -> RenderView {
        // A zero size frame will cause window surface
        // creation failure
        return RenderView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }

    func updateNSView(_ nsView: RenderView, context: Context) {}
}
#else
struct SUIRenderView: UIViewRepresentable {
    typealias UIViewType = RenderView

    func makeUIView(context: Context) -> RenderView {
        // A zero size frame will cause window surface
        // creation failure
        return RenderView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }

    func updateUIView(_ uiView: RenderView, context: Context) {}
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
