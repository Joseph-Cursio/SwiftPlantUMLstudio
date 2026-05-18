import Foundation

/// Sandbox-safe wrappers around `URL`'s security-scoped bookmark APIs. Used to
/// persist user-granted file access across launches: under App Sandbox a raw
/// path string carries no access rights, so the Studio app stores a bookmark
/// alongside each path and re-grants access on load by resolving it here.
enum SecurityScopedURL {

    /// Create security-scoped bookmark data for a URL the user has granted
    /// access to (typically via `NSOpenPanel`). Returns `nil` if the system
    /// refuses to produce a bookmark — most commonly when the receiver isn't
    /// reachable or the caller has no access right to begin with.
    nonisolated static func makeBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Resolve a previously created security-scoped bookmark back to a URL.
    /// Returns the resolved URL plus a stale-flag that callers should observe:
    /// when `isStale == true` the bookmark should be re-created from the URL
    /// and re-persisted, otherwise it may stop resolving in a future OS
    /// release.
    nonisolated static func resolveURL(from bookmark: Data) -> (url: URL, isStale: Bool)? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        return (url, isStale)
    }

    /// Given the bookmark that was just resolved and the URL it produced, pick
    /// the bookmark to persist back to disk. Stale bookmarks regenerate from
    /// the live URL; fresh ones are returned unchanged. Falls back to the
    /// original bookmark if regeneration fails (e.g., the URL is no longer
    /// reachable at this instant), which is safer than persisting `nil` and
    /// losing all sandbox access on the next launch.
    nonisolated static func bookmarkToPersist(original: Data, resolvedURL: URL, isStale: Bool) -> Data {
        guard isStale else { return original }
        return makeBookmark(for: resolvedURL) ?? original
    }
}
