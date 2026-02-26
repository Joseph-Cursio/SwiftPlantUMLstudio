import Testing
@testable import SwiftUMLBridgeFramework

@Suite("Theme")
struct ThemeTests {

    @Test("directive theme uses given string as rawValue")
    func directiveThemeRawValue() {
        let theme = Theme.__directive__("my-custom-theme")
        #expect(theme.rawValue == "my-custom-theme")
    }

    @Test("single-word theme rawValue is lowercased")
    func singleWordThemeRawValue() {
        #expect(Theme.amiga.rawValue == "amiga")
        #expect(Theme.plain.rawValue == "plain")
        #expect(Theme.metal.rawValue == "metal")
        #expect(Theme.silver.rawValue == "silver")
        #expect(Theme.hacker.rawValue == "hacker")
    }

    @Test("camelCase theme rawValue converts to kebab-case")
    func camelCaseThemeRawValue() {
        #expect(Theme.carbonGray.rawValue == "carbon-gray")
        #expect(Theme.lightgray.rawValue == "lightgray")
        #expect(Theme.sketchyOutline.rawValue == "sketchy-outline")
        #expect(Theme.cloudscapeDesign.rawValue == "cloudscape-design")
    }

    @Test("reddress themes convert to kebab-case")
    func reddressThemeRawValues() {
        #expect(Theme.reddressDarkblue.rawValue == "reddress-darkblue")
        #expect(Theme.reddressDarkgreen.rawValue == "reddress-darkgreen")
        #expect(Theme.reddressDarkorange.rawValue == "reddress-darkorange")
        #expect(Theme.reddressDarkred.rawValue == "reddress-darkred")
        #expect(Theme.reddressLightblue.rawValue == "reddress-lightblue")
        #expect(Theme.reddressLightgreen.rawValue == "reddress-lightgreen")
        #expect(Theme.reddressLightorange.rawValue == "reddress-lightorange")
        #expect(Theme.reddressLightred.rawValue == "reddress-lightred")
    }

    @Test("multi-word themes produce correct kebab-case")
    func multiWordThemeRawValues() {
        #expect(Theme.awsOrange.rawValue == "aws-orange")
        #expect(Theme.blackKnight.rawValue == "black-knight")
        #expect(Theme.ceruleanOutline.rawValue == "cerulean-outline")
        #expect(Theme.cyborgOutline.rawValue == "cyborg-outline")
        #expect(Theme.materiaOutline.rawValue == "materia-outline")
        #expect(Theme.spacelabWhite.rawValue == "spacelab-white")
        #expect(Theme.superheroOutline.rawValue == "superhero-outline")
        #expect(Theme.superhero.rawValue == "superhero")
    }

    @Test("preferred list is non-empty and contains known themes")
    func preferredListNonEmpty() {
        #expect(!Theme.preferred.isEmpty)
        let rawValues = Theme.preferred.map { $0.rawValue }
        #expect(rawValues.contains("amiga"))
        #expect(rawValues.contains("carbon-gray"))
    }
}
