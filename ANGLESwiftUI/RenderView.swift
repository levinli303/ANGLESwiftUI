//
//  RenderView.swift
//  ANGLESwiftUI
//
//  Created by Levin Li on 2023/6/9.
//

import libEGL
import libGLESv2

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)
typealias PlatformView = NSView
typealias PlatformDisplayLink = CVDisplayLink
#else
typealias PlatformView = UIView
typealias PlatformDisplayLink = CADisplayLink
#endif

class RenderView: PlatformView {
    private var display: EGLDisplay!
    private var surface: EGLSurface!
    private var context: EGLContext!
    private var program: GLuint!

    private var displayLink: PlatformDisplayLink?

#if os(macOS)
    override func makeBackingLayer() -> CALayer {
        return CAMetalLayer()
    }
#else
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
#endif

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

#if !os(macOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard previousTraitCollection?.displayScale != traitCollection.displayScale else {
            return
        }

        layer.contentsScale = traitCollection.displayScale
    }
#endif

    private func setUp() {
#if os(macOS)
        wantsLayer = true
#else
        layer.contentsScale = traitCollection.displayScale
#endif
        guard let display = eglGetPlatformDisplay(EGLenum(EGL_PLATFORM_ANGLE_ANGLE), nil, nil) else {
            print("eglGetPlatformDisplay() returned error \(eglGetError())")
            return
        }

        guard eglInitialize(display, nil, nil) != 0 else {
            print("eglInitialize() returned error \(eglGetError())")
            return
        }

        var configAttribs: [EGLint] = [
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_DEPTH_SIZE, 24,
            EGL_NONE,
        ]

        let configs = UnsafeMutablePointer<EGLConfig?>.allocate(capacity: 1)
        defer { configs.deallocate() }

        var numConfigs: EGLint = 0
        guard eglChooseConfig(display, &configAttribs, configs, 1, &numConfigs) != 0 else {
            print("eglChooseConfig() returned error \(eglGetError())")
            return
        }

        guard let config = configs.pointee else {
            print("Empty config returned in eglChooseConfig()")
            return
        }

        var contextAttribs: [EGLint] = [
            EGL_CONTEXT_MAJOR_VERSION, 2,
            EGL_CONTEXT_MINOR_VERSION, 0,
            EGL_NONE,
        ]

        guard let context = eglCreateContext(display, config, nil, &contextAttribs) else {
            print("eglCreateContext() returned error \(eglGetError())")
            return
        }

        guard let surface = eglCreateWindowSurface(display, config, unsafeBitCast(layer, to: EGLNativeWindowType.self), nil) else {
            print("eglCreateWindowSurface() returned error \(eglGetError())")
            return
        }

        self.surface = surface
        self.display = display
        self.context = context

        buildShaders()

        #if os(macOS)
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { _, _, _, _, _, pointer in
            let view = unsafeBitCast(pointer, to: RenderView.self)
            DispatchQueue.main.async {
                view.displayLinkCallback()
            }
            return kCVReturnSuccess
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
        #else
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink.add(to: .current, forMode: .common)
        self.displayLink = displayLink
        #endif
    }

    private func buildShaders() {
        eglMakeCurrent(display, surface, surface, context)

        let vShaderSource =
"""
attribute vec4 vPosition;
void main()
{
    gl_Position = vPosition;
}
"""
        let fShaderSource =
"""
precision mediump float;
void main()
{
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
"""
        // Assuming we are always on the happy path...
        let vShader = glCreateShader(GLenum(GL_VERTEX_SHADER))
        vShaderSource.withCString { pointer in
            var optionalPointer: UnsafePointer<Int8>? = pointer
            glShaderSource(vShader, 1, &optionalPointer, nil)
        }
        glCompileShader(vShader)

        let fShader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
        fShaderSource.withCString { pointer in
            var optionalPointer: UnsafePointer<Int8>? = pointer
            glShaderSource(fShader, 1, &optionalPointer, nil)
        }
        glCompileShader(fShader)

        let program = glCreateProgram()
        glAttachShader(program, vShader)
        glAttachShader(program, fShader)
        glLinkProgram(program)
        self.program = program
    }

    @objc private func displayLinkCallback() {
        eglMakeCurrent(display, surface, surface, context)

        let drawableSize = (self.layer as! CAMetalLayer).drawableSize
        glViewport(0, 0, GLsizei(drawableSize.width), GLsizei(drawableSize.height))

        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        glUseProgram(program)

        let vertices: [Float] = [ 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 ]
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices)
        glEnableVertexAttribArray(0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)

        eglSwapBuffers(display, surface)
    }
}
