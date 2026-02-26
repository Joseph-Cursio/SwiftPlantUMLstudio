import AppKit
import Foundation

/// Presentation formats supported to render PlantUML scripts in browser
public enum BrowserPresentationFormat {
    case png
    case svg
    case `default`
}

/// Compress diagram into a URL and open in browser (PlantText server)
public struct BrowserPresenter: DiagramPresenting {
    public private(set) var format: BrowserPresentationFormat

    public init(format: BrowserPresentationFormat = .default) {
        self.format = format
    }

    public func present(script: DiagramScript, completionHandler: @escaping () -> Void) {
        let encodedText = script.encodeText()
        let url: URL
        switch format {
        case .png:
            url = URL(string: "https://www.planttext.com/api/plantuml/png/\(encodedText)")!
        case .svg:
            url = URL(string: "https://www.planttext.com/api/plantuml/svg/\(encodedText)")!
        default:
            url = URL(string: "https://www.planttext.com/?text=\(encodedText)")!
        }
        NSWorkspace.shared.open(url)
        completionHandler()
    }
}
