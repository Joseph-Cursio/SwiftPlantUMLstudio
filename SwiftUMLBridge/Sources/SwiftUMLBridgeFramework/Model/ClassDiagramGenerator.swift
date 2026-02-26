import Foundation

/// UML Class Diagram powered by PlantUML
public struct ClassDiagramGenerator {
    private let fileCollector = FileCollector()

    public init() {}

    /// Generate diagram from Swift file(s)
    public func generate(for paths: [String], with configuration: Configuration = .default, presentedBy presenter: DiagramPresenting = BrowserPresenter(), sdkPath: String? = nil) {
        let startDate = Date()
        outputDiagram(for: generateScript(for: fileCollector.getFiles(for: paths), with: configuration, sdkPath: sdkPath), with: presenter, processingStartDate: startDate)
    }

    /// Generate diagram from Swift source string
    public func generate(from content: String, with configuration: Configuration = .default, presentedBy presenter: DiagramPresenting = BrowserPresenter()) {
        let startDate = Date()
        outputDiagram(for: generateScript(for: content, with: configuration), with: presenter, processingStartDate: startDate)
    }

    func generateScript(for content: String, with configuration: Configuration = .default) -> DiagramScript {
        var allValidItems: [SyntaxStructure] = []
        if let validItems = SyntaxStructure.create(from: content)?.substructure {
            allValidItems.append(contentsOf: validItems)
        }
        return DiagramScript(items: allValidItems, configuration: configuration)
    }

    func generateScript(for files: [URL], with configuration: Configuration = .default, sdkPath: String? = nil) -> DiagramScript {
        var allValidItems: [SyntaxStructure] = []
        for aFile in files {
            if let validItems = SyntaxStructure.create(from: aFile, sdkPath: sdkPath)?.substructure {
                allValidItems.append(contentsOf: validItems)
            }
        }
        return DiagramScript(items: allValidItems, configuration: configuration)
    }

    func outputDiagram(for script: DiagramScript, with presenter: DiagramPresenting, processingStartDate date: Date) {
        logProcessingDuration(started: date)
        let semaphore = DispatchSemaphore(value: 0)
        presenter.present(script: script) {
            semaphore.signal()
        }
        semaphore.wait()
    }

    func logProcessingDuration(started processingStartDate: Date) {
        BridgeLogger.shared.info("Class diagram generated in \(Date().timeIntervalSince(processingStartDate)) seconds and will be presented now")
    }
}
