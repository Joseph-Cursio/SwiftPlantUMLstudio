# Sample: Sequence Diagram

`OrderService.placeOrder()` calls three other methods on itself — one synchronous, one awaited (async), one synchronous. Exercises the static call-graph trace and the async/sync arrow distinction.

## Run

```bash
cd docs/samples/sequence-diagram
swiftumlbridge sequence Sources/ --entry OrderService.placeOrder --output consoleOnly
```

## What you'll see

A single participant `OrderService` with three self-call arrows from `placeOrder`:

| Call | Arrow |
|---|---|
| `validate()` | synchronous |
| `await charge()` | async — distinct arrow (`->>` in PlantUML, `-->>` in Mermaid) |
| `notify()` | synchronous |

## Try next

- `--depth 1` to limit the trace to direct calls.
- `--format mermaid` for `sequenceDiagram` markup.
- Add a class that holds an `OrderService` and calls `placeOrder()` on it, then re-run with `--entry NewType.someMethod` — the variable-receiver call to `placeOrder()` will appear as an `Unresolved` note (see [Troubleshooting → Sequence diagram has Unresolved notes](../../user/troubleshooting.md#sequence-diagram-is-full-of-unresolved-foo-notes)).

See the [sequence-diagram chapter of the User Guide](../../user/user-guide.md#generating-sequence-diagrams) for full coverage.
