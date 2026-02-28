import AppKit
import Foundation

/// Presentation formats supported to render PlantUML scripts in browser
public enum BrowserPresentationFormat: Sendable {
    case png
    case svg
    case `default`
}

/// Compress diagram into a URL and open in browser
public struct BrowserPresenter: DiagramPresenting {
    public private(set) var format: BrowserPresentationFormat

    public init(format: BrowserPresentationFormat = .default) {
        self.format = format
    }

    public func present(script: DiagramScript) async {
        let url: URL
        switch script.format {
        case .plantuml:
            let encodedText = script.encodeText()
            switch format {
            case .png:
                url = URL(string: "https://www.planttext.com/api/plantuml/png/\(encodedText)")!
            case .svg:
                url = URL(string: "https://www.planttext.com/api/plantuml/svg/\(encodedText)")!
            default:
                url = URL(string: "https://www.planttext.com/?text=\(encodedText)")!
            }
        case .mermaid:
            url = mermaidLiveURL(for: script.text)
        }
        _ = await MainActor.run { NSWorkspace.shared.open(url) }
    }

    private func mermaidLiveURL(for text: String) -> URL {
        let payload: [String: Any] = [
            "code": text,
            "mermaid": ["theme": "default"]
        ]
        let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
        let base64 = data.base64EncodedString()
        return URL(string: "https://mermaid.live/view#base64:\(base64)")
            ?? URL(string: "https://mermaid.live")!
    }
}
