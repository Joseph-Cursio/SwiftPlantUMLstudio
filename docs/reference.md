# SwiftUMLBridge Reference Guide

Complete reference for all CLI options, YAML configuration fields, element kinds, relationship styles, themes, colors, and public framework types.

---

## Table of Contents

1. [CLI Reference](#cli-reference)
   - [Root Command](#root-command)
   - [classdiagram](#classdiagram)
2. [Configuration File Schema](#configuration-file-schema)
   - [files](#files)
   - [elements](#elements)
   - [hideShowCommands](#hideshowcommands)
   - [skinparamCommands](#skinparamcommands)
   - [includeRemoteURL](#includeremoteurl)
   - [theme](#theme)
   - [relationships](#relationships)
   - [stereotypes](#stereotypes)
   - [texts](#texts)
   - [format](#format)
3. [Diagram Formats](#diagram-formats)
4. [Element Kinds](#element-kinds)
5. [Access Levels](#access-levels)
6. [Relationship Arrows](#relationship-arrows)
7. [RelationshipStyle Properties](#relationshipstyle-properties)
8. [Themes](#themes)
9. [Colors](#colors)
10. [Output Destinations](#output-destinations)
11. [Glob Pattern Syntax](#glob-pattern-syntax)
12. [Framework API](#framework-api)
    - [ClassDiagramGenerator](#classdiagramgenerator)
    - [DiagramFormat](#diagramformat)
    - [Configuration](#configuration)
    - [ConfigurationProvider](#configurationprovider)
    - [FileCollector](#filecollector)
    - [DiagramScript](#diagramscript)
    - [DiagramPresenting](#diagrampresenting)
    - [BrowserPresenter](#browserpresenter)
    - [ConsolePresenter](#consolepresenter)
    - [BridgeLogger](#bridgelogger)
13. [Version](#version)

---

## CLI Reference

### Root Command

```
swiftumlbridge [--version] [--help] <subcommand>
```

| Option | Description |
|---|---|
| `--version` | Print the tool version and exit (`0.1.0`) |
| `--help` | Print help and exit |

The default subcommand is `classdiagram`. Running `swiftumlbridge` with no verb is equivalent to `swiftumlbridge classdiagram`.

---

### classdiagram

Generate a PlantUML or Mermaid class diagram from Swift source files.

```
swiftumlbridge classdiagram [<paths>...] [options]
```

**Positional arguments:**

| Argument | Type | Description |
|---|---|---|
| `<paths>...` | `[String]` | Zero or more paths to `.swift` files or directories to scan recursively. Defaults to the current directory. Ignored when `files.include` patterns are set in the config file. |

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `--config <path>` | `String?` | `nil` | Path to a custom `.swiftumlbridge.yml` file. When omitted, looks for `.swiftumlbridge.yml` in the current directory, then falls back to built-in defaults. |
| `--exclude <path>...` | `[String]` | `[]` | File or directory paths to exclude. Takes precedence over positional path arguments. May be specified multiple times. |
| `--format <format>` | `DiagramFormat?` | `plantuml` | Diagram language. One of: `plantuml`, `mermaid`. Overrides the `format` field in the config file. |
| `--output <format>` | `ClassDiagramOutput?` | `browser` | Output destination. One of: `browser`, `browserImageOnly`, `consoleOnly`. |
| `--sdk <path>` | `String?` | `nil` | macOS SDK path for improved type inference. Typically `$(xcrun --show-sdk-path -sdk macosx)`. |
| `--show-extensions` | Flag | — | Show all extensions as separate nodes (overrides config file). |
| `--merge-extensions` | Flag | — | Fold extension members into parent type nodes (overrides config file). |
| `--hide-extensions` | Flag | — | Remove all extensions from the diagram (overrides config file). |
| `--verbose` | Flag | `false` | Enable verbose logging to stderr. |
| `--help` | Flag | — | Print subcommand help and exit. |

**Extension flags are mutually exclusive.** If more than one is passed, the last one wins.

**Examples:**

```bash
# Diagram all Swift files in Sources/, open in browser (PlantUML, default)
swiftumlbridge classdiagram Sources/

# Generate Mermaid output and open in Mermaid Live editor
swiftumlbridge classdiagram Sources/ --format mermaid

# Print Mermaid markup to stdout
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly

# Use a custom config, write PlantUML to stdout
swiftumlbridge classdiagram Sources/ --config ./docs/diagram.yml --output consoleOnly

# Diagram with SDK for better type resolution, open PNG
swiftumlbridge classdiagram Sources/ \
  --sdk "$(xcrun --show-sdk-path -sdk macosx)" \
  --output browserImageOnly

# Exclude generated files
swiftumlbridge classdiagram Sources/ --exclude Sources/Generated/ --exclude Sources/Mocks/

# Merge extensions for a compact overview
swiftumlbridge classdiagram Sources/ --merge-extensions
```

---

## Configuration File Schema

The configuration file is a YAML file named `.swiftumlbridge.yml`. All fields are optional. Any field you omit uses its built-in default.

**Annotated full schema:**

```yaml
# ─── files ─────────────────────────────────────────────────────────────────
files:
  include:
    # Glob patterns relative to the current directory.
    # When non-empty, positional <paths> arguments are ignored.
    # Type: [String]  Default: []
    - "Sources/**/*.swift"

  exclude:
    # Glob patterns. Matched files are excluded even if they match 'include'.
    # Type: [String]  Default: []
    - "Sources/Generated/**"
    - "Tests/**/Mock*.swift"

# ─── elements ──────────────────────────────────────────────────────────────
elements:
  havingAccessLevel:
    # Which type declarations (classes, structs, etc.) to include in the diagram.
    # Type: [AccessLevel]
    # Values: open | public | package | internal | private | fileprivate
    # Default: [open, public, package, internal, private, fileprivate]
    - public
    - internal

  showMembersWithAccessLevel:
    # Which member declarations (vars, funcs) to show inside included types.
    # Type: [AccessLevel]  Default: [open, public, package, internal, private, fileprivate]
    - public

  showMemberAccessLevelAttribute: true
    # When true, prefix each member with + (public/open), ~ (internal/package),
    # or - (private/fileprivate).
    # Type: Bool  Default: false

  showNestedTypes: true
    # When true, nested type declarations are shown as child nodes connected
    # by composition arrows (+-- in PlantUML; skipped in Mermaid).
    # Type: Bool  Default: true

  showGenerics: true
    # When true, generic type parameters (<T>, <Key, Value>) appear on type nodes.
    # Type: Bool  Default: true

  showExtensions: merged
    # Controls how extension declarations are rendered.
    # Type: all | merged | none
    #   all    — each extension is a separate node (default)
    #   merged — extension members are folded into the parent type node
    #   none   — extensions are hidden entirely
    # Also accepts Boolean: true → all, false → none
    # Default: all

  mergedExtensionMemberIndicator: "^"
    # String appended to member names that were merged from an extension.
    # Only applies when showExtensions: merged.
    # Type: String?  Default: nil

  exclude:
    # Glob patterns matched against type names (not file paths).
    # Matched types are excluded from the diagram.
    # Type: [String]  Default: []
    - "UIViewController"
    - "NS*"

# ─── hideShowCommands ──────────────────────────────────────────────────────
hideShowCommands:
  # Raw PlantUML 'hide' or 'show' directives inserted verbatim into the diagram.
  # Ignored when format is 'mermaid'.
  # Type: [String]  Default: ["hide empty members"]
  - "hide empty members"
  - "hide @unlinked"

# ─── skinparamCommands ─────────────────────────────────────────────────────
skinparamCommands:
  # Raw PlantUML 'skinparam' directives inserted verbatim into the diagram.
  # Ignored when format is 'mermaid'.
  # Type: [String]  Default: ["skinparam shadowing false"]
  - "skinparam shadowing false"
  - "skinparam sequenceMessageAlign center"

# ─── includeRemoteURL ──────────────────────────────────────────────────────
includeRemoteURL:
  # URL for a PlantUML '!include' directive. Useful for shared style libraries.
  # Ignored when format is 'mermaid'.
  # Type: String?  Default: nil
  "https://raw.githubusercontent.com/example/styles/main/custom.iuml"

# ─── theme ─────────────────────────────────────────────────────────────────
theme: minty
  # PlantUML theme name. camelCase names are converted to kebab-case automatically.
  # Use __directive__("name") to pass a raw PlantUML theme directive as-is.
  # Ignored when format is 'mermaid'.
  # Type: String?  Default: nil
  # See the Themes section for available values.

# ─── relationships ─────────────────────────────────────────────────────────
relationships:
  inheritance:
    # Solid arrow (<|--) for class inheritance (e.g., class Dog: Animal)
    label: "inherits from"    # Text label on the arrow. Type: String?  Default: nil
    exclude:
      # Parent names to suppress. Accepts glob patterns.
      # Type: [String]  Default: []
      - "NSObject"
    style:
      # Relationship style is applied to PlantUML output only; ignored for Mermaid.
      lineStyle: plain        # bold | dashed | dotted | hidden | plain
      lineColor: DarkGray     # HTML color name recognized by PlantUML
      textColor: DarkGray

  realize:
    # Dashed arrow (<|..) for protocol conformance (e.g., struct Foo: Bar)
    label: "conforms to"
    exclude:
      - "Codable"
      - "Sendable"
    style:
      lineStyle: dashed
      lineColor: RoyalBlue
      textColor: RoyalBlue

  dependency:
    # Dotted arrow (<..) for extension dependency connections
    label: "extends"
    style:
      lineStyle: dotted
      lineColor: DarkGreen
      textColor: DarkGreen

# ─── stereotypes ───────────────────────────────────────────────────────────
stereotypes:
  # Spot characters and colors apply to PlantUML output only.
  class:
    name: "class"             # Display name shown after the spot character. Type: String?
    spot:
      character: "C"          # Single character shown in the type spot circle. Type: String
      color: AliceBlue        # HTML color name for the spot circle. Type: String
  struct:
    spot:
      character: "S"
      color: AntiqueWhite
  extension:
    spot:
      character: "X"
      color: AntiqueWhite
  enum:
    spot:
      character: "E"
      color: AntiqueWhite
  protocol:
    spot:
      character: "P"
      color: AntiqueWhite

# ─── texts ─────────────────────────────────────────────────────────────────
texts:
  # Page text sections added to the diagram. All fields are optional.
  # PlantUML: rendered as header/title/legend/caption/footer blocks.
  # Mermaid: title, header, and footer are rendered as %% comment lines.
  #          legend and caption are not supported in Mermaid and are ignored.
  header: "CONFIDENTIAL"      # Top of every page
  title: "My Architecture"   # Diagram title
  legend: "Legend text"       # Legend box (PlantUML only)
  caption: "Fig. 1"          # Caption below the diagram (PlantUML only)
  footer: "Generated by swiftumlbridge"  # Bottom of every page

# ─── format ────────────────────────────────────────────────────────────────
format: plantuml
  # Diagram language for the generated output.
  # Type: plantuml | mermaid  Default: plantuml
  # Can be overridden at runtime with the --format CLI flag.
```

---

## Diagram Formats

SwiftUMLBridge supports two output diagram languages.

### PlantUML (default)

Set `format: plantuml` or pass `--format plantuml`. The generated script is wrapped in `@startuml` / `@enduml` and uses PlantUML class diagram syntax.

**Browser output:** The script is encoded and opened at [planttext.com](https://www.planttext.com).

**Script structure:**
```
@startuml
[!theme <name>]
[!include <url>]
' STYLE START
hide empty members
skinparam shadowing false
' STYLE END
set namespaceSeparator none
[header/title/legend/caption/footer blocks]
[type nodes]
[relationship arrows]
@enduml
```

**PlantUML-specific features:** themes, skinparam commands, hide/show commands, remote include URL, custom spot stereotypes, relationship line styles/colors, nested type `+--` composition connections.

### Mermaid

Set `format: mermaid` or pass `--format mermaid`. The generated script starts with `classDiagram` and uses [Mermaid.js](https://mermaid.js.org) class diagram syntax.

**Browser output:** The script is base64-encoded and opened at [mermaid.live](https://mermaid.live).

**Script structure:**
```
classDiagram
[%% title: ...]
[%% header: ...]
[%% footer: ...]
[type nodes]
[relationship arrows]
```

**Mermaid-specific notes:**
- `hideShowCommands`, `skinparamCommands`, `includeRemoteURL`, `theme`, and `stereotypes` settings are ignored.
- `texts.legend` and `texts.caption` are ignored (not supported by Mermaid classDiagram).
- `texts.title`, `texts.header`, and `texts.footer` are emitted as `%% key: value` comment lines.
- Nested type composition connections (`+--`) are omitted (not supported by Mermaid classDiagram).
- Relationship line styles and colors are omitted (not supported by Mermaid classDiagram).
- Member format: variables as `Type name`, methods as `name()`, static members with `$` classifier suffix.

**Member syntax comparison:**

| Member | PlantUML | Mermaid |
|---|---|---|
| Instance variable | `name : Type` | `Type name` |
| Static variable | `{static} name : Type` | `Type name$` |
| Instance method | `name()` | `name()` |
| Static method | `{static} name()` | `name()$` |
| Enum case | `name` | `name` |

---

## Element Kinds

SwiftUMLBridge recognizes these Swift declaration kinds:

| Kind | SourceKit Raw Value | Notes |
|---|---|---|
| `class` | `source.lang.swift.decl.class` | |
| `struct` | `source.lang.swift.decl.struct` | |
| `enum` | `source.lang.swift.decl.enum` | |
| `protocol` | `source.lang.swift.decl.protocol` | |
| `extension` | `source.lang.swift.decl.extension` | |
| `extensionClass` | `source.lang.swift.decl.extension.class` | |
| `extensionEnum` | `source.lang.swift.decl.extension.enum` | |
| `extensionProtocol` | `source.lang.swift.decl.extension.protocol` | |
| `extensionStruct` | `source.lang.swift.decl.extension.struct` | |
| `typealias` | `source.lang.swift.decl.typealias` | |
| `associatedtype` | `source.lang.swift.decl.associatedtype` | |
| `actor` | `source.lang.swift.decl.actor` | Parses as `.class` in SourceKit 6.3 (see Known Limitations) |
| `macro` | `source.lang.swift.decl.macro` | PlantUML: `note` block; Mermaid: `%% macro:` comment |
| `varInstance` | `source.lang.swift.decl.var.instance` | |
| `varStatic` | `source.lang.swift.decl.var.static` | |
| `varClass` | `source.lang.swift.decl.var.class` | |
| `functionMethodInstance` | `source.lang.swift.decl.function.method.instance` | |
| `functionMethodStatic` | `source.lang.swift.decl.function.method.static` | |
| `functionConstructor` | `source.lang.swift.decl.function.constructor` | |
| `enumcase` | `source.lang.swift.decl.enumcase` | Container for enum elements |
| `enumelement` | `source.lang.swift.decl.enumelement` | Individual case shown by name |

All other kinds are silently skipped during diagram generation.

**Diagram-renderable kinds:** `class`, `struct`, `enum`, `protocol`, `extension` (all variants), `actor`, `macro`.

---

## Access Levels

Access level values used in `havingAccessLevel` and `showMembersWithAccessLevel`:

| Value | Swift keyword | Indicator |
|---|---|---|
| `open` | `open` | `+` |
| `public` | `public` | `+` |
| `package` | `package` | `~` |
| `internal` | `internal` (default) | `~` |
| `fileprivate` | `fileprivate` | `-` |
| `private` | `private` | `-` |

The indicator prefix is applied when `showMemberAccessLevelAttribute: true`. The same `+`/`~`/`-` symbols are used in both PlantUML and Mermaid output.

**Default access level filter:** All six levels are included by default. To show only public API:

```yaml
elements:
  havingAccessLevel:
    - public
    - open
```

---

## Relationship Arrows

Arrow notation used in generated diagrams. Both PlantUML and Mermaid use the same arrow strings for inheritance, conformance, and extension connections.

| Arrow | Syntax | Meaning |
|---|---|---|
| Inheritance | `Child <\|-- Parent` | `class Dog: Animal` |
| Realization (conformance) | `Type <\|.. Protocol` | `struct Foo: Equatable` |
| Extension dependency | `Extension <.. Type` | Extension on a named type |
| Composition (nested) | `Outer +-- Inner` | Nested type declaration **(PlantUML only)** |
| Generic link | `A -- B` | Generic relationship |

---

## RelationshipStyle Properties

Each of `relationships.inheritance`, `relationships.realize`, and `relationships.dependency` accepts an optional `style` block. Style properties apply to PlantUML output only and are ignored when `format: mermaid`.

### lineStyle

Controls the line stroke:

| Value | Appearance |
|---|---|
| `plain` | Solid line (default) |
| `bold` | Thicker solid line |
| `dashed` | Dashed line |
| `dotted` | Dotted line |
| `hidden` | Line is invisible (layout only) |

### lineColor and textColor

Any HTML color name recognized by PlantUML. Common values:

| Color Name | Hex |
|---|---|
| `Black` | `#000000` |
| `White` | `#FFFFFF` |
| `Red` | `#FF0000` |
| `Green` | `#008000` |
| `Blue` | `#0000FF` |
| `DarkGray` | `#A9A9A9` |
| `DarkGreen` | `#006400` |
| `DarkViolet` | `#9400D3` |
| `RoyalBlue` | `#4169E1` |
| `AliceBlue` | `#F0F8FF` |
| `AntiqueWhite` | `#FAEBD7` |

See the [Colors](#colors) section for a broader list.

**Example style block:**

```yaml
relationships:
  inheritance:
    style:
      lineStyle: dashed
      lineColor: RoyalBlue
      textColor: RoyalBlue
```

This emits: `#line:RoyalBlue;line.dashed;text:RoyalBlue` inline on the PlantUML relationship arrow.

---

## Themes

Set a PlantUML built-in theme with the `theme` key. camelCase names are automatically converted to kebab-case (e.g., `carbonGray` → `carbon-gray`). This setting is ignored when `format: mermaid`.

**Preferred themes (tested):**

| Config Value | PlantUML Theme |
|---|---|
| `default` | Default light theme |
| `minty` | Light pastel |
| `hacker` | Dark green on black |
| `materia` | Material Design light |
| `cyborg` | Dark with blue accents |
| `sketchy` | Hand-drawn look |
| `sketchyOutline` | `sketchy-outline` |
| `carbonGray` | `carbon-gray` |
| `reddress-darkBlue` | Dark blue header style |
| `reddress-darkOrange` | Dark orange header style |
| `reddress-darkRed` | Dark red header style |
| `reddress-darkGreen` | Dark green header style |
| `reddress-lightBlue` | Light blue header style |
| `spacelab` | Bootstrap-inspired |
| `amiga` | Retro Amiga palette |
| `cerulean` | Blue-gray |
| `superhero` | Dark with purple accents |

**Using a raw PlantUML directive:**

```yaml
theme: "__directive__(\"!theme hacker from https://example.com/themes\")"
```

The `__directive__(...)` syntax passes the string verbatim to PlantUML, bypassing the camelCase-to-kebab-case conversion. Use this for custom or remotely hosted themes.

---

## Colors

PlantUML accepts any HTML 4 color name. A representative set:

### Reds
`Red`, `DarkRed`, `Crimson`, `Firebrick`, `IndianRed`, `LightCoral`, `Salmon`, `Tomato`, `OrangeRed`

### Oranges
`Orange`, `DarkOrange`, `Coral`, `SandyBrown`, `Peru`, `Chocolate`, `Sienna`, `SaddleBrown`

### Yellows
`Yellow`, `Gold`, `Goldenrod`, `DarkGoldenrod`, `PaleGoldenrod`, `Khaki`, `DarkKhaki`

### Greens
`Green`, `DarkGreen`, `LimeGreen`, `Lime`, `ForestGreen`, `SeaGreen`, `MediumSeaGreen`, `SpringGreen`, `YellowGreen`, `OliveDrab`, `Olive`, `DarkOliveGreen`

### Blues
`Blue`, `DarkBlue`, `MediumBlue`, `Navy`, `RoyalBlue`, `CornflowerBlue`, `SteelBlue`, `DodgerBlue`, `DeepSkyBlue`, `SkyBlue`, `LightSkyBlue`, `LightBlue`, `AliceBlue`, `CadetBlue`

### Purples/Violets
`Purple`, `DarkViolet`, `DarkMagenta`, `Magenta`, `Violet`, `Orchid`, `MediumOrchid`, `MediumPurple`, `BlueViolet`, `Indigo`, `SlateBlue`, `MediumSlateBlue`

### Grays
`Black`, `DarkGray`, `Gray`, `DimGray`, `LightGray`, `Silver`, `Gainsboro`, `WhiteSmoke`, `White`

### Whites/Neutrals
`AntiqueWhite`, `Beige`, `Bisque`, `BlanchedAlmond`, `Cornsilk`, `FloralWhite`, `Ivory`, `Linen`, `MintCream`, `MistyRose`, `OldLace`, `Seashell`, `Snow`

> **Complete list:** See the [PlantUML color reference](https://plantuml.com/color) for the full set of recognized names.

---

## Output Destinations

Controlled by the `--output` CLI flag. Applies to both PlantUML and Mermaid formats.

| Value | PlantUML behavior | Mermaid behavior |
|---|---|---|
| `browser` | Opens interactive planttext.com editor | Opens Mermaid Live editor (`mermaid.live`) |
| `browserImageOnly` | Opens a PNG render at planttext.com | Same as `browser` for Mermaid |
| `consoleOnly` | Prints raw PlantUML to stdout | Prints raw Mermaid to stdout |

**PlantUML encoding:** ZLIB deflate followed by PlantUML's custom base64 alphabet (`0-9A-Za-z-_=`).

**Mermaid encoding:** The script text and a theme config object are JSON-encoded and then base64-encoded, per the Mermaid Live URL format.

**Planned output formats (future milestones):**

| Format | Milestone |
|---|---|
| PlantUML sequence diagram | M3 |
| Mermaid.js sequence diagram | M3 |
| GraphViz/DOT | v1.1+ |

---

## Glob Pattern Syntax

Used in `files.include`, `files.exclude`, `elements.exclude`, and `relationships.*.exclude`.

| Pattern | Matches |
|---|---|
| `*` | Any sequence of characters (not path separators in single `*`) |
| `**` | Any sequence including path separators (recursive) |
| `?` | Any single character |
| `{a,b}` | Either `a` or `b` (brace expansion) |
| Plain string | Substring match anywhere in the path |

**Examples:**

```yaml
files:
  include:
    - "Sources/**/*.swift"          # all .swift under Sources/
    - "Sources/App/**"              # everything under Sources/App/

  exclude:
    - "**/Generated/**"             # any Generated/ directory at any depth
    - "Tests/**/Mock*.swift"        # files starting with Mock in any Tests/ subdir
    - "**/__Snapshots__/**"         # snapshot test directories

elements:
  exclude:
    - "NS*"                         # any type starting with NS
    - "UI*"                         # any type starting with UI
    - "Generated*"                  # generated types

relationships:
  inheritance:
    exclude:
      - "Codable"                   # exact match
      - "NS*"                       # wildcard match
```

**`elements.exclude` patterns match against type names (not file paths).** `files.include` and `files.exclude` patterns match against file paths relative to the working directory.

---

## Framework API

SwiftUMLBridge is also usable as a Swift Package library (`SwiftUMLBridgeFramework`). Add it to your `Package.swift`:

```swift
.package(path: "../SwiftUMLBridge"),

// In your target:
.product(name: "SwiftUMLBridgeFramework", package: "SwiftUMLBridge"),
```

---

### ClassDiagramGenerator

```swift
public struct ClassDiagramGenerator
```

Top-level orchestrator. Stateless — all state accumulates in `DiagramScript` and `DiagramContext`.

**Methods:**

```swift
// Generate from file paths (async, with presenter)
func generate(
    for paths: [String],
    with configuration: Configuration,
    presentedBy presenter: DiagramPresenting,
    sdkPath: String?
) async

// Generate from source string (useful for testing / in-memory use, async)
func generate(
    from content: String,
    with configuration: Configuration,
    presentedBy presenter: DiagramPresenting
) async

// Generate a DiagramScript synchronously from file paths (for GUI integration)
func generateScript(
    for paths: [String],
    with configuration: Configuration,
    sdkPath: String?
) -> DiagramScript
```

**Example (CLI/async):**

```swift
import SwiftUMLBridgeFramework

let generator = ClassDiagramGenerator()
var config = Configuration.default
config.format = .mermaid
let presenter = ConsolePresenter()

await generator.generate(
    for: ["Sources/"],
    with: config,
    presentedBy: presenter,
    sdkPath: nil
)
```

**Example (GUI/synchronous):**

```swift
let script = ClassDiagramGenerator().generateScript(
    for: ["/path/to/Sources"],
    with: Configuration(format: .mermaid)
)
print(script.text)
```

---

### DiagramFormat

```swift
public enum DiagramFormat: String, Codable, Sendable, CaseIterable
```

The diagram language for generated output.

| Case | Raw value | Description |
|---|---|---|
| `.plantuml` | `"plantuml"` | PlantUML class diagram syntax (default) |
| `.mermaid` | `"mermaid"` | Mermaid.js class diagram syntax |

Set on `Configuration.format` or via the `--format` CLI flag.

---

### Configuration

```swift
public struct Configuration: Codable, Sendable
```

The complete configuration object.

| Property | Type | Default |
|---|---|---|
| `files` | `FileOptions` | Empty include/exclude |
| `elements` | `ElementOptions` | All access levels, generics on, nested types on, all extensions |
| `hideShowCommands` | `[String]?` | `["hide empty members"]` |
| `skinparamCommands` | `[String]?` | `["skinparam shadowing false"]` |
| `includeRemoteURL` | `String?` | `nil` |
| `theme` | `Theme?` | `nil` |
| `relationships` | `RelationshipOptions` | Default labels and styles |
| `stereotypes` | `Stereotypes` | Default spot characters and colors |
| `texts` | `PageTexts?` | `nil` |
| `format` | `DiagramFormat` | `.plantuml` |

```swift
// Built-in defaults
static let `default`: Configuration
```

**Example — Mermaid configuration:**

```swift
var config = Configuration.default
config.format = .mermaid
```

Or via the memberwise initializer:

```swift
let config = Configuration(format: .mermaid)
```

---

### ConfigurationProvider

```swift
public struct ConfigurationProvider
```

Loads a `Configuration` from YAML.

```swift
// Load config from an optional explicit path, falling back to CWD search and defaults
func getConfiguration(for path: String?) -> Configuration

// Look for .swiftumlbridge.yml in the current working directory
func readSwiftConfig() -> Configuration

// Decode a specific YAML file
func decodeYml(config: URL) -> Configuration?

// Default file name and path
var defaultYmlPath: URL     // <CWD>/.swiftumlbridge.yml
var defaultConfig: Configuration
```

Invalid or missing YAML always falls back to `Configuration.default` — it never throws.

---

### FileCollector

```swift
public struct FileCollector
```

Enumerates `.swift` files from paths. Respects `FileOptions` include/exclude globs. Skips hidden files and `.build/` directories.

```swift
// Collect files from paths relative to a directory, applying FileOptions
func getFiles(for paths: [String], in directory: String, honoring fileOptions: FileOptions?) -> [URL]

// Collect files from paths relative to a directory (no filter)
func getFiles(for paths: [String], in directory: String) -> [URL]

// Recursively collect all .swift files under a URL
func getFiles(for url: URL) -> [URL]
```

---

### DiagramScript

```swift
public struct DiagramScript: @unchecked Sendable
```

Builds the complete diagram text from a `[SyntaxStructure]` list and a `Configuration`.

```swift
// Build the script
init(items: [SyntaxStructure], configuration: Configuration)

// The full diagram text (PlantUML or Mermaid depending on configuration.format)
var text: String

// The diagram language
var format: DiagramFormat

// PlantUML URL-encoded form (ZLIB deflate + custom base64). Used for planttext.com URLs.
func encodeText() -> String
```

**PlantUML script structure:**

```
@startuml
[!theme <name>]
[!include <url>]
' STYLE START
hide empty members
skinparam shadowing false
' STYLE END
set namespaceSeparator none
[header/title/legend/caption/footer texts]
[type declarations]
[relationship arrows]
@enduml
```

**Mermaid script structure:**

```
classDiagram
[%% title: ...]
[%% header: ...]
[%% footer: ...]
[type declarations]
[relationship arrows]
```

---

### DiagramPresenting

```swift
public protocol DiagramPresenting: Sendable
```

Implement this protocol to create a custom output target.

```swift
func present(script: DiagramScript) async
```

`ClassDiagramGenerator` calls `await presenter.present(script:)` after generating the script. Both `BrowserPresenter` and `ConsolePresenter` implement this protocol.

**Custom presenter example (file saver):**

```swift
struct FileSaver: DiagramPresenting {
    let url: URL

    func present(script: DiagramScript) async {
        try? script.text.write(to: url, atomically: true, encoding: .utf8)
    }
}
```

**Custom presenter example (format-aware):**

```swift
struct SmartFileSaver: DiagramPresenting {
    let directory: URL

    func present(script: DiagramScript) async {
        let ext = script.format == .mermaid ? "mmd" : "puml"
        let file = directory.appendingPathComponent("diagram.\(ext)")
        try? script.text.write(to: file, atomically: true, encoding: .utf8)
    }
}
```

---

### BrowserPresenter

```swift
public struct BrowserPresenter: DiagramPresenting
```

Opens the diagram in the default macOS browser via `NSWorkspace`. Format-aware: routes PlantUML to planttext.com and Mermaid to mermaid.live.

```swift
// Available render formats (PlantUML only; Mermaid always opens mermaid.live)
public enum BrowserPresentationFormat {
    case `default`    // Interactive planttext.com editor
    case png          // Direct PNG render at planttext.com
    case svg          // Direct SVG render at planttext.com
}

init(format: BrowserPresentationFormat = .default)
```

**URL patterns:**

| `script.format` | `BrowserPresentationFormat` | URL |
|---|---|---|
| `.plantuml` | `.default` | `https://www.planttext.com/?text=<encoded>` |
| `.plantuml` | `.png` | `https://www.planttext.com/api/plantuml/png/<encoded>` |
| `.plantuml` | `.svg` | `https://www.planttext.com/api/plantuml/svg/<encoded>` |
| `.mermaid` | any | `https://mermaid.live/view#base64:<base64json>` |

---

### ConsolePresenter

```swift
public struct ConsolePresenter: DiagramPresenting
```

Prints the raw diagram text to stdout with `print(script.text)`. Works for both PlantUML and Mermaid output.

```swift
init()
```

---

### BridgeLogger

```swift
public final class BridgeLogger
```

Singleton logger backed by `os.Logger`. All messages are logged with `.public` privacy so they appear in Console.app without a configuration profile.

```swift
static let shared: BridgeLogger

func info(_ message: String)
func error(_ message: String)
func warning(_ message: String)
func debug(_ message: String)
```

Subsystem: `name.JosephCursio.SwiftUMLBridge`

---

## Version

```swift
public struct Version {
    public let value: String
    public static let current: Version   // Version(value: "0.1.0")
}
```

The CLI version string. Displayed by `swiftumlbridge --version`.
