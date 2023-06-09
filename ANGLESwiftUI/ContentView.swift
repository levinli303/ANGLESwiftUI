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

struct SUIRenderView: UIViewRepresentable {
    typealias UIViewType = RenderView

    func makeUIView(context: Context) -> RenderView {
        // A zero size frame will cause window surface
        // creation failure
        return RenderView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    }

    func updateUIView(_ uiView: RenderView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
