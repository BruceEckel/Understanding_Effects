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
