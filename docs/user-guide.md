# SwiftUMLBridge User Guide

SwiftUMLBridge is a command-line tool and Swift Package that generates architectural diagrams (class diagrams, dependency graphs) from Swift source code. It supports PlantUML output today and is designed to add Mermaid.js and sequence diagrams in upcoming milestones.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Generating Class Diagrams](#generating-class-diagrams)
   - [Specifying Input Paths](#specifying-input-paths)
   - [Choosing an Output Mode](#choosing-an-output-mode)
   - [Using an SDK Path](#using-an-sdk-path)
   - [Controlling Extension Display](#controlling-extension-display)
5. [Configuration File](#configuration-file)
   - [File Discovery](#file-discovery)
   - [Overriding Defaults](#overriding-defaults)
6. [Output Modes](#output-modes)
7. [Understanding the Diagram](#understanding-the-diagram)
   - [Element Types](#element-types)
   - [Relationships](#relationships)
   - [Access Level Indicators](#access-level-indicators)
8. [Known Limitations](#known-limitations)
9. [Getting Help](#getting-help)

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

Generate a class diagram from a directory of Swift files and open it in your browser:

```bash
swiftumlbridge classdiagram Sources/
```

This parses every `.swift` file under `Sources/`, produces a PlantUML diagram, and opens it in the interactive [PlantText](https://www.planttext.com) editor in your default browser.

To print the raw PlantUML markup to the terminal instead:

```bash
swiftumlbridge classdiagram Sources/ --output consoleOnly
```

---

## Generating Class Diagrams

The `classdiagram` subcommand is the primary entry point. Because it is also the default subcommand, running `swiftumlbridge` with no verb is equivalent to `swiftumlbridge classdiagram`.

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

### Choosing an Output Mode

The `--output` flag controls where the diagram goes:

| Value | Behavior |
|---|---|
| `browser` | Opens the interactive PlantText editor in your default browser (default) |
| `browserImageOnly` | Opens a direct PNG render from planttext.com in your browser |
| `consoleOnly` | Prints the raw PlantUML markup to stdout |

```bash
# Interactive browser editor (default)
swiftumlbridge classdiagram Sources/ --output browser

# Direct PNG in browser
swiftumlbridge classdiagram Sources/ --output browserImageOnly

# Raw PlantUML to stdout (useful for CI or piping to a file)
swiftumlbridge classdiagram Sources/ --output consoleOnly > diagram.puml
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

## Configuration File

For repeatable, project-specific settings, place a `.swiftumlbridge.yml` file in the root of your project.

**Minimal example:**

```yaml
elements:
  showExtensions: merged
  showMembersWithAccessLevel:
    - public
    - internal
```

**More complete example:**

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
```

### Overriding Defaults

You do not need to include all keys. Any key you omit keeps its built-in default. For example, to only change the theme:

```yaml
theme: hacker
```

---

## Output Modes

### Browser (interactive)

The default mode. The PlantUML markup is encoded and opened as a URL pointing to [planttext.com](https://www.planttext.com). You can edit the diagram interactively in the browser and export it as PNG or SVG.

### Browser (image only)

`--output browserImageOnly` opens a direct image URL (`planttext.com/api/plantuml/png/...`). The image opens immediately with no editor interface.

### Console

`--output consoleOnly` is useful for CI pipelines or when you want to pipe the output to a file or another tool:

```bash
# Save to a file for use with a local PlantUML renderer
swiftumlbridge classdiagram Sources/ --output consoleOnly > diagram.puml

# Render locally if you have PlantUML installed
swiftumlbridge classdiagram Sources/ --output consoleOnly | plantuml -pipe > diagram.png
```

---

## Understanding the Diagram

### Element Types

Each Swift type appears as a PlantUML class node with a stereotype indicating its kind:

| Swift Construct | Stereotype |
|---|---|
| `class` | `<<class>>` |
| `struct` | `<<struct>>` |
| `protocol` | `<<protocol>>` |
| `enum` | `<<enum>>` |
| `extension` | `<<extension>>` |
| `actor` | `<<class>>` (M0 limitation — see Known Limitations) |
| `macro` | Rendered as a PlantUML `note` block |

### Relationships

Arrows between elements represent Swift relationships:

| Arrow | Meaning | Example |
|---|---|---|
| `<\|--` (solid) | Inheritance | `class Dog: Animal` |
| `<\|..` (dashed) | Protocol conformance | `struct User: Codable` |
| `<..` (dotted) | Extension dependency | `extension String: ...` |
| `+--` (composition) | Nested type | `struct Outer { struct Inner {} }` |

### Access Level Indicators

When `showMemberAccessLevelAttribute: true` is set, each member displays a prefix:

| Prefix | Access Level |
|---|---|
| `+` | `open` or `public` |
| `~` | `internal` or `package` |
| `-` | `private` or `fileprivate` |

---

## Known Limitations

These are current M0 constraints scheduled for resolution in M1 (SwiftSyntax integration):

**Actors appear as classes.** SourceKit 6.3 on macOS 26 reports `actor` declarations with kind `source.lang.swift.decl.class`. Actors are included in the diagram but show the `<<class>>` stereotype instead of `<<actor>>`. The internal `ElementKind.actor` case is ready for when SourceKit is updated.

**`async` and `throws` labels are unreliable.** SourceKit's `key.typename` field is the method return type, not the full signature. Annotating methods with `async` and `throws` requires SwiftSyntax (planned for M1).

**Macros parsed as their underlying type.** `@Observable`, `@Bindable`, and similar attribute macros expand to their synthesized type (class/struct), not as `source.lang.swift.decl.macro`. Macro stereotypes are planned for M1.

**PlantUML output only.** Mermaid.js output is planned for M2. Sequence diagrams are planned for M3.

---

## Getting Help

```bash
# Top-level help
swiftumlbridge --help

# Subcommand help
swiftumlbridge classdiagram --help

# Version
swiftumlbridge --version
```

Report issues at the project repository or file a bug in Xcode.
