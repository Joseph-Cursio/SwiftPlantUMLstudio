# SwiftUMLBridge Troubleshooting

Common errors and remediation steps for the `swiftumlbridge` CLI, the `swiftumlbridge-action` GitHub Action, and the SwiftUML Studio macOS app. For the full feature reference, see the [User Guide](user-guide.md) and [Reference](reference.md). For things SwiftUMLBridge intentionally does not do, see [Known Limitations in the User Guide](user-guide.md#known-limitations).

---

## Table of Contents

1. [Installation](#installation)
2. [CLI Errors](#cli-errors)
3. [Diagram Quality](#diagram-quality)
4. [GitHub Actions](#github-actions)
5. [Configuration File](#configuration-file)
6. [SwiftUML Studio App](#swiftuml-studio-app)

---

## Installation

### `brew install swiftumlbridge` fails to compile

The Homebrew formula builds from source. Two requirements must be met on your machine:

- **macOS Sequoia (15) or newer** — the formula gates with `depends_on macos: :sequoia`.
- **Xcode 16+ with the Swift 6.2 toolchain** — required by `SwiftUMLBridge/Package.swift` (`swift-tools-version: 6.2`).

Verify with:

```bash
sw_vers -productVersion         # 15.x or 26.x
xcrun swift --version           # Apple Swift 6.2 or later
```

If `swift --version` reports an older toolchain, set `DEVELOPER_DIR` to a newer Xcode and retry:

```bash
sudo xcode-select -s /Applications/Xcode.app
brew reinstall --build-from-source swiftumlbridge
```

### `swiftumlbridge: command not found` after install

Homebrew installs the binary at `$(brew --prefix)/bin/swiftumlbridge`. Confirm that directory is on `$PATH`:

```bash
echo "$PATH" | tr ':' '\n' | grep -F "$(brew --prefix)/bin"
```

If empty, add Homebrew's bin to your shell profile (`~/.zshrc` for zsh):

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Build-from-source: `error: package manifest cannot be loaded`

Means the toolchain doesn't understand `swift-tools-version: 6.2`. Same fix as above — install Xcode 16+ and re-run `xcode-select -s`.

---

## CLI Errors

### Sequence/Activity diagram is empty

`--entry Type.method` matches your sources exactly and case-sensitively. If the diagram comes out blank, the entry point string did not resolve. Check:

```bash
# Confirm the type and method names exist verbatim
grep -n "func myMethod" Sources/
```

Pass `--depth 1` first to confirm the entry method itself is being found. If depth-1 returns a single participant, the resolver found the entry — increase depth to expand.

### Sequence diagram is full of `Unresolved: foo()` notes

The static call-graph resolver only resolves three patterns:

- `self.method()` — bound to the caller's type
- `TypeName.method()` (uppercase first letter) — bound to that type
- `bareMethod()` (no receiver) — bound to the caller's type

`localVariable.method()` or `parameterName.method()` cannot be resolved without type inference. These calls appear as notes and are not expanded. There is no flag to "fix" this — refactor the call site to one of the three resolvable forms, or accept the notes as documentation of indirection.

### State diagram says "no candidates found"

The state-machine detector requires three signals in your source:

1. An `enum` with **no associated values** (cases are pure states).
2. A property somewhere else typed as that enum.
3. A `switch` against the property that **assigns the property** in one of its arms (`self.state = .next`).

Run with `--list` to see what was found at each confidence level:

```bash
swiftumlbridge state Sources/ --list
```

If a candidate is reported at low/medium confidence, the heuristic found signals 1 and 2 but no switch-driven mutation. Either add an explicit `switch` over the state property, or render the partial machine with `--state HostType.EnumType` anyway.

### `swift package describe failed` from `classdiagram --package` or `component`

The CLI shells out to `swift package describe --type json`. The directory you passed to `--package` must:

- Contain a top-level `Package.swift`.
- Build successfully in isolation — try `swift build --package-path <dir>` first to surface the real error.

### `er` exits with "no entities discovered"

The ER extractor recognizes four stacks (see [User Guide → Generating ER Diagrams](user-guide.md#generating-er-diagrams)). If you run `swiftumlbridge er Sources/` and get an empty result, none of the inputs matched a signal:

- SwiftData expects `@Model` class declarations.
- Core Data expects a `.xcdatamodeld` bundle, not a `.xcdatamodel` file.
- GRDB expects `FetchableRecord` / `PersistableRecord` (or related) conformance.
- SQLite.swift expects `Table("name")` values with `Expression<T>("col")` columns.

If you have a mixed project, point `er` at every relevant root in one invocation — the entities and relationships are merged into a single diagram.

---

## Diagram Quality

### Actors are rendered as `<<class>>` instead of `<<actor>>`

Known SourceKit limitation. SourceKit on macOS 26 reports `actor` declarations as `source.lang.swift.decl.class`. The internal `ElementKind.actor` case is wired up — actors will appear with the correct stereotype as soon as SourceKit reports them distinctly.

### `async` and `throws` are missing from member labels in class diagrams

Class diagram labels come from SourceKit's `key.typename`, which holds the return type only, not the full signature. **Sequence** diagrams *do* detect `await` correctly (via SwiftSyntax) and render async edges distinctly — use a sequence diagram if calling conventions matter.

### Diagram is too busy

In order of impact:

1. `--public-only` (deps, classdiagram via config) — drop internal/private types.
2. `--hide-extensions` or `--merge-extensions` (classdiagram) — strip or fold extensions.
3. `.swiftumlbridge.yml` filters — `elements.exclude` for type patterns, `files.exclude` for paths.
4. `--exclude` flags — same as #3 but ad-hoc.
5. Configure `relationships.inheritance.exclude` to drop noisy protocols like `Codable` / `Hashable`.

### Mermaid component diagram looks like a flowchart, not UML components

Expected. Mermaid has no dedicated component-diagram dialect, so `swiftumlbridge component --format mermaid` emits a `flowchart TD` with one subgraph per component. Use PlantUML output if you need the canonical UML component syntax.

### Deps graph shows a cycle I can't find

The cycle annotation lists every participating node. In PlantUML output, look for the trailing `note as CyclicDependencies` block; in Mermaid, look for `style <Node> fill:#ffcccc` directives. The cycle exists in the directed graph — trace forward from any annotated node and you'll close it within the listed set.

---

## GitHub Actions

### `swiftumlbridge-action` exits 1 with "requires a macOS runner"

The action only runs on macOS — the Bridge depends on SourceKit, which doesn't ship on Linux. Change your job to `runs-on: macos-latest` (or `macos-26` for matching the Studio app's target).

### Smoke test fails: `error: package manifest cannot be loaded` on `macos-latest`

The `macos-latest` runner still ships Xcode pinned to the runner's image, and Swift 6.2 may not be the default toolchain. Add `maxim-lobanov/setup-xcode@v1` to ensure the latest stable Xcode:

```yaml
- uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: latest-stable
- uses: Joseph-Cursio/swiftumlbridge-action@v0.1.0
  with:
    command: classdiagram
    args: Sources --output consoleOnly
```

### First run takes 5-10 minutes; subsequent runs are still slow

The action shallow-clones the SwiftUMLBridge repo at the requested tag and runs `swift build -c release` on a cold cache. Cache hits restore the compiled binary near-instantly. If subsequent runs are also slow, the cache isn't restoring — check the action's logs for the "Restore swiftumlbridge cache" step. The cache key is `swiftumlbridge-v1-<version>-<os>-<arch>`; bumping the `version` input invalidates it.

---

## Configuration File

### `.swiftumlbridge.yml` is not picked up

The CLI looks for the config file in this order:

1. The path passed via `--config <path>`.
2. `.swiftumlbridge.yml` in the **current working directory** (not the `--package` directory, not the directory of the first positional path).
3. Built-in defaults.

If you run `swiftumlbridge` from a parent directory and the config lives elsewhere, pass `--config` explicitly.

### Positional paths are ignored

When `files.include` patterns are defined in the config, they take precedence over positional `<paths>...` arguments. Either remove `files.include`, pass `--config /dev/null` to bypass the config, or update the include patterns.

### YAML parse errors point to "unknown key X"

Yams is strict about top-level structure. Keys you set must match the schema in [Reference → Configuration File Schema](reference.md#configuration-file-schema). Common typos:

- `format` (top level) — not `outputFormat`.
- `elements.showExtensions: merged` — not `mergeExtensions: true`.
- `relationships.inheritance.exclude` — not `excludeInheritance`.

---

## SwiftUML Studio App

### Component Diagram row is grayed out

Component diagrams require a Swift Package context. Use **File → Open Package…** to point Studio at a `Package.swift` directory; the Component row activates once a package is loaded.

### Diagram preview is blank but the source pane shows markup

The preview pipeline differs by format:

- **PlantUML, Nomnoml** — rendered via WebView. Check the in-app log; a missing `nomnoml.js` or `plantuml-encoder.js` indicates a WebKit asset failure (rare).
- **Mermaid** — rendered via WebView with `mermaid.js` loaded from CDN. Blocked network access produces a blank preview.
- **Native SVG / Canvas** (class / sequence / activity / dependency / state / component) — rendered locally. A blank preview here means the layout pass found no nodes, which usually indicates an upstream extraction failure rather than a render bug.

### "Restore Purchases" doesn't reactivate my Pro subscription

Studio reads StoreKit 2 transactions directly. Confirm you're signed into the same Apple ID that purchased the subscription (System Settings → Apple ID → Media & Purchases). If you're using a sandbox/test account, switch to your production Apple ID before invoking Restore.

### Architecture Change Tracking shows no snapshots

Change Tracking compares the current parse against earlier saved snapshots. On a brand-new project there is no baseline, so the tab shows an empty state until you save your first snapshot via **File → Save Snapshot**.

---

## Still stuck?

- Run with `--verbose` to see SourceKit / SwiftSyntax diagnostics on stderr.
- File an issue with the failing command, full output, and the smallest source file that reproduces the problem.
