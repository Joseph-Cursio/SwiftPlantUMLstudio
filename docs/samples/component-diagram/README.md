# Sample: Component Diagram

Three-target SPM package:

- `Core` — leaf utility types (`CoreIdentifier`, `CoreLogger`).
- `Storage` — depends on `Core`; exports `StorageClient`.
- `App` — depends on `Core` and `Storage`; exports `AppRunner`.

The Component subcommand reads the manifest via `swift package describe --type json`, lists each target's public types as provided interfaces, and renders `target_dependencies` as dotted edges.

## Run

```bash
cd docs/samples/component-diagram
swiftumlbridge component --package . --output consoleOnly
```

## What you'll see

Three components arranged in topological levels (top → bottom): `App`, `Storage`, `Core`.

- `App` lists `AppRunner` as a provided interface, with dotted edges to `Core` and `Storage`.
- `Storage` lists `StorageClient`, with a dotted edge to `Core`.
- `Core` lists `CoreIdentifier` and `CoreLogger`; no outgoing edges.

In PlantUML, each component renders with a `«component»` stereotype band. In Mermaid (`--format mermaid`), components render as subgraphs in a `flowchart TD` — Mermaid lacks a dedicated component-diagram dialect.

## Try next

- `--include-test-targets` to include `.testTarget` entries (none in this sample, but exists in larger packages).
- `--format mermaid` to see the flowchart fallback.

See the [component-diagram chapter of the User Guide](../../user/user-guide.md#generating-component-diagrams).
