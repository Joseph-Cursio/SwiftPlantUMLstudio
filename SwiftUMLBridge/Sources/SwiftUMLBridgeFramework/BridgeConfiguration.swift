import Foundation

/// Runtime toggles for the Bridge framework.
///
/// Hosts running inside the macOS App Sandbox (e.g. App-Store-distributed
/// Studio builds) cannot tolerate `dlopen`-ing `sourcekitdInProc.framework`
/// from the system Xcode toolchain. Flip `skipSourceKitTypenameSupplement`
/// before any parsing entry point is called to keep `SyntaxStructureProvider`
/// on the SwiftSyntax-only path.
public enum BridgeConfiguration {
    /// When `true`, `SyntaxStructure.create(...)` skips the SourceKit pass
    /// that resolves inferred variable typenames. Defaults to `false`. The
    /// only loss is fidelity for `let x = foo()`-style declarations whose
    /// types cannot be read from the syntax tree alone.
    nonisolated(unsafe) public static var skipSourceKitTypenameSupplement: Bool = false
}
