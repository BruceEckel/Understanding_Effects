// Introductory effect example in TypeScript with Effect.ts.
// One effect: Tell.
// The implementation (layer) in runPromise is swappable without changing the logic.

import { Context, Effect, Layer } from "effect"


// --- Service tag ---

class Tell extends Context.Tag("Tell")<
  Tell,
  { tell: (message: string) => Effect.Effect<void> }
>() {}


// --- Core logic ---

const hello = Effect.gen(function* () {
  const tell = yield* Tell
  yield* tell.tell("Hello, World!")
})


// --- Implementation ---

const ConsoleTell = Layer.succeed(Tell, {
  tell: (message) => Effect.sync(() => console.log(message)),
})


// --- Entry point ---

Effect.runPromise(
  hello.pipe(Effect.provide(ConsoleTell)),
)


// =============================================================================
// SYNTAX GUIDE
// =============================================================================
//
// SERVICE TAG
//
//   class Tell extends Context.Tag("Tell")<
//     Tell,
//     { tell: (message: string) => Effect.Effect<void> }
//   >() {}
//
// A service tag names and describes a service. It carries three pieces of
// information: a string identifier ("Tell") used for runtime lookup, the tag
// class itself (first type parameter), and the service shape — the interface
// that any implementation must satisfy (second type parameter). The method
// returns `Effect.Effect<void>`, not void directly. It is a description of
// work, not an immediate action.
//
//
// CORE LOGIC
//
//   const hello = Effect.gen(function* () {
//     const tell = yield* Tell
//     yield* tell.tell("Hello, World!")
//   })
//
// `Effect.gen` creates a generator-based effect computation. Inside it:
//   - `yield* Tell` resolves the Tell service from the environment, binding
//     the concrete implementation to `tell`.
//   - `yield* tell.tell(...)` performs the tell operation, handing control
//     to the runtime to execute that effect.
// Each `yield*` suspends and waits for an effect to complete before continuing.
// `hello` itself is a value — a description. Nothing runs until the runtime
// is told to execute it.
//
//
// LAYER (IMPLEMENTATION)
//
//   const ConsoleTell = Layer.succeed(Tell, {
//     tell: (message) => Effect.sync(() => console.log(message)),
//   })
//
// A Layer provides a concrete implementation of a service. `Layer.succeed`
// takes the tag and an implementation object matching the service shape.
// `Effect.sync(...)` wraps a plain synchronous side effect (console.log) in
// an Effect value, making it safe to compose in the Effect world.
//
//
// ENTRY POINT
//
//   Effect.runPromise(
//     hello.pipe(Effect.provide(ConsoleTell)),
//   )
//
// `Effect.provide(ConsoleTell)` wires the implementation into the description,
// satisfying the Tell requirement. `.pipe(...)` applies a transformation to
// the effect — equivalent to `Effect.provide(hello, ConsoleTell)`.
// `Effect.runPromise` is the boundary between the Effect world and the
// JavaScript runtime: it executes the description and returns a Promise.
