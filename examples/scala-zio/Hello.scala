// Introductory effect example in Scala with ZIO.
// One effect: Tell.
// The implementation (layer) in run is swappable without changing the logic.

import zio._
import zio.Console.printLine


// --- Service interface ---

trait Tell:
  def tell(message: String): UIO[Unit]


// --- Accessor method (lift service method into a ZIO) ---

object Tell:
  def tell(message: String): ZIO[Tell, Nothing, Unit] =
    ZIO.serviceWithZIO[Tell](_.tell(message))


// --- Core logic (description — nothing runs yet) ---

val hello: ZIO[Tell, Nothing, Unit] =
  Tell.tell("Hello, World!")


// --- Implementation ---

val consoleTell: ULayer[Tell] = ZLayer.succeed(new Tell:
  def tell(message: String): UIO[Unit] = printLine(message).orDie)


// --- Entry point ---

object Main extends ZIOAppDefault:
  def run = hello.provide(consoleTell)


// =============================================================================
// SYNTAX GUIDE
// =============================================================================
//
// SERVICE INTERFACE
//
//   trait Tell:
//     def tell(message: String): UIO[Unit]
//
// An effect is modeled as a Scala trait — an interface. The method returns
// `UIO[Unit]`: a ZIO value that requires no environment (U = no dependencies),
// can fail with Nothing (cannot fail), and produces Unit. The method does not
// run anything; it returns a description of work to be done.
//
//
// ACCESSOR METHOD
//
//   object Tell:
//     def tell(message: String): ZIO[Tell, Nothing, Unit] =
//       ZIO.serviceWithZIO[Tell](_.tell(message))
//
// The companion object provides a convenience method. `ZIO.serviceWithZIO[Tell]`
// looks up the Tell service from the environment and calls its `tell` method.
// The return type `ZIO[Tell, Nothing, Unit]` has three type parameters:
//   - R = Tell    (this ZIO requires a Tell service in its environment)
//   - E = Nothing (it cannot fail)
//   - A = Unit    (it produces no value)
// This accessor is what the core logic calls — it keeps the logic decoupled
// from any specific implementation.
//
//
// CORE LOGIC AS A VALUE
//
//   val hello: ZIO[Tell, Nothing, Unit] =
//     Tell.tell("Hello, World!")
//
// `hello` is a value — a description of the program, not its execution.
// Nothing runs when this line is evaluated. The type says: to run this, you
// must supply a Tell service.
//
//
// LAYER (IMPLEMENTATION)
//
//   val consoleTell: ULayer[Tell] = ZLayer.succeed(new Tell:
//     def tell(message: String): UIO[Unit] = printLine(message).orDie)
//
// A `ZLayer` is an implementation of a service. `ZLayer.succeed(...)` wraps a
// concrete instance. `ULayer[Tell]` means: a layer that provides Tell, requires
// nothing as input, and cannot fail. `printLine(message).orDie` runs the
// console print and converts any IO failure into a fatal error, simplifying
// the error type to Nothing.
//
//
// ENTRY POINT
//
//   object Main extends ZIOAppDefault:
//     def run = hello.provide(consoleTell)
//
// `ZIOAppDefault` is ZIO's entry point base class. `.provide(consoleTell)`
// wires the implementation into the description, satisfying the Tell
// requirement. At this point the ZIO runtime executes the program.
