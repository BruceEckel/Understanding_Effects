// Welcome effect example in TypeScript with Effect.ts.
// Two effects: Ask and Tell.
// The implementations (layers) in runPromise are swappable without changing the logic.

import { Context, Effect, Layer } from "effect"
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


// --- Core logic ---

const greet = Effect.gen(function* () {
  const ask  = yield* Ask
  const tell = yield* Tell
  const name = yield* ask.ask("What is your name? ")
  yield* tell.tell(`Hello, ${name}!`)
})


// --- Implementations ---

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

const ConsoleTell = Layer.succeed(Tell, {
  tell: (message) => Effect.sync(() => console.log(message)),
})


// --- Entry point ---

Effect.runPromise(
  greet.pipe(Effect.provide(Layer.merge(ConsoleAsk, ConsoleTell))),
)


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// RESOLVING MULTIPLE SERVICES
//
//   const ask  = yield* Ask
//   const tell = yield* Tell
//
// Each `yield* Tag` resolves one service from the environment. With two
// services, both are resolved at the start of the generator before they
// are used. The order of resolution does not matter.
//
//
// COMBINING LAYERS
//
//   greet.pipe(Effect.provide(Layer.merge(ConsoleAsk, ConsoleTell)))
//
// `Layer.merge` combines two layers so both services are available when the
// effect runs.
//
//
// WRAPPING CALLBACK-BASED ASYNC
//
//   Effect.async<string>((resolve) => {
//     const rl = readline.createInterface({ ... })
//     rl.question(prompt, (answer) => {
//       rl.close()
//       resolve(Effect.succeed(answer))
//     })
//   })
//
// `Effect.async` bridges callback-based APIs into the Effect world. The
// outer function receives a `resolve` callback. When the async operation
// completes (here: when the user presses Enter), call
// `resolve(Effect.succeed(value))` to deliver the result back into the
// Effect runtime. Until `resolve` is called, the Effect is suspended.
