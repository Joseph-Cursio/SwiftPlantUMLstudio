//
//  MermaidHTMLBuilder.swift
//  SwiftUMLStudio
//
//  Created by joe cursio on 2/27/26.
//

import Foundation

enum MermaidHTMLBuilder {
    nonisolated static func htmlEscape(_ raw: String) -> String {
        raw
            .replacing("&", with: "&amp;")
            .replacing("<", with: "&lt;")
            .replacing(">", with: "&gt;")
    }

    nonisolated static func mermaidHTML(_ text: String, dark: Bool = false) -> String {
        let escaped = htmlEscape(text)
        let scriptTag: String
        if let bundleURL = Bundle.main.url(forResource: "mermaid.min", withExtension: "js") {
            scriptTag = "<script src=\"\(bundleURL.absoluteString)\"></script>"
        } else {
            scriptTag = "<script src=\"https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js\"></script>"
        }
        let theme = dark ? "dark" : "default"
        let bg = dark ? "#1e1e1e" : "white"
        return """
        <html>
        <body style="background:\(bg); padding:20px;">
        \(scriptTag)
        <script>mermaid.initialize({ startOnLoad: true, theme: '\(theme)' });</script>
        <div class="mermaid">\(escaped)</div>
        </body>
        </html>
        """
    }
}
