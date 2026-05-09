# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This file covers both the **SwiftUMLBridge** package (CLI + framework) and the **SwiftUMLStudio** macOS app.

---

## [Unreleased] — preparing 1.0.0

### Added — Diagram Types

- **Dependency graphs (M4)** — `swiftumlbridge deps` CLI command with `--modules`, `--types`, `--public-only`, `--exclude`; module-level and type-level dependency analysis with cycle detection; PlantUML and Mermaid emitters
- **Activity diagrams (M5)** — `swiftumlbridge activity` CLI; control-flow extraction from imperative function bodies (branches, loops, `switch`, `do/catch`); native SVG renderer
- **State machine diagrams (M6)** — `swiftumlbridge state` CLI; enum-driven state machine detection with confidence scoring, where-clause guards, property-wrapper enum inference; PlantUML, Mermaid, and SVG emitters
- **Entity-Relationship diagrams (M7)** — `swiftumlbridge er` CLI; SwiftData `@Model` and `@Relationship` extraction; PlantUML entity and Mermaid `erDiagram` emitters

### Added — Output Formats

- **Nomnoml** class diagram emitter with locally bundled JS for offline rendering
- **Native SVG** format with Dagre layout via JavaScriptCore (Phase D), plus a SwiftUI `Canvas` renderer for in-app display

### Added — Parsing

- **SwiftSyntax-primary parser (M5)** — replaces SourceKitten as the primary AST source for newer functionality; SourceKitten retained for declarations
- **Macro-aware stereotypes** — `MacroConformanceTable` maps macros (`@Observable`, `@Model`, etc.) to synthetic conformances surfaced in diagrams
- Attribute fields exposed on `SyntaxStructure` for macro-aware diagrams

### Added — Diagram Interaction

- **Unified `DiagramViewport`** shared by the class, sequence, and activity native canvases — replaces three duplicated copies of scale/offset state
- **Floating zoom toolbar** (top-trailing): zoom in / zoom out / fit-to-window / actual size / reset, with a live percent label and standard mac shortcuts (⌘= ⌘− ⌘9 ⌘0 ⇧⌘R)
- **Single-click node selection** on class diagrams — selected node is drawn with an accent-colored ring; clicking the canvas background clears the selection
- **`SourceLocation` on `LayoutNode`** — public framework type carrying file path + 1-based line/column, populated by `SyntaxStructureBuilder` from a SwiftSyntax `SourceLocationConverter` for class / struct / enum / actor / protocol / extension declarations
- **"Reveal in Source"** floating button (⌘J) — when a node with a known `sourceLocation` is selected, opens the file in the developer-layout source pane, scrolls to the line, and highlights it in yellow
- **`SourceEditorView` rewritten** as an `NSViewRepresentable` around `NSTextView` to support line scrolling and back-fill highlighting (replaces the previous disabled `TextEditor`)

### Added — Studio App

- **Three app modes** (`AppMode`): Document, Explorer, Project — with mode-switching toolbar
- **Project Dashboard** (`ProjectDashboardView`) with stats, insights, and one-click suggestion cards
- **InsightEngine** — plain-language project insights derived from `ProjectAnalyzer`
- **SuggestionEngine** + `SuggestionDispatcher` — actionable diagram suggestions with confidence scoring
- **Explorer Mode** — simplified UI for non-developer users (`ExplorerSidebar`, `ExplorerToolbar`, `ExplorerDetailView`)
- **Pro subscription tier** (StoreKit 2) — `SubscriptionManager`, `SubscriptionProviding`, `FeatureGate`, `PaywallView`, `ReviewReminderManager`, `Configuration.storekit`
- **Architecture Change Tracking (Phase 4)** — diff view comparing snapshots over time for Pro subscribers (`ArchitectureDiffView`, `ProjectSnapshot`, `SnapshotManager`)
- **3-pane NavigationSplitView** layout with sidebar / detail / inspector
- **History sidebar** with diagram restoration and entry-point menu
- **File browser sidebar** with tabbed preview
- **Live-updating preview** with explicit save action
- **MarkupView** annotation overlay tied to diagram entities
- **Inspector strip** + per-mode controls (`SequenceControlsView`, `ActivityControlsView`)

### Added — Tests & Quality

- ViewInspector test coverage for `ProjectDashboardView`, `ArchitectureDiffView`, `PaywallView`, `DiagramPreviewView`, `HistoryItemRow`, `SnapshotRowView`, `MarkupView`
- Geometry helpers extracted from `NativeDiagramView` and `NativeSequenceDiagramView` for unit-testable layout
- Protocol abstractions (`DiagramGenerating` family, `SubscriptionProviding`) for dependency-injected testing
- SampleProject fixture enriched for state-machine and sequence-diagram coverage
- 89% test coverage on the Bridge package, 70%+ on the Studio app

