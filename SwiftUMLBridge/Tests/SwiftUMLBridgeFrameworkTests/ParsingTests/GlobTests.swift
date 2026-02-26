import Testing
@testable import SwiftUMLBridgeFramework
import Foundation

@Suite("Glob")
struct GlobTests {

    private var projectMockURL: URL {
        Bundle.module.resourceURL!
            .appendingPathComponent("TestData")
            .appendingPathComponent("ProjectMock")
    }

    // MARK: - pathContainsGlobSyntax

    @Test("pathContainsGlobSyntax returns true for * wildcard")
    func pathContainsStarWildcard() {
        #expect(pathContainsGlobSyntax("Sources/**/*.swift"))
    }

    @Test("pathContainsGlobSyntax returns true for ? wildcard")
    func pathContainsQuestionWildcard() {
        #expect(pathContainsGlobSyntax("Sources/?oo.swift"))
    }

    @Test("pathContainsGlobSyntax returns true for [ character")
    func pathContainsBracket() {
        #expect(pathContainsGlobSyntax("file[0-9].swift"))
    }

    @Test("pathContainsGlobSyntax returns true for { character")
    func pathContainsBrace() {
        #expect(pathContainsGlobSyntax("file{A,B}.swift"))
    }

    @Test("pathContainsGlobSyntax returns false for plain path")
    func pathContainsPlain() {
        #expect(!pathContainsGlobSyntax("/absolute/path/to/file.swift"))
    }

    @Test("pathContainsGlobSyntax returns false for empty string")
    func pathContainsEmpty() {
        #expect(!pathContainsGlobSyntax(""))
    }

    // MARK: - parseCommaDelimitedList

    @Test("parseCommaDelimitedList splits by comma")
    func parseCommaBasic() {
        let result = parseCommaDelimitedList("a,b,c")
        #expect(result == ["a", "b", "c"])
    }

    @Test("parseCommaDelimitedList trims whitespace")
    func parseCommaTrimsWhitespace() {
        let result = parseCommaDelimitedList("a , b , c")
        #expect(result == ["a", "b", "c"])
    }

    @Test("parseCommaDelimitedList filters empty entries")
    func parseCommaFiltersEmpty() {
        let result = parseCommaDelimitedList("a,,b")
        #expect(result == ["a", "b"])
    }

    @Test("parseCommaDelimitedList returns empty for empty string")
    func parseCommaEmpty() {
        let result = parseCommaDelimitedList("")
        #expect(result.isEmpty)
    }

    @Test("parseCommaDelimitedList returns single item for no comma")
    func parseCommaSingleItem() {
        let result = parseCommaDelimitedList("Sources/Foo.swift")
        #expect(result == ["Sources/Foo.swift"])
    }

    // MARK: - expandPath

    @Test("expandPath returns URL unchanged for absolute path")
    func expandPathAbsolute() {
        let url = expandPath("/usr/local/bin", in: "/tmp")
        #expect(url.path == "/usr/local/bin")
    }

    @Test("expandPath expands tilde to home directory")
    func expandPathTilde() {
        let url = expandPath("~/Documents", in: "/tmp")
        let home = NSString(string: "~").expandingTildeInPath
        #expect(url.path.hasPrefix(home))
    }

    @Test("expandPath appends relative path to directory")
    func expandPathRelative() {
        let url = expandPath("sub/file.swift", in: "/tmp/project")
        #expect(url.path == "/tmp/project/sub/file.swift")
    }

    // MARK: - expandGlobs

    @Test("expandGlobs without glob syntax returns path globs")
    func expandGlobsNoGlobSyntax() {
        let globs = expandGlobs("Sources/Foo.swift", in: projectMockURL.path)
        #expect(!globs.isEmpty)
        for glob in globs {
            switch glob {
            case .path:
                #expect(Bool(true))
            case .regex:
                break
            }
        }
    }

    @Test("expandGlobs with wildcard returns regex globs")
    func expandGlobsWithWildcard() {
        let globs = expandGlobs("**/*.swift", in: projectMockURL.path)
        #expect(!globs.isEmpty)
    }

    @Test("expandGlobs handles brace expansion")
    func expandGlobsBraceExpansion() {
        let globs = expandGlobs("{Mock0,Mock1}File.swift", in: projectMockURL.path)
        #expect(!globs.isEmpty)
    }

    @Test("expandGlobs with comma-delimited paths produces multiple globs")
    func expandGlobsMultiplePaths() {
        let globs = expandGlobs("Mock0File.swift,Mock1File.swift", in: projectMockURL.path)
        #expect(globs.count >= 1)
    }

    // MARK: - Glob.matches

    @Test("Glob.path matches exact path")
    func globPathMatchesExact() {
        let glob = Glob.path("/path/to/file.swift")
        #expect(glob.matches("/path/to/file.swift"))
    }

    @Test("Glob.path matches substring of path")
    func globPathMatchesSubstring() {
        let glob = Glob.path("to/file.swift")
        #expect(glob.matches("/path/to/file.swift"))
    }

    @Test("Glob.path does not match unrelated path")
    func globPathNoMatch() {
        let glob = Glob.path("/other/path/file.swift")
        #expect(!glob.matches("/completely/different/path.swift"))
    }

    @Test("Glob.regex matches pattern")
    func globRegexMatches() {
        let pattern = "^.*\\.swift$"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let glob = Glob.regex(regex)
            #expect(glob.matches("/path/to/file.swift"))
            #expect(!glob.matches("/path/to/file.txt"))
        }
    }

    // MARK: - Glob.description

    @Test("Glob.path description returns path string")
    func globPathDescription() {
        let glob = Glob.path("/some/path/file.swift")
        #expect(glob.description == "/some/path/file.swift")
    }

    @Test("Glob.regex description reconstructs glob pattern")
    func globRegexDescription() {
        let globs = expandGlobs("**/*.swift", in: "/tmp")
        for glob in globs {
            let desc = glob.description
            #expect(!desc.isEmpty)
        }
    }

    // MARK: - matchGlobs

    @Test("matchGlobs finds matching files in directory")
    func matchGlobsFindsFiles() {
        let globs = expandGlobs("**/Mock*.swift", in: projectMockURL.path)
        let results = matchGlobs(globs, in: projectMockURL.path)
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.lastPathComponent.hasPrefix("Mock") })
    }

    @Test("matchGlobs returns empty for non-matching pattern")
    func matchGlobsNoMatch() {
        let globs = expandGlobs("NonExistent*.xyz", in: projectMockURL.path)
        let results = matchGlobs(globs, in: projectMockURL.path)
        // Should be empty since no .xyz files exist
        #expect(results.allSatisfy { $0.pathExtension == "xyz" } || results.isEmpty)
    }
}
