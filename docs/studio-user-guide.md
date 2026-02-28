# SwiftPlantUML Studio — User Guide

SwiftPlantUML Studio is a macOS GUI for [SwiftUMLBridge](../SwiftUMLBridge/), the Swift-native diagram generator. It lets you point at Swift source files or folders, choose a diagram type and output format, and view the rendered diagram — all without touching the terminal.

For CLI usage, see the [SwiftUMLBridge User Guide](user-guide.md).

---

## Table of Contents

1. [Requirements](#requirements)
2. [Window Layout](#window-layout)
3. [Opening Swift Source Files](#opening-swift-source-files)
4. [Choosing a Diagram Mode](#choosing-a-diagram-mode)
5. [Choosing a Diagram Format](#choosing-a-diagram-format)
6. [Generating a Class Diagram](#generating-a-class-diagram)
7. [Generating a Sequence Diagram](#generating-a-sequence-diagram)
   - [Entry Point Syntax](#entry-point-syntax)
   - [Traversal Depth](#traversal-depth)
8. [Reading the Results](#reading-the-results)
9. [Copying the Diagram Markup](#copying-the-diagram-markup)
10. [Known Limitations](#known-limitations)

---

## Requirements

| Requirement | Minimum |
|---|---|
| macOS | 26.4 |
| Xcode (to build the app) | 16.0 |

---

## Window Layout

The app opens at 1100 × 700 points and is split into two panes.

```
┌────────────────────────────────────────────────────────────┐
│  Toolbar                                                   │
│  [Open…] [path label] [Class Diagram|Sequence Diagram]     │
│           [PlantUML|Mermaid]  [Generate]                   │
│  (sequence mode adds: [Type.method field] [Depth stepper]) │
├──────────────────────┬─────────────────────────────────────┤
│                      │                                     │
│   Left pane          │   Right pane                        │
│   Raw diagram text   │   Rendered diagram preview          │
│   (read-only)        │   (web view)                        │
│                      │                                     │
└──────────────────────┴─────────────────────────────────────┘
```

**Left pane** — shows the raw PlantUML or Mermaid markup produced by the generator. Useful for copying into version control or a diagramming tool.

**Right pane** — renders the diagram inside a web view. PlantUML diagrams are fetched as SVG from [planttext.com](https://www.planttext.com); Mermaid diagrams are rendered locally using an embedded [Mermaid.js](https://mermaid.js.org) CDN script.

---

## Opening Swift Source Files

Click **Open…** in the toolbar. A standard Open panel appears with these options:

- **Individual `.swift` files** — select one or more files directly.
- **Folders** — select a directory; the generator searches it recursively for `.swift` files.
- **Mixed selection** — select a combination of files and folders.

After you confirm, the toolbar path label updates to show the selection. If you selected a single item, its filename is shown. If you selected multiple items, the first filename is shown followed by `+ N more`.

To switch to a different set of files, click **Open…** again. The previous selection is replaced.

---

## Choosing a Diagram Mode

The **segmented control** in the toolbar selects the diagram type:

| Mode | What it generates |
|---|---|
| **Class Diagram** | Structural overview of types, properties, methods, and relationships |
| **Sequence Diagram** | Static call-graph trace from a named entry-point method |

Switching modes clears the current diagram and resets the preview pane.

---

## Choosing a Diagram Format

The **PlantUML / Mermaid** segmented control selects the output language. It applies to both diagram modes.

| Format | Preview rendering | Markup extension |
|---|---|---|
| **PlantUML** | SVG fetched from planttext.com (requires internet) | `.puml` |
| **Mermaid** | Rendered locally via Mermaid.js CDN (requires internet for CDN) | `.mmd` |

You can switch formats after generation — click **Generate** again to re-render in the new format.

---

## Generating a Class Diagram

1. Click **Open…** and select Swift files or a folder.
2. Make sure **Class Diagram** is selected in the mode picker.
3. Choose **PlantUML** or **Mermaid** in the format picker.
4. Click **Generate**.

The **Generate** button is disabled until at least one source path is selected. While the generator runs, a progress spinner fills the right pane. Results appear as soon as generation completes.

The left pane displays the raw markup; the right pane renders it as a diagram.

---

## Generating a Sequence Diagram

1. Click **Open…** and select the Swift files or folder that contain the entry-point type.
2. Select **Sequence Diagram** in the mode picker. Two additional controls appear in the toolbar:
   - A **text field** for the entry point.
   - A **depth stepper**.
3. Choose **PlantUML** or **Mermaid**.
4. Type the entry point in the text field (see [Entry Point Syntax](#entry-point-syntax) below).
5. Adjust the depth if needed.
6. Click **Generate**.

If the entry-point field is empty when **Sequence Diagram** mode is active, the right pane shows a reminder: *"Enter an entry point (e.g. MyType.myMethod), then click Generate."*

### Entry Point Syntax

The entry point must be in the form `TypeName.methodName`:

| Example | Meaning |
|---|---|
| `MyService.run` | Method `run` on `MyService` |
| `ClassDiagramGenerator.generateScript` | Method `generateScript` on `ClassDiagramGenerator` |
| `AuthService.login` | Method `login` on `AuthService` |

The names are **case-sensitive** and must exactly match the Swift source code. If no function matches, the diagram will be empty.

The entry point must be `TypeName.methodName` — exactly one dot. A bare function name or a deeply qualified path (e.g., `Module.Type.method`) is not accepted.

### Traversal Depth

The **Depth stepper** controls how many hops to follow from the entry point. The default is **3**; the range is 1–10.

- **Depth 1** — only the direct calls made by the entry method.
- **Depth 3** — entry method + up to 3 levels of callees.
- **Depth 10** — as deep as the call graph goes (each `Type.method` pair is visited at most once, so cycles are safe).

Increase depth if you want to see deeper call chains; decrease it for a focused, high-level overview.

---

## Reading the Results

### Class Diagram

Each Swift type appears as a node. Arrows indicate relationships:

| Arrow | Meaning |
|---|---|
| Solid `<\|--` | Inheritance (`class Dog: Animal`) |
| Dashed `<\|..` | Protocol conformance (`struct User: Codable`) |
| Dotted `<..` | Extension dependency |
| `+--` (PlantUML only) | Nested type |

Stereotypes identify the Swift construct: `<<class>>`, `<<struct>>`, `<<protocol>>`, `<<enum>>`, `<<extension>>`.

### Sequence Diagram

Participants are the types involved in the call chain. Each arrow is a call:

| Arrow | Meaning |
|---|---|
| `->` (PlantUML) / `->>` (Mermaid) | Synchronous call |
| `->>` (PlantUML) / `-->>` (Mermaid) | `await`-prefixed (async) call |

Calls that cannot be resolved statically (e.g., `dependency.doWork()` where `dependency` is a variable) appear as **notes** in the diagram rather than arrows.

---

## Copying the Diagram Markup

The **left pane** contains the raw PlantUML or Mermaid markup. To copy it:

1. Click inside the left pane.
2. Press **⌘A** to select all, then **⌘C** to copy.

You can paste the markup into:
- [planttext.com](https://www.planttext.com) or the PlantUML CLI for PlantUML diagrams.
- [mermaid.live](https://mermaid.live) or any Mermaid-compatible tool for Mermaid diagrams.
- A Markdown file — Mermaid blocks render natively on GitHub and in many editors.

---

## Known Limitations

**Internet connection required for rendering.** PlantUML diagrams are rendered by planttext.com. Mermaid diagrams use Mermaid.js loaded from a CDN. Both require an active internet connection for the right-pane preview. The raw markup in the left pane is always available offline.

**Actors appear as classes.** SourceKit 6.3 on macOS 26 reports `actor` declarations with kind `source.lang.swift.decl.class`. Actor types are included in class diagrams but show the `<<class>>` stereotype.

**`async` and `throws` not shown in class diagrams.** Class diagram member labels omit `async`/`throws` annotations. Sequence diagrams correctly distinguish `await`-wrapped calls with a distinct arrow.

**Variable-receiver calls are unresolved in sequence diagrams.** `dep.doWork()` where `dep` is a local variable or parameter cannot be resolved statically. Such calls appear as notes in the diagram and are not expanded further.

**No configuration file support in the GUI.** The GUI uses built-in defaults. Project-level `.swiftumlbridge.yml` settings (custom access levels, themes, extension display, etc.) are not applied. Use the CLI for configuration-file-driven generation.
