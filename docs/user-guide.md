# SwiftUMLBridge User Guide

SwiftUMLBridge is a command-line tool and Swift Package that generates architectural diagrams (class diagrams, dependency graphs) from Swift source code. It supports **PlantUML** and **Mermaid.js** class diagram output, with sequence diagrams planned for upcoming milestones.

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
5. [Configuration File](#configuration-file)
   - [File Discovery](#file-discovery)
   - [Overriding Defaults](#overriding-defaults)
6. [Output Destinations](#output-destinations)
7. [Understanding the Diagram](#understanding-the-diagram)
   - [Element Types](#element-types)
   - [Relationships](#relationships)
   - [Access Level Indicators](#access-level-indicators)
   - [Format Differences](#format-differences)
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

Generate a PlantUML class diagram from a directory of Swift files and open it in your browser:

```bash
swiftumlbridge classdiagram Sources/
```

This parses every `.swift` file under `Sources/`, produces a PlantUML diagram, and opens it in the interactive [PlantText](https://www.planttext.com) editor in your default browser.

Generate a Mermaid diagram and open it in [Mermaid Live](https://mermaid.live) instead:

```bash
swiftumlbridge classdiagram Sources/ --format mermaid
```

To print the raw markup to the terminal:

```bash
# PlantUML
swiftumlbridge classdiagram Sources/ --output consoleOnly

# Mermaid
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly
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
# Save PlantUML to a file for use with a local renderer
swiftumlbridge classdiagram Sources/ --output consoleOnly > diagram.puml

# Render locally if you have PlantUML installed
swiftumlbridge classdiagram Sources/ --output consoleOnly | plantuml -pipe > diagram.png

# Save Mermaid markup
swiftumlbridge classdiagram Sources/ --format mermaid --output consoleOnly > diagram.mmd
```

---

## Understanding the Diagram

### Element Types

Each Swift type appears as a node with a stereotype indicating its kind. The stereotype label is the same in both PlantUML and Mermaid.

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

**Actors appear as classes.** SourceKit 6.3 on macOS 26 reports `actor` declarations with kind `source.lang.swift.decl.class`. Actors are included in the diagram but show the `<<class>>` stereotype instead of `<<actor>>`. The internal `ElementKind.actor` case is ready for when SourceKit is updated.

**`async` and `throws` labels are unreliable.** SourceKit's `key.typename` field is the method return type, not the full signature. Annotating methods with `async` and `throws` requires SwiftSyntax (planned for a future milestone). This affects both PlantUML and Mermaid output.

**Macros parsed as their underlying type.** `@Observable`, `@Bindable`, and similar attribute macros expand to their synthesized type (class/struct), not as `source.lang.swift.decl.macro`. Macro stereotypes are planned for a future milestone.

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
