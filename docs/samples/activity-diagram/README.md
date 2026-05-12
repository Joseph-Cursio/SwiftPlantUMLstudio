# Sample: Activity Diagram

`ImportJob.run()` packs every control-flow construct the activity emitter knows about into a tight method body: a `for` loop, a `do/try/catch` block, an `await` call, and a `switch` with three branches (one returning, one continuing, one throwing).

## Run

```bash
cd docs/samples/activity-diagram
swiftumlbridge activity Sources/ --entry ImportJob.run --output consoleOnly
```

## What you'll see

- A `for` loop wrapping the body of the method.
- A protected `do/catch` block with the `catch` branch wired to `log(_:)`.
- An async step for `await self.attempt(index:)`.
- A three-arm `switch` on `AttemptOutcome` with explicit `return`, `continue`, and `throw` edges.

## Try next

- `--format mermaid` to see Mermaid's flowchart-style activity output.
- Remove the `catch` block and re-run — the protected region disappears and `await` errors become unhandled.

See the [activity-diagram chapter of the User Guide](../../user/user-guide.md#generating-activity-diagrams) for the construct table.
