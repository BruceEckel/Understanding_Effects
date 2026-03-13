// Welcome effect example in Scala with ZIO.
// Two effects: Ask and Tell.
// The implementations (layers) in run are swappable without changing the logic.

import zio._
import zio.Console.{printLine, print => printNoNewline, readLine}


// --- Service interfaces ---

trait Ask:
  def ask(prompt: String): UIO[String]

trait Tell:
  def tell(message: String): UIO[Unit]


// --- Accessor methods (lift each service method into a ZIO) ---

object Ask:
  def ask(prompt: String): ZIO[Ask, Nothing, String] =
    ZIO.serviceWithZIO[Ask](_.ask(prompt))

object Tell:
  def tell(message: String): ZIO[Tell, Nothing, Unit] =
    ZIO.serviceWithZIO[Tell](_.tell(message))


// --- Core logic (description — nothing runs yet) ---

val greet: ZIO[Ask & Tell, Nothing, Unit] =
  for
    name <- Ask.ask("What is your name? ")
    _    <- Tell.tell(s"Hello, $name!")
  yield ()


// --- Implementations ---

val consoleAsk: ULayer[Ask] = ZLayer.succeed(new Ask:
  def ask(prompt: String): UIO[String] =
    printNoNewline(prompt).orDie *> readLine.orDie)

val consoleTell: ULayer[Tell] = ZLayer.succeed(new Tell:
  def tell(message: String): UIO[Unit] = printLine(message).orDie)


// --- Entry point ---

object Main extends ZIOAppDefault:
  def run = greet.provide(consoleAsk, consoleTell)


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// FOR-COMPREHENSION (SEQUENCING EFFECTS)
//
//   val greet: ZIO[Ask & Tell, Nothing, Unit] =
//     for
//       name <- Ask.ask("What is your name? ")
//       _    <- Tell.tell(s"Hello, $name!")
//     yield ()
//
// ZIO's `for`/`yield` comprehension sequences effects. The `<-` arrow binds
// the result of each ZIO to a variable. `name` receives the String produced
// by `Ask.ask`. The underscore `_` discards the Unit result of `Tell.tell`.
// `yield ()` ends the comprehension with a Unit value. Each step runs in
// order; later steps can reference earlier bindings.
//
//
// ENVIRONMENT INTERSECTION
//
//   ZIO[Ask & Tell, Nothing, Unit]
//
// `Ask & Tell` is a Scala type intersection: `greet` requires both services
// to be present in its environment.
//
//
// PROVIDING MULTIPLE LAYERS
//
//   greet.provide(consoleAsk, consoleTell)
//
// `.provide(...)` accepts multiple layers. ZIO combines them and wires each
// service into the environment, satisfying the `Ask & Tell` requirement.
//
//
// SEQUENCING WITHIN AN IMPLEMENTATION
//
//   printNoNewline(prompt).orDie *> readLine.orDie
//
// `*>` is ZIO's sequence-and-discard operator: run the left effect, discard
// its result, then run the right effect and return its result. Here: print
// the prompt (no result needed), then read a line and return the string.
//
//
// STRING INTERPOLATION
//
//   s"Hello, $name!"
//
// The `s` prefix enables string interpolation; `$name` is replaced by the
// variable's value.
