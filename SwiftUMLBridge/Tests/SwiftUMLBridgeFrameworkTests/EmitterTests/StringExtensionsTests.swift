import Testing
@testable import SwiftUMLBridgeFramework

@Suite("String+Extensions")
struct StringExtensionsTests {

    // MARK: - appendAsNewLine

    @Test("appendAsNewLine prepends a newline character")
    func appendAsNewLinePrependsNewline() {
        var s = "first"
        s.appendAsNewLine("second")
        #expect(s == "first\nsecond")
    }

    @Test("appendAsNewLine on empty string produces newline prefix")
    func appendAsNewLineOnEmpty() {
        var s = ""
        s.appendAsNewLine("content")
        #expect(s == "\ncontent")
    }

    @Test("appendAsNewLine can chain multiple appends")
    func appendAsNewLineMultiple() {
        var s = "line1"
        s.appendAsNewLine("line2")
        s.appendAsNewLine("line3")
        #expect(s == "line1\nline2\nline3")
    }

    // MARK: - removeAngleBracketsWithContent

    @Test("removeAngleBracketsWithContent removes generic notation")
    func removeAngleBracketsWithGeneric() {
        let result = "Collection<Element>".removeAngleBracketsWithContent()
        #expect(result == "Collection")
    }

    @Test("removeAngleBracketsWithContent leaves plain strings unchanged")
    func removeAngleBracketsNoGeneric() {
        let result = "MyClass".removeAngleBracketsWithContent()
        #expect(result == "MyClass")
    }

    @Test("removeAngleBracketsWithContent removes nested generics")
    func removeAngleBracketsNestedGeneric() {
        let result = "Dictionary<String, Int>".removeAngleBracketsWithContent()
        #expect(result == "Dictionary")
    }

    // MARK: - getAngleBracketsWithContent

    @Test("getAngleBracketsWithContent extracts angle bracket content")
    func getAngleBracketsExtracts() {
        let result = "Array<Element>".getAngleBracketsWithContent()
        #expect(result == "<Element>")
    }

    @Test("getAngleBracketsWithContent returns nil when no angle brackets")
    func getAngleBracketsNone() {
        let result = "MyClass".getAngleBracketsWithContent()
        #expect(result == nil)
    }

    @Test("getAngleBracketsWithContent handles multiple type params")
    func getAngleBracketsMultipleParams() {
        let result = "Dict<K, V>".getAngleBracketsWithContent()
        #expect(result == "<K, V>")
    }

    // MARK: - isMatching

    @Test("isMatching returns true for exact match")
    func isMatchingExactMatch() {
        #expect("MyClass".isMatching(searchPattern: "MyClass"))
    }

    @Test("isMatching returns false for non-match")
    func isMatchingNoMatch() {
        #expect("MyClass".isMatching(searchPattern: "OtherClass") == false)
    }

    @Test("isMatching supports * wildcard for any non-slash characters")
    func isMatchingStarWildcard() {
        #expect("MyClass".isMatching(searchPattern: "My*"))
        #expect("MyClass".isMatching(searchPattern: "*Class"))
        #expect("MyClass".isMatching(searchPattern: "*"))
    }

    @Test("isMatching supports ** wildcard for any characters")
    func isMatchingDoubleStarWildcard() {
        #expect("path/to/MyClass".isMatching(searchPattern: "**/MyClass"))
    }

    @Test("isMatching supports ? wildcard for single non-slash character")
    func isMatchingQuestionWildcard() {
        #expect("MyClass".isMatching(searchPattern: "MyClass?") == false)
        #expect("MyClas".isMatching(searchPattern: "MyCla?"))
    }

    @Test("isMatching is anchored at start and end")
    func isMatchingAnchored() {
        #expect("MyClass".isMatching(searchPattern: "Class") == false)
        #expect("MyClass".isMatching(searchPattern: "My") == false)
    }

    // MARK: - addOrSkipMemberAccessLevelAttribute

    @Test("addOrSkipMemberAccessLevelAttribute adds + for public element")
    func addAccessLevelPublic() {
        var s = ""
        let element = SyntaxStructure(accessibility: .public, kind: .functionMethodInstance, name: "foo")
        s.addOrSkipMemberAccessLevelAttribute(for: element, basedOn: .default)
        #expect(s == "+")
    }

    @Test("addOrSkipMemberAccessLevelAttribute adds ~ for internal element")
    func addAccessLevelInternal() {
        var s = ""
        let element = SyntaxStructure(accessibility: .internal, kind: .varInstance, name: "foo")
        s.addOrSkipMemberAccessLevelAttribute(for: element, basedOn: .default)
        #expect(s == "~")
    }

    @Test("addOrSkipMemberAccessLevelAttribute adds - for private element")
    func addAccessLevelPrivate() {
        var s = ""
        let element = SyntaxStructure(accessibility: .private, kind: .varInstance, name: "bar")
        s.addOrSkipMemberAccessLevelAttribute(for: element, basedOn: .default)
        #expect(s == "-")
    }

    @Test("addOrSkipMemberAccessLevelAttribute skips when showMemberAccessLevelAttribute is false")
    func skipWhenDisabled() {
        var s = ""
        let element = SyntaxStructure(accessibility: .public, kind: .functionMethodInstance, name: "foo")
        let config = Configuration(
            elements: ElementOptions(showMemberAccessLevelAttribute: false)
        )
        s.addOrSkipMemberAccessLevelAttribute(for: element, basedOn: config)
        #expect(s == "")
    }
}