### Changed

- **Project rename**: `SwiftPlantUMLstudio` → `SwiftUMLStudio` (working dir, GitHub repo, all targets)
- **Migrated persistence from Core Data to SwiftData** (`PersistenceController`, `DiagramEntity`, `ProjectSnapshot`)
- Modernized to macOS 26 `Tab` API in detail pane (replacing deprecated `tabItem()`)
- Moved project analysis off the main actor to avoid UI blocking
- Switched `Task.sleep` to `Duration`-based API
- Async/await for notification authorization request
- PRD revised to v1.2 covering both Bridge and Studio as first-class products
- CLAUDE.md refreshed to reflect post-M10 state (six diagram types, Swift 6 strict concurrency, Studio architecture)

### Fixed

- Sequence diagram regeneration bug from file-browser sidebar
- `@MainActor` test hangs and Core Data crashes on macOS 26 beta
- DiagramEntity crash; toolbar overflow on small windows
- Empty-paths crash in `ProjectAnalyzer`
- Test isolation issues (UserDefaults injection, removed no-op `.serialized`)
- All SwiftLint violations (multiple cleanup passes — final state: zero warnings, zero errors)
- Accessibility labels and deprecated APIs in native Canvas views
- Stale `ProFeatureTests` and `DiagramModeTests` after enum cases were added

### Removed

- Obsolete plan docs from earlier phases

---

## [0.2.0] — 2026-02-28

### Added

- **M2 — Mermaid.js class diagram output** — first-class Mermaid emitter alongside PlantUML
- **M3 — Sequence diagrams** — static call-graph extraction (`CallGraphExtractor`) and `SequenceDiagramGenerator` with PlantUML and Mermaid emitters; `--depth` and `--entry` CLI flags
- Studio user guide
- GitHub README

### Changed

- Eliminated all force unwraps and `@unchecked Sendable` annotations from the parsing and emitter layers

### Fixed

- SwiftLint violations across the SwiftUMLBridge package

---

## [0.1.0] — 2026-02-27

### Added

- SwiftUMLBridge local Swift package (M0): three-layer parsing/model/emitter architecture powered by SourceKitten, swift-argument-parser, and Yams
- `swiftumlbridge classdiagram` CLI command with `--format`, `--output`, `--sdk`, and `--exclude` options
- `BridgeLogger` singleton wrapping `os.Logger` (replaces SwiftyBeaver)
- macOS SwiftUI studio front-end (M1): file picker, PlantUML preview via planttext.com WebView, toolbar Generate button
- User guide, tutorial, and reference documentation in `docs/`
- Test suite raising SwiftUMLBridge framework coverage from 35% to 89% (229 tests)

### Changed

- **Swift 6 strict concurrency** (`846adfa`):
  - Enabled `swiftLanguageMode(.v6)` in `Package.swift` and `SWIFT_VERSION = 6.0` in the Xcode project for all targets
  - `DiagramPresenting` protocol replaced callback-based `present(script:completionHandler:)` with `async func present(script:)` and added `Sendable` conformance
  - `ClassDiagramGenerator.generate()` methods are now `async`; `DispatchSemaphore`-based `outputDiagram()` removed
  - New public `ClassDiagramGenerator.generateScript(for paths: [String], ...)` synchronous method as the GUI integration point
  - `BrowserPresenter.present()` wraps `NSWorkspace.shared.open()` in `await MainActor.run {}`
  - `BridgeLogger.shared` changed from `var` to `let`; class marked `@unchecked Sendable`
  - `DiagramScript` and `SyntaxStructure` marked `@unchecked Sendable`
  - Full `Sendable` conformance added to all model value types: `Color`, `Theme`, `Version`, `Stereotype`/`Stereotypes`/`Spot`, `Configuration`, `AccessLevel`, `ExtensionVisualization`, `RelationshipInlineStyle`, `RelationshipStyle`, `Relationship`, `RelationshipOptions`, `FileOptions`, `ElementOptions`, `PageTexts`
  - Static mutable singletons and collections converted from `var` to `let`
  - `ClassDiagramCommand` and `SwiftUMLBridgeCLI` migrated to `AsyncParsableCommand`
  - App `DiagramViewModel` replaced GCD + `SwiftUIPresenter` with `Task { await Task.detached { }.value }`
- `Color` enum cases converted to camelCase
- Yams dependency bumped from 5.0.0 to 6.0.0

### Removed

- `SwiftUIPresenter.swift` — no longer needed after async protocol migration
- `outputDiagram(for:with:processingStartDate:)` internal method on `ClassDiagramGenerator`
- All `DispatchSemaphore` usage

### Fixed

- All SwiftLint violations resolved at project inception
