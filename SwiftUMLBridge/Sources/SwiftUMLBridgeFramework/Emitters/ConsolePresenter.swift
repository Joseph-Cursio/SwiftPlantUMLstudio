import Foundation

/// Print script to console
public struct ConsolePresenter: DiagramPresenting {
    public init() {}

    public func present(script: DiagramScript, completionHandler: @escaping () -> Void) {
        print(script.text)
        completionHandler()
    }
}
