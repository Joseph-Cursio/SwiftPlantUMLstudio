import Testing
@testable import SwiftUMLBridgeFramework

@Suite("PageTexts")
struct PageTextsTests {

    @Test("plantuml() returns nil when all fields are nil")
    func allNilReturnsNil() {
        let texts = PageTexts()
        #expect(texts.plantuml() == nil)
    }

    @Test("plantuml() returns non-nil when header is set")
    func headerOnlyReturnsNonNil() {
        let texts = PageTexts(header: "Top")
        #expect(texts.plantuml() != nil)
    }

    @Test("plantuml() includes header keyword and content")
    func headerSection() {
        let texts = PageTexts(header: "My Header")
        let result = texts.plantuml()
        #expect(result?.contains("header") == true)
        #expect(result?.contains("My Header") == true)
        #expect(result?.contains("end header") == true)
    }

    @Test("plantuml() includes title keyword and content")
    func titleSection() {
        let texts = PageTexts(title: "My Title")
        let result = texts.plantuml()
        #expect(result?.contains("title") == true)
        #expect(result?.contains("My Title") == true)
        #expect(result?.contains("end title") == true)
    }

    @Test("plantuml() includes legend keyword and content")
    func legendSection() {
        let texts = PageTexts(legend: "My Legend")
        let result = texts.plantuml()
        #expect(result?.contains("legend") == true)
        #expect(result?.contains("My Legend") == true)
        #expect(result?.contains("end legend") == true)
    }

    @Test("plantuml() includes caption keyword and content")
    func captionSection() {
        let texts = PageTexts(caption: "My Caption")
        let result = texts.plantuml()
        #expect(result?.contains("caption") == true)
        #expect(result?.contains("My Caption") == true)
        #expect(result?.contains("end caption") == true)
    }

    @Test("plantuml() includes footer keyword and content")
    func footerSection() {
        let texts = PageTexts(footer: "My Footer")
        let result = texts.plantuml()
        #expect(result?.contains("footer") == true)
        #expect(result?.contains("My Footer") == true)
        #expect(result?.contains("end footer") == true)
    }

    @Test("plantuml() includes all five sections when all fields are set")
    func allFieldsIncluded() {
        let texts = PageTexts(header: "H", title: "T", legend: "L", caption: "C", footer: "F")
        let result = texts.plantuml()
        #expect(result?.contains("header") == true)
        #expect(result?.contains("title") == true)
        #expect(result?.contains("legend") == true)
        #expect(result?.contains("caption") == true)
        #expect(result?.contains("footer") == true)
        #expect(result?.contains("end header") == true)
        #expect(result?.contains("end title") == true)
        #expect(result?.contains("end legend") == true)
        #expect(result?.contains("end caption") == true)
        #expect(result?.contains("end footer") == true)
    }

    @Test("PageTexts respects field mutability")
    func fieldsAreMutable() {
        var texts = PageTexts()
        texts.header = "New Header"
        texts.footer = "New Footer"
        let result = texts.plantuml()
        #expect(result?.contains("New Header") == true)
        #expect(result?.contains("New Footer") == true)
    }
}
