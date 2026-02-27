//
//  DiagramWebView.swift
//  SwiftPlantUMLstudio
//
//  Created by joe cursio on 2/27/26.
//

import SwiftUI
import WebKit
import SwiftUMLBridgeFramework

/// NSViewRepresentable wrapping WKWebView, rendering the diagram SVG via planttext.com.
struct DiagramWebView: NSViewRepresentable {
    var script: DiagramScript?

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let script, !script.text.isEmpty else { return }
        let encoded = script.encodeText()
        let urlString = "https://www.planttext.com/api/plantuml/svg/\(encoded)"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}
