// Session effect example in Scala with ZIO.
// Four effects: Ask, Tell, Store, Fetch.
// The implementations (layers) in run are swappable without changing the logic.

import zio._
import zio.Console.{printLine, print => printNoNewline, readLine}


// --- Service interfaces ---

trait Ask:
  def ask(prompt: String): UIO[String]

trait Tell:
  def tell(message: String): UIO[Unit]

trait Store:
  def store(value: String): UIO[Int]

trait Fetch:
  def fetch(id: Int): UIO[String]


// --- Accessor methods (lift each service method into a ZIO) ---

object Ask:
  def ask(prompt: String): ZIO[Ask, Nothing, String] =
    ZIO.serviceWithZIO[Ask](_.ask(prompt))

object Tell:
  def tell(message: String): ZIO[Tell, Nothing, Unit] =
    ZIO.serviceWithZIO[Tell](_.tell(message))

object Store:
  def store(value: String): ZIO[Store, Nothing, Int] =
    ZIO.serviceWithZIO[Store](_.store(value))

object Fetch:
  def fetch(id: Int): ZIO[Fetch, Nothing, String] =
    ZIO.serviceWithZIO[Fetch](_.fetch(id))


// --- Core logic (descriptions — nothing runs yet) ---

val inquire: ZIO[Ask & Tell & Store, Nothing, Int] =
  for
    _    <- Tell.tell("Hello!")
    name <- Ask.ask("What is your name? ")
    id   <- Store.store(name)
  yield id

def greet(id: Int): ZIO[Fetch & Tell, Nothing, Unit] =
  for
    name <- Fetch.fetch(id)
    _    <- Tell.tell(s"Hello, $name!")
  yield ()


// --- Implementations ---

val consoleTell: ULayer[Tell] = ZLayer.succeed(new Tell:
  def tell(message: String): UIO[Unit] = printLine(message).orDie)

val consoleAsk: ULayer[Ask] = ZLayer.succeed(new Ask:
  def ask(prompt: String): UIO[String] =
    printNoNewline(prompt).orDie *> readLine.orDie)

// Store and Fetch share a Ref, so they are built together from a single ZIO.
// VERIFY: Tag[Store & Fetch] derivation in ZIO 2 / izumi-reflect with Scala 3
val memoryLayer: ULayer[Store & Fetch] = ZLayer.fromZIO(
  for
    db      <- Ref.make(Map.empty[Int, String])
    counter <- Ref.make(0)
  yield (new Store with Fetch {
    def store(value: String): UIO[Int] =
      for
        id <- counter.updateAndGet(_ + 1)
        _  <- db.update(_ + (id -> value))
      yield id

    def fetch(id: Int): UIO[String] =
      db.get.map(_.getOrElse(id, ""))
  }: Store & Fetch)
)


// --- Entry point ---

object Main extends ZIOAppDefault:
  def run =
    inquire
      .flatMap(greet)
      .provide(consoleTell, consoleAsk, memoryLayer)


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// TWO LOGIC FUNCTIONS WITH DIFFERENT SIGNATURES
//
//   val inquire: ZIO[Ask & Tell & Store, Nothing, Int]
//   def greet(id: Int): ZIO[Fetch & Tell, Nothing, Unit]
//
// `inquire` is a value (no parameters); `greet` is a function that takes an
// Int. Both are ZIO descriptions. Each declares only its own environmental
// requirements — neither knows about the other's services.
//
//
// MUTABLE REFERENCES WITH Ref
//
//   db      <- Ref.make(Map.empty[Int, String])
//   counter <- Ref.make(0)
//
// `Ref.make(initial)` creates a ZIO-managed mutable reference. Unlike a Scala
// `var`, a `Ref` is safe in concurrent code because ZIO controls all access.
//
//   counter.updateAndGet(_ + 1)      // atomically increment, return new value
//   db.update(_ + (id -> value))     // atomically add a key-value pair to the map
//   db.get.map(_.getOrElse(id, ""))  // read, then transform the result
//
// `_ + (id -> value)` is shorthand for `map => map + (id -> value)` — adding
// an entry to an immutable Map and returning the updated copy.
//
//
// BUILDING A LAYER WITH INITIALIZATION
//
//   val memoryLayer: ULayer[Store & Fetch] = ZLayer.fromZIO(
//     for ... yield (new Store with Fetch { ... }: Store & Fetch)
//   )
//
// `ZLayer.fromZIO` builds a layer from a ZIO effect — useful when the layer
// itself needs to perform initialization (here: allocating Refs). The inner
// `for`/`yield` creates the Refs, then yields a single object implementing
// both Store and Fetch. `new Store with Fetch { ... }` is Scala's syntax for
// an anonymous class that mixes in multiple traits. Both services share the
// same Refs, which is why they are built together.
//
//
// CHAINING TWO PROGRAMS
//
//   inquire.flatMap(greet)
//
// `.flatMap(f)` runs `inquire`, takes its result (the Int id), and passes it
// to `greet`. This is equivalent to writing the same thing as a
// for-comprehension but expressed directly.
