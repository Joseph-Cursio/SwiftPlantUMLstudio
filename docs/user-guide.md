# SwiftUMLBridge User Guide

SwiftUMLBridge is a command-line tool and Swift Package that generates architectural diagrams from Swift source code. It supports **PlantUML** and **Mermaid.js** output for two diagram types:

- **Class diagrams** — structural overview of types, members, and relationships (M0–M2)
- **Sequence diagrams** — static call-graph traces from a named entry-point method (M3)

---

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Generating Class Diagrams](#generating-class-diagrams)
   - [Specifying Input Paths](#specifying-input-paths)
   - [Choosing a Diagram Format](#choosing-a-diagram-format)
   - [Choosing an Output Destination](#choosing-an-output-destination)
   - [Using an SDK Path](#using-an-sdk-path)
   - [Controlling Extension Display](#controlling-extension-display)
5. [Generating Sequence Diagrams](#generating-sequence-diagrams)
   - [Entry Point Syntax](#entry-point-syntax)
   - [Controlling Traversal Depth](#controlling-traversal-depth)
   - [How Calls Are Resolved](#how-calls-are-resolved)
   - [Async Calls](#async-calls)
   - [Unresolved Calls](#unresolved-calls)
6. [Configuration File](#configuration-file)
   - [File Discovery](#file-discovery)
   - [Overriding Defaults](#overriding-defaults)
7. [Output Destinations](#output-destinations)
8. [Understanding Class Diagrams](#understanding-class-diagrams)
   - [Element Types](#element-types)
   - [Relationships](#relationships)
   - [Access Level Indicators](#access-level-indicators)
   - [Format Differences](#format-differences)
9. [Known Limitations](#known-limitations)
10. [Getting Help](#getting-help)

---

## Requirements

| Requirement | Minimum Version |
|---|---|
| macOS | 13.0 (Ventura) |
| Xcode | 15.0 |
| Swift | 5.9 |
| Swift toolchain | Current or one prior major release |

---

## Installation

SwiftUMLBridge is distributed as a local Swift Package inside the SwiftPlantUMLstudio project.

**Build the CLI from source:**

```bash
cd /path/to/SwiftPlantUMLstudio/SwiftUMLBridge
swift build -c release
```

The compiled binary is at `.build/release/swiftumlbridge`. Copy it to a location on your `$PATH`:

```bash
cp .build/release/swiftumlbridge /usr/local/bin/swiftumlbridge
```

**Verify the installation:**

```bash
swiftumlbridge --version
# 0.1.0
```

---

## Quick Start

**Class diagram** — parse Swift files and open in your browser:

```bash
swiftumlbridge classdiagram Sources/
```

**Class diagram, Mermaid format:**

```bash
swiftumlbridge classdiagram Sources/ --format mermaid
```

**Sequence diagram** — trace calls from an entry point:

```bash
swiftumlbridge sequence Sources/ --entry MyService.process
```

**Sequence diagram, Mermaid, printed to stdout:**

```bash
swiftumlbridge sequence Sources/ --entry MyService.process \
  --format mermaid --output consoleOnly
```

---

## Generating Class Diagrams

The `classdiagram` subcommand is the primary entry point for structural diagrams. Because it is also the default subcommand, running `swiftumlbridge` with no verb is equivalent to `swiftumlbridge classdiagram`.

```
swiftumlbridge classdiagram [<paths>...] [options]
```

### Specifying Input Paths

Pass one or more paths as positional arguments. Paths may be individual `.swift` files or directories — directories are searched recursively.

```bash
# Single directory
swiftumlbridge classdiagram Sources/

# Multiple directories
swiftumlbridge classdiagram Sources/ Tests/

# Specific files
swiftumlbridge classdiagram Sources/MyApp/Models/User.swift Sources/MyApp/Models/Account.swift

# Current directory (default when no paths are given)
swiftumlbridge classdiagram
```

When a `.swiftumlbridge.yml` configuration file includes `files.include` patterns, those patterns take precedence over the positional path arguments. See [Configuration File](#configuration-file).

**Excluding files:**

Use `--exclude` to skip specific files or directories. The `--exclude` flag takes precedence over positional arguments:

```bash
swiftumlbridge classdiagram Sources/ --exclude Sources/Generated/
```

Multiple `--exclude` values are supported:

```bash
swiftumlbridge classdiagram Sources/ --exclude Sources/Generated/ --exclude Sources/Stubs/
```

### Choosing a Diagram Format

The `--format` flag selects the diagram language. It overrides the `format` key in the config file.

| Value | Output language | Browser destination |
|---|---|---|
| `plantuml` | PlantUML class diagram (default) | [planttext.com](https://www.planttext.com) |
| `mermaid` | Mermaid.js class diagram | [mermaid.live](https://mermaid.live) |

```bash
# PlantUML (default — equivalent to --format plantuml)
swiftumlbridge classdiagram Sources/

# Mermaid
swiftumlbridge classdiagram Sources/ --format mermaid

# Mermaid, raw markup to stdout
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly

# Persist the format preference in the config file
echo "format: mermaid" >> .swiftumlbridge.yml
```

### Choosing an Output Destination

The `--output` flag controls where the diagram goes, regardless of format:

| Value | Behavior |
|---|---|
| `browser` | Opens the diagram editor in your default browser (default) |
| `browserImageOnly` | For PlantUML: opens a direct PNG render. For Mermaid: same as `browser`. |
| `consoleOnly` | Prints the raw markup to stdout |

```bash
# Interactive browser editor (default)
swiftumlbridge classdiagram Sources/ --output browser

# Direct PNG in browser (PlantUML)
swiftumlbridge classdiagram Sources/ --output browserImageOnly

# Raw markup to stdout (useful for CI or piping to a file)
swiftumlbridge classdiagram Sources/ --output consoleOnly > diagram.puml
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly > diagram.mmd
```

### Using an SDK Path

For accurate type inference, pass the macOS SDK path with `--sdk`. This enables SourceKitten's `SwiftDocs` mode, which resolves types against the SDK.

```bash
swiftumlbridge classdiagram Sources/ \
  --sdk "$(xcrun --show-sdk-path -sdk macosx)"
```

### Controlling Extension Display

Extensions are shown as separate nodes by default. Three flags change this behavior:

| Flag | Effect |
|---|---|
| `--show-extensions` | Show each extension as a separate node (default) |
| `--merge-extensions` | Fold extension members back into the parent type node |
| `--hide-extensions` | Remove all extensions from the diagram |

```bash
# Cleaner diagram with extension members merged into parent types
swiftumlbridge classdiagram Sources/ --merge-extensions

# Strip all extensions for a minimal overview
swiftumlbridge classdiagram Sources/ --hide-extensions
```

These flags override the `elements.showExtensions` setting in the configuration file.

---

## Generating Sequence Diagrams

The `sequence` subcommand traces a static call graph from a named Swift method and renders it as a sequence diagram.

```
swiftumlbridge sequence [<paths>...] --entry Type.method [options]
```

SwiftSyntax is used to parse function bodies — this gives access to actual call sites inside method implementations, which SourceKitten alone cannot provide.

### Entry Point Syntax

`--entry` is required and takes the form `TypeName.methodName`:

```bash
# Trace ClassDiagramGenerator.generateScript
swiftumlbridge sequence Sources/ --entry ClassDiagramGenerator.generateScript

# Trace AuthService.login
swiftumlbridge sequence Sources/ --entry AuthService.login

# Trace across multiple directories
swiftumlbridge sequence Sources/ Tests/ --entry DataPipeline.run
```

The type and method names are case-sensitive and must exactly match the Swift source code. If no functions match, `SequenceScript.empty` is returned and the diagram is blank.

### Controlling Traversal Depth

`--depth` sets the maximum number of hops to follow from the entry point. Default is `3`.

```bash
# Shallow trace — only direct calls from the entry method
swiftumlbridge sequence Sources/ --entry MyService.run --depth 1

# Deeper trace
swiftumlbridge sequence Sources/ --entry MyService.run --depth 6
```

Each `Type.method` pair is visited at most once regardless of depth, so cycles in the call graph are safe.

### How Calls Are Resolved

The extractor analyzes each `FunctionCallExprSyntax` node found in a function body. Resolution is static and pattern-based:

| Call pattern | Resolution |
|---|---|
| `self.method()` | Resolved — same type as caller |
| `TypeName.method()` (uppercase first letter) | Resolved — `TypeName` |
| `bareMethod()` (no receiver) | Resolved — same type as caller |
| `variable.method()` (lowercase first letter) | Unresolved — emitted as a note |
| Closure call or complex expression | Unresolved — emitted as a note |

Calls inside free functions (not inside a type declaration) are skipped — there is no `callerType` to assign to them.

### Async Calls

When a call expression is wrapped in `await`, it is marked `isAsync = true` and rendered with a distinct arrow:

| Format | Sync arrow | Async arrow |
|---|---|---|
| PlantUML | `->` | `->>` |
| Mermaid | `->>` | `-->>` |

```swift
// Source — detected as async
func process() async {
    await self.flush()       // isAsync = true
    self.log("done")         // isAsync = false
}
```

### Unresolved Calls

When a call cannot be resolved statically, it is included in the diagram as a note rather than an arrow, and its callees are not explored further:

**PlantUML:**
```
note right: Unresolved: completion()
```

**Mermaid:**
```
Note right of LastParticipant: Unresolved: completion()
```

This keeps the diagram honest about what is and is not known statically.

---

## Configuration File

For repeatable, project-specific settings, place a `.swiftumlbridge.yml` file in the root of your project. The `format` key applies to both `classdiagram` and `sequence`. All other keys are class-diagram–specific and are silently ignored by `sequence`.

**Minimal example:**

```yaml
elements:
  showExtensions: merged
  showMembersWithAccessLevel:
    - public
    - internal
```

**Mermaid-first project:**

```yaml
format: mermaid

elements:
  havingAccessLevel:
    - public
    - internal
  showMembersWithAccessLevel:
    - public
  showMemberAccessLevelAttribute: true
```

**Full PlantUML example:**

```yaml
files:
  include:
    - "Sources/**/*.swift"
  exclude:
    - "Sources/Generated/**"

elements:
  havingAccessLevel:
    - public
    - internal
  showMembersWithAccessLevel:
    - public
  showMemberAccessLevelAttribute: true
  showGenerics: true
  showNestedTypes: true
  showExtensions: merged

hideShowCommands:
  - "hide empty members"

skinparamCommands:
  - "skinparam shadowing false"

theme: hacker

relationships:
  inheritance:
    label: "inherits from"
    exclude:
      - "Codable"
      - "Hashable"
  realize:
    label: "conforms to"

texts:
  title: "My Architecture"
  footer: "Generated by swiftumlbridge"
```

See the [Reference Guide](reference.md) for the full YAML schema.

### File Discovery

The configuration file is located in this order:

1. The path passed via `--config <path>`
2. `.swiftumlbridge.yml` in the current working directory
3. Built-in defaults (no file required)

```bash
# Explicit config path
swiftumlbridge classdiagram Sources/ --config ./configs/diagram.yml
swiftumlbridge sequence Sources/ --entry MyService.run --config ./configs/diagram.yml
```

### Overriding Defaults

You do not need to include all keys. Any key you omit keeps its built-in default. For example, to only set the diagram format:

```yaml
format: mermaid
```

---

## Output Destinations

### Browser (interactive)

The default mode. For PlantUML, the markup is encoded and opened at [planttext.com](https://www.planttext.com). For Mermaid, the script is base64-encoded and opened at [mermaid.live](https://mermaid.live). Both editors let you view and export the diagram.

### Browser (image only)

`--output browserImageOnly` opens a direct PNG render from planttext.com for PlantUML diagrams. For Mermaid, this behaves identically to `browser`.

### Console

`--output consoleOnly` is useful for CI pipelines or when you want to pipe the output to a file or another tool:

```bash
# Save PlantUML class diagram to a file
swiftumlbridge classdiagram Sources/ --output consoleOnly > class-diagram.puml

# Save Mermaid class diagram
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly > class-diagram.mmd

# Save PlantUML sequence diagram
swiftumlbridge sequence Sources/ --entry MyService.run --output consoleOnly > sequence.puml

# Save Mermaid sequence diagram
swiftumlbridge sequence Sources/ --entry MyService.run \
  --format mermaid --output consoleOnly > sequence.mmd

# Render PlantUML locally if you have PlantUML installed
swiftumlbridge classdiagram Sources/ --output consoleOnly | plantuml -pipe > diagram.png
```

---

## Understanding Class Diagrams

### Element Types

Each Swift type appears as a node with a stereotype indicating its kind.

| Swift Construct | Stereotype | PlantUML node | Mermaid node |
|---|---|---|---|
| `class` | `<<class>>` | `class "Name" as Alias <<(C,color)>>` | `class Alias["Name"] { <<class>> }` |
| `struct` | `<<struct>>` | `class "Name" as Alias <<(S,color) struct>>` | `class Alias["Name"] { <<struct>> }` |
| `protocol` | `<<protocol>>` | `class "Name" as Alias <<(P,color) protocol>>` | `class Alias["Name"] { <<protocol>> }` |
| `enum` | `<<enum>>` | `class "Name" as Alias <<(E,color) enum>>` | `class Alias["Name"] { <<enum>> }` |
| `extension` | `<<extension>>` | `class "Name" as Alias <<(X,color) extension>>` | `class Alias["Name"] { <<extension>> }` |
| `actor` | `<<class>>` (limitation) | Same as class | Same as class |
| `macro` | — | `note as Name ...` | `%% macro: Name` comment |

### Relationships

Arrows between elements represent Swift relationships. The same arrow notation is used in both PlantUML and Mermaid output.

| Arrow | Meaning | Example |
|---|---|---|
| `<\|--` (solid) | Inheritance | `class Dog: Animal` |
| `<\|..` (dashed) | Protocol conformance | `struct User: Codable` |
| `<..` (dotted) | Extension dependency | `extension String: ...` |
| `+--` (composition) | Nested type **(PlantUML only)** | `struct Outer { struct Inner {} }` |

### Access Level Indicators

When `showMemberAccessLevelAttribute: true` is set, each member displays a prefix. The same symbols are used in both PlantUML and Mermaid.

| Prefix | Access Level |
|---|---|
| `+` | `open` or `public` |
| `~` | `internal` or `package` |
| `-` | `private` or `fileprivate` |

### Format Differences

A few things render differently between PlantUML and Mermaid:

| Feature | PlantUML | Mermaid |
|---|---|---|
| Member variable format | `name : Type` | `Type name` |
| Static members | `{static} name` | `name$` suffix |
| Nested types | `Outer +-- Inner` connection | Not rendered |
| Macros | `note` block | `%% macro:` comment |
| Page texts | `title`/`header`/`footer`/`legend`/`caption` blocks | `%% title:`/`header:`/`footer:` comments only |
| Visual styling | Themes, skinparam, line colors | Not applicable |

---

## Known Limitations

**Actors appear as classes.** SourceKit 6.3 on macOS 26 reports `actor` declarations with kind `source.lang.swift.decl.class`. Actors are included in class diagrams but show the `<<class>>` stereotype instead of `<<actor>>`. The internal `ElementKind.actor` case is ready for when SourceKit is updated.

**`async` and `throws` labels are not shown in class diagrams.** SourceKit's `key.typename` field is the method return type, not the full signature. Class diagram member labels do not include `async` or `throws` annotations. Note: the sequence diagram extractor _does_ correctly detect `await`-wrapped calls using SwiftSyntax, so async calls are distinguished in sequence diagrams.

**Macros parsed as their underlying type in class diagrams.** `@Observable`, `@Bindable`, and similar attribute macros expand to their synthesized type (class/struct), not as `source.lang.swift.decl.macro`.

**Sequence diagram: variable-receiver calls are unresolved.** `dep.doWork()` where `dep` is a local variable or parameter cannot be statically resolved. These calls appear as notes (`Unresolved: doWork()`) and are not expanded further. Only `self.x()`, `TypeName.x()`, and bare `x()` calls are resolved.

**Sequence diagram: entry point must exist.** If no function matches `TypeName.methodName` exactly in the parsed sources, the diagram is empty.

---

## Getting Help

```bash
# Top-level help
swiftumlbridge --help

# Subcommand help
swiftumlbridge classdiagram --help
swiftumlbridge sequence --help

# Version
swiftumlbridge --version
```

Report issues at the project repository or file a bug in Xcode.
