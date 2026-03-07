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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground") // Allow transparency
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let newText = script?.text ?? ""
        guard newText != context.coordinator.lastLoadedText else { return }
        context.coordinator.lastLoadedText = newText
        updateWebView(webView)
    }

    func updateWebView(_ webView: WKWebView) {
        guard let script, !script.text.isEmpty else { return }
        switch script.format {
        case .plantuml:
            if let url = plantUMLURL(for: script) {
                webView.load(URLRequest(url: url))
            }
        case .mermaid:
            webView.loadHTMLString(mermaidHTML(script.text), baseURL: nil)
        }
    }

    func plantUMLURL(for script: any DiagramOutputting) -> URL? {
        let encoded = script.encodeText()
        let urlString = "https://www.planttext.com/api/plantuml/svg/\(encoded)"
        return URL(string: urlString)
    }

    func mermaidHTML(_ text: String) -> String {
        // swiftlint:disable:next line_length
        """
        <html>
        <head>
            <style>
                body {
                    background: transparent;
                    padding: 20px;
                    margin: 0;
                    display: flex;
                    justify-content: center;
                }
                @media (prefers-color-scheme: dark) {
                    .mermaid { background-color: transparent !important; }
                }
            </style>
        </head>
        <body>
            <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
            <script>
                const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                mermaid.initialize({
                    startOnLoad: true,
                    theme: isDark ? 'dark' : 'default',
                    securityLevel: 'loose'
                });
            </script>
            <div class="mermaid">
                \(text)
            </div>
        </body>
        </html>
        """
    }

    class Coordinator {
        var lastLoadedText: String = ""
    }
}
