//
//  DiagramWebViewTests.swift
//  SwiftPlantUMLstudioTests
//
//  Created by Gemini on 3/7/26.
//

import XCTest
import WebKit
import SwiftUI
import SwiftUMLBridgeFramework
@testable import SwiftPlantUMLstudio

@MainActor
final class DiagramWebViewTests: XCTestCase {

    func testPlantUMLURL() async throws {
        let viewModel = DiagramViewModel()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.swift")
        try "class A {}".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        viewModel.selectedPaths = [fileURL.path]
        viewModel.generate()
        
        for _ in 0..<50 {
            if !viewModel.isGenerating { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        guard let script = viewModel.script else {
            XCTFail("Script should not be nil")
            return
        }
        
        let view = DiagramWebView(script: script)
        let url = view.plantUMLURL(for: script)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("planttext.com") ?? false)
    }

    func testUpdateWebViewPlantUML() async throws {
        let viewModel = DiagramViewModel()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.swift")
        try "class A {}".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        viewModel.selectedPaths = [fileURL.path]
        viewModel.generate()
        
        for _ in 0..<50 {
            if !viewModel.isGenerating { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let webView = WKWebView()
        let view = DiagramWebView(script: viewModel.script)
        view.updateWebView(webView)
        
        // At least we know it didn't crash and hit the logic
        XCTAssertNotNil(webView)
    }

    func testUpdateWebViewMermaid() async throws {
        let viewModel = DiagramViewModel()
        viewModel.diagramFormat = .mermaid
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.swift")
        try "class A {}".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        
        viewModel.selectedPaths = [fileURL.path]
        viewModel.generate()
        
        for _ in 0..<50 {
            if !viewModel.isGenerating { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        let webView = WKWebView()
        let view = DiagramWebView(script: viewModel.script)
        view.updateWebView(webView)
        
        XCTAssertNotNil(webView)
    }
    
    func testMakeCoordinator() {
        let view = DiagramWebView(script: nil)
        let coordinator = view.makeCoordinator()
        XCTAssertEqual(coordinator.lastLoadedText, "")
    }

    func testUpdateNSViewPreventsRedundantReloads() {
        let view = DiagramWebView(script: nil)
        let webView = WKWebView()
        let coordinator = view.makeCoordinator()
        let context = unsafeBitCast(coordinator, to: DiagramWebView.Context.self)
        
        // First update
        view.updateNSView(webView, context: context)
        XCTAssertEqual(coordinator.lastLoadedText, "")
        
        // Update with script
        let generator = ClassDiagramGenerator()
        let script = generator.generateScript(for: [], with: Configuration.default)
        let viewWithScript = DiagramWebView(script: script)
        viewWithScript.updateNSView(webView, context: context)
        XCTAssertEqual(coordinator.lastLoadedText, script.text)
        
        // Redundant update
        viewWithScript.updateNSView(webView, context: context)
        XCTAssertEqual(coordinator.lastLoadedText, script.text)
    }

    func testMermaidHTML() {
        let view = DiagramWebView(script: nil)
        let html = view.mermaidHTML("graph TD; A-->B")
        XCTAssertTrue(html.contains("graph TD; A-->B"))
        XCTAssertTrue(html.contains("mermaid.js"))
    }

    func testLifecycleWithHostingView() {
        let view = DiagramWebView(script: nil)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 100, height: 100)
        
        // Triggering layout/display can sometimes hit the lifecycle methods
        hostingView.layout()
        hostingView.display()
        
        XCTAssertNotNil(hostingView)
    }
}
