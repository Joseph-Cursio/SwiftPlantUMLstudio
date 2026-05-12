# Sample: ER Diagram

Minimal SwiftData schema: `Author` ↔ `Book` with a one-to-many relationship. The `@Relationship` macro annotates the `books` array on `Author` with the inverse keypath, and the `author` property on `Book` is optional (one-to-one back-reference).

## Run

```bash
cd docs/samples/er-diagram
swiftumlbridge er Sources/ --output consoleOnly
```

## What you'll see

Two entities — `Author` and `Book` — connected by a crow's-foot relationship:

- `Author "1" -- "0..*" Book` (one author has many books)
- The `Book.author` property is optional, so the back-reference is `0..1`.

In PlantUML, each entity renders as an `entity` block with its attributes. In Mermaid, each renders as an `erDiagram` entity.

## Try next

Drop in a `.xcdatamodeld` bundle or a GRDB record file to see all four supported stacks coexist in one merged ER diagram. The [User Guide → Generating ER Diagrams](../../user/user-guide.md#generating-er-diagrams) covers the detection rules for SwiftData, Core Data, GRDB, and SQLite.swift.
