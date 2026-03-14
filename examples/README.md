# Examples: Overview and Conventions

This directory contains introductory effect examples in four languages,
organized as three progressive tiers.
Each tier adds one new capability over the previous one.

---

## Languages

- **Koka** — native effect system; algebraic effects and handlers
- **Flix** — native effect system; algebraic effects with region-scoped state
- **Scala / ZIO** — library effect system; service interfaces and layers
- **TypeScript / Effect.ts** — library effect system; service tags and layers

---

## Tiers

### hello — Tell only

Files: `koka/hello.kk`, `flix/Hello.flix`, `scala-zio/Hello.scala`, `effect-ts/hello.ts`

One effect: `Tell`. The program prints a fixed string.
The simplest possible demonstration that the effect declaration, the core logic,
and the handler are three separate things.

### welcome — Ask + Tell

Files: `koka/welcome.kk`, `flix/Welcome.flix`, `scala-zio/Welcome.scala`, `effect-ts/welcome.ts`

Two effects: `Ask` and `Tell`. The program asks for the user's name and greets them.
Introduces an effect that returns a value (`Ask` returns a string)
and shows how multiple effects compose.

### session — Ask + Tell + Store + Fetch

Files: `koka/session.kk`, `flix/Session.flix`, `scala-zio/Session.scala`, `effect-ts/session.ts`

Four effects: `Ask`, `Tell`, `Store`, `Fetch`. The program is split across
two logic functions (`inquire` and `greet`) coordinated through a stored ID.
Introduces effects with non-unit return types, mutable state in handlers,
and the separation of program phases.

---

## The Four Effects

| Effect | Signature | Description |
|--------|-----------|-------------|
| `Ask`  | string → string | Takes a prompt; returns a string from a source (console, test stub, etc.) |
| `Tell` | string → unit  | Consumes a string; sends it to a sink (console, log, test capture, etc.) |
| `Store`| string → int   | Stores a string; returns an integer ID |
| `Fetch`| int → string   | Takes an ID; returns the corresponding string |

Because these are effects, the backing implementations are swappable
without changing the core logic. They could be backed by a database,
a file system, a remote API, or a test double.

---

## Logic Functions (session tier)

**`inquire`** — performs `Ask`, `Tell`, and `Store`.
Says hello, asks for the user's name, stores it, and returns the storage ID.

**`greet`** — performs `Fetch` and `Tell`.
Takes the ID returned by `inquire`, fetches the stored name, and greets the user.

---

## Per-Language Conventions

### Koka

- Handler operations use `fun` (auto-resuming) rather than `ctl` (explicit continuation).
- The explicit continuation is named `resume` in `ctl` handlers, but is not needed here.
- Mutable state in handlers uses `var` / `:=`.
- The `session.kk` handler for `store` returns the new counter value directly
  as the last expression in the handler body.

### Flix

- Effect operations are called as `EffectName.operationName(...)`.
- Handler operations receive a `resume` parameter (not `k`) for the continuation.
- `resume()` for unit-returning operations; `resume(value)` for value-returning ones.
- Mutable state uses `region` and `Ref.fresh`.
- `Console.readLine()` returns `Option[String]`; unwrap with `|> Option.getWithDefault("")`.

### Scala / ZIO

- Each effect is a `trait` (service interface) plus a companion `object` with an accessor.
- The accessor uses `ZIO.serviceWithZIO[T]` to lift the service method into a ZIO.
- `Store` and `Fetch` share a `Ref`, so they are built together via `ZLayer.fromZIO`.
- The two logic functions are chained with `.flatMap(greet)` in the entry point.

### TypeScript / Effect.ts

- Each effect is a `Context.Tag` class carrying the service shape as a type parameter.
- Services are resolved inside `Effect.gen` with `yield* Tag`.
- `Effect.async` bridges callback-based APIs (readline) into the Effect world;
  the callback parameter is named `resolve` (not `resume`) to match Promise convention.
- `Store` and `Fetch` share `Ref`s and are built together via `Layer.unwrapEffect`.
- The top-level `program` generator sequences `inquire` and `greet`.
- Three or more layers are combined with `Layer.mergeAll`.

---

## Annotation Blocks

Each file ends with a commented syntax guide.
The guides are progressive: the `hello` files explain all fundamentals from scratch;
the `welcome` files cover only what is new relative to `hello`;
the `session` files cover only what is new relative to `welcome`.

---

## Setup Guides

- `setup-zed.md` — installing toolchains and editor support for Zed
- `setup-vscode.md` — installing toolchains and editor support for Visual Studio Code

Both guides cover all four languages.
Toolchain steps (Node.js, JDK, sbt, flix.jar, tsconfig.json) are identical between them;
only the editor-specific extension steps differ.

---

## Open Questions (`VERIFY` comments)

The following items are marked `<!-- VERIFY: ... -->` in the source files
and have not been confirmed against current language/library versions:

- `koka/session.kk` — whether `var` in a handler requires `<st<h>>` or `<io>` in the effect row rather than `console`
- `flix/Welcome.flix`, `flix/Session.flix` — `Console.print` vs `print`; `Console.readLine` vs `readline`
- `flix/Session.flix` — `Ref.fresh` signature and deref/assignment syntax in current Flix
- `flix/Session.flix` — `Map.getWithDefault` argument order
- `scala-zio/Session.scala` — `Tag[Store & Fetch]` derivation with ZIO 2 / izumi-reflect under Scala 3
- `effect-ts/session.ts` — `Layer.unwrapEffect` signature in current Effect.ts version
- `setup-zed.md`, `setup-vscode.md` — Koka and Flix extension availability in both marketplaces; current Scala 3, ZIO 2, and sbt versions; minimum JDK version for Flix; tsconfig settings for current Effect.ts
