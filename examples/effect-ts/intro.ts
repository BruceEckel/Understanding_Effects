// Introductory effect example in TypeScript with Effect.ts.
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
