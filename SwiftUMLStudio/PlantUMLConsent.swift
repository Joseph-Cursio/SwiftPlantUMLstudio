import Foundation

/// Persists the user's one-time consent to render PlantUML diagrams via the
/// third-party `planttext.com` service. PlantUML rendering uploads the
/// diagram source over HTTPS to that service — the consent gate makes the
/// network use explicit instead of silent, which App Store Review expects for
/// any non-essential third-party data transmission.
///
/// Other formats (Mermaid, Nomnoml, SVG) render locally and do not require
/// consent.
enum PlantUMLConsent {
    nonisolated private static let userDefaultsKey = "plantUMLRenderingConsented"

    nonisolated static var hasConsented: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    nonisolated static func grant() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }

    /// Clears the persisted consent — used by tests and any future Settings
    /// surface that offers a "revoke" toggle.
    nonisolated static func revoke() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
