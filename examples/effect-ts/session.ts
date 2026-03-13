// Session effect example in TypeScript with Effect.ts.
// Four effects: Ask, Tell, Store, Fetch.
// The implementations (layers) in runPromise are swappable without changing the logic.

import { Context, Effect, Layer, Ref } from "effect"
import * as readline from "node:readline"
import * as process from "node:process"


// --- Service tags ---

class Ask extends Context.Tag("Ask")<
  Ask,
  { ask: (prompt: string) => Effect.Effect<string> }
>() {}

class Tell extends Context.Tag("Tell")<
  Tell,
  { tell: (message: string) => Effect.Effect<void> }
>() {}

class Store extends Context.Tag("Store")<
  Store,
  { store: (value: string) => Effect.Effect<number> }
>() {}

class Fetch extends Context.Tag("Fetch")<
  Fetch,
  { fetch: (id: number) => Effect.Effect<string> }
>() {}


// --- Core logic ---

const inquire = Effect.gen(function* () {
  const ask   = yield* Ask
  const tell  = yield* Tell
  const store = yield* Store
  yield* tell.tell("Hello!")
  const name = yield* ask.ask("What is your name? ")
  return yield* store.store(name)
})

const greet = (id: number) =>
  Effect.gen(function* () {
    const fetch = yield* Fetch
    const tell  = yield* Tell
    const name  = yield* fetch.fetch(id)
    yield* tell.tell(`Hello, ${name}!`)
  })


// --- Implementations ---

const ConsoleTell = Layer.succeed(Tell, {
  tell: (message) => Effect.sync(() => console.log(message)),
})

const ConsoleAsk = Layer.succeed(Ask, {
  ask: (prompt) =>
    Effect.async<string>((resolve) => {
      const rl = readline.createInterface({
        input:  process.stdin,
        output: process.stdout,
      })
      rl.question(prompt, (answer) => {
        rl.close()
        resolve(Effect.succeed(answer))
      })
    }),
})

// Store and Fetch share Refs, so they are built together inside a single Effect
// then wrapped in a Layer via Layer.unwrapEffect.
// VERIFY: Layer.unwrapEffect signature in current Effect.ts version
const MemoryLayer: Layer.Layer<Store | Fetch> = Layer.unwrapEffect(
  Effect.gen(function* () {
    const db      = yield* Ref.make(new Map<number, string>())
    const counter = yield* Ref.make(0)

    const storeLayer = Layer.succeed(Store, {
      store: (value: string) =>
        Effect.gen(function* () {
          const id = yield* Ref.updateAndGet(counter, (n) => n + 1)
          yield* Ref.update(db, (map) => new Map([...map, [id, value]]))
          return id
        }),
    })

    const fetchLayer = Layer.succeed(Fetch, {
      fetch: (id: number) =>
        Ref.get(db).pipe(Effect.map((map) => map.get(id) ?? "")),
    })

    return Layer.merge(storeLayer, fetchLayer)
  }),
)


// --- Entry point ---

const program = Effect.gen(function* () {
  const id = yield* inquire
  yield* greet(id)
})

Effect.runPromise(
  program.pipe(Effect.provide(Layer.mergeAll(ConsoleTell, ConsoleAsk, MemoryLayer))),
)


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// TWO SEPARATE EFFECT.GEN FUNCTIONS
//
//   const inquire = Effect.gen(function* () { ... })
//   const greet = (id: number) => Effect.gen(function* () { ... })
//
// `inquire` is a plain Effect value. `greet` is a function that returns an
// Effect — it takes the id produced by `inquire` and uses it to fetch the
// name. Each resolves only the services it needs.
//
//
// MUTABLE REFERENCES WITH Ref
//
//   const db      = yield* Ref.make(new Map<number, string>())
//   const counter = yield* Ref.make(0)
//
// `Ref.make(initial)` creates an Effect-managed mutable reference. All reads
// and writes are themselves effects, so the runtime controls all access.
//
//   yield* Ref.updateAndGet(counter, (n) => n + 1)
//     // atomically increment counter, return new value
//
//   yield* Ref.update(db, (map) => new Map([...map, [id, value]]))
//     // atomically add an entry to the map
//
//   Ref.get(db).pipe(Effect.map((map) => map.get(id) ?? ""))
//     // read the map, then transform the result; ?? "" supplies a default
//
//
// BUILDING A LAYER WITH INITIALIZATION
//
//   const MemoryLayer: Layer.Layer<Store | Fetch> = Layer.unwrapEffect(
//     Effect.gen(function* () {
//       ...
//       return Layer.merge(storeLayer, fetchLayer)
//     })
//   )
//
// `Layer.unwrapEffect` takes an Effect that produces a Layer and flattens it
// into a Layer. This is how you build layers that need initialization (here:
// allocating Refs). The inner Effect.gen creates the Refs and constructs two
// inner layers that close over them; `Layer.merge` combines Store and Fetch
// since they share the same Refs.
//
//
// SEQUENCING AT THE TOP LEVEL
//
//   const program = Effect.gen(function* () {
//     const id = yield* inquire
//     yield* greet(id)
//   })
//
// A top-level `program` generator sequences `inquire` and `greet`. The id
// returned by `inquire` is passed directly to `greet(id)`.
//
//
// PROVIDING ALL LAYERS AT ONCE
//
//   program.pipe(Effect.provide(Layer.mergeAll(ConsoleTell, ConsoleAsk, MemoryLayer)))
//
// `Layer.mergeAll` combines three or more layers in one call, rather than
// nesting `Layer.merge` calls.
