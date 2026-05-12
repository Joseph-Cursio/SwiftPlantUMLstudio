# Sample: Class Diagram

Tiny zoo: a `Greeter` protocol, an `Animal` base class, two subclasses, and an extension on one of them. Exercises every relationship the class-diagram emitter draws — inheritance, conformance, and extensions.

## Run

```bash
cd docs/samples/class-diagram
swiftumlbridge classdiagram Sources/ --output consoleOnly
```

For an interactive render in your browser, drop the `--output` flag:

```bash
swiftumlbridge classdiagram Sources/
```

## What you'll see

- Nodes for `Animal`, `Dog`, `Cat`, `Greeter`, and the `Dog` extension.
- A solid inheritance arrow from `Dog` and `Cat` to `Animal`.
- A dashed conformance arrow from `Dog` and `Cat` to `Greeter`.
- A dotted extension arrow attaching the `Dog` extension (with `fetch()`) to the `Dog` class.

## Try next

- `--format mermaid` to see Mermaid `classDiagram` markup instead.
- `--merge-extensions` to fold the `Dog` extension's members back into the `Dog` node.

See the [class-diagram chapter of the User Guide](../../user/user-guide.md#generating-class-diagrams) for the full set of flags.
