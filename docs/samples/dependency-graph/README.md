# Sample: Dependency Graph

Three source directories under `Sources/` — `Domain`, `Storage`, `App`. With `--modules` mode, each parent directory becomes a module name, and `import` statements become edges between modules.

This sample deliberately includes a **cycle**: `Domain` imports `Storage`, and `Storage` imports `Domain`. Re-run the command and watch the cycle annotation light up.

## Run

```bash
cd docs/samples/dependency-graph
swiftumlbridge deps Sources/ --modules --output consoleOnly
```

## What you'll see

Edges:

- `Domain → Storage`
- `Domain → Foundation`
- `Storage → Domain`
- `Storage → Foundation`
- `App → Domain`
- `App → Storage`
- `App → Foundation`

Plus a cycle annotation listing `Domain` and `Storage` as participating in a cycle:

- PlantUML: a trailing `note as CyclicDependencies` block.
- Mermaid: red `style` directives on the cyclic nodes.

## Try next

- `--exclude Foundation` to drop the system module and focus on your own layering.
- Switch to type-level mode by dropping `--modules` — you'll see structs/classes/protocols instead of module names. (No cycle this time, since there's no type-level circularity.)

See the [dependency-graph chapter of the User Guide](../../user/user-guide.md#generating-dependency-graphs).
