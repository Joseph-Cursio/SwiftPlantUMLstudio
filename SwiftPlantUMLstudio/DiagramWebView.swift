//
//  DiagramWebView.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import SwiftUI
import WebKit
import SwiftUMLBridgeFramework

/// NSViewRepresentable wrapping WKWebView, rendering the diagram via planttext.com (PlantUML) or
/// an embedded Mermaid.js page (Mermaid).
struct DiagramWebView: NSViewRepresentable {
    var script: (any DiagramOutputting)?

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let script, !script.text.isEmpty else { return }
        switch script.format {
        case .plantuml:
            let encoded = script.encodeText()
            let urlString = "https://www.planttext.com/api/plantuml/svg/\(encoded)"
            if let url = URL(string: urlString) {
                webView.load(URLRequest(url: url))
            }
        case .mermaid:
            webView.loadHTMLString(mermaidHTML(script.text), baseURL: nil)
        }
    }

    private func mermaidHTML(_ text: String) -> String {
        // swiftlint:disable:next line_length
        "<html><body style=\"background:white; padding:20px;\"><script src=\"https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js\"></script><script>mermaid.initialize({ startOnLoad: true, theme: 'default' });</script><div class=\"mermaid\">\(text)</div></body></html>"
    }
}
