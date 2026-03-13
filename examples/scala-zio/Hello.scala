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
