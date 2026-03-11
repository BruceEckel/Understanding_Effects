**Why ZIO/Effect need delayed execution:** They're libraries in languages without native effect support, so they must encode effects as *data structures* (descriptions of computations) that get interpreted later by a runtime. The `flatMap` chain builds a recipe; `unsafeRun` executes it. Delayed execution isn't a property of effect systems — it's a workaround for the lack of language-level support.

**Why native algebraic effects don't:** Languages like Koka, OCaml 5, and Flix implement effects via *continuations*. The function executes eagerly and normally. When it hits an effect operation, the runtime captures a continuation, transfers control to the handler, and the handler can resume execution. No thunks, no descriptions, no interpretation step.

Here's a Koka example that makes it concrete:

```koka
// Declare effects — these are just operation signatures
effect ask
  fun ask() : int

effect tell
  fun tell(x : int) : ()

// This function executes EAGERLY — no delayed execution anywhere
fun double() : <ask, tell> int
  val x = ask()      // runs immediately, handler provides value
  tell(x * 2)        // runs immediately, handler receives value
  x * 2

fun main() : console ()
  with fun ask()    42
  with fun tell(x)  println("Got: " ++ x.show)
  val result = double()   // executes RIGHT NOW
  println("Returned: " ++ result.show)
```

When `double()` is called, it *runs*. It doesn't build a description. When execution hits `ask()`, the runtime captures the continuation (everything after `ask()`), passes control to the handler, and the handler provides `42`. Execution resumes at `val x = 42`. Same for `tell`. It's just function calls with a clever control-flow mechanism underneath.

Compare the ZIO equivalent:

```scala
// This builds a DATA STRUCTURE — nothing executes
val double: ZIO[Ask & Tell, Nothing, Int] = for {
  x <- Ask.ask           // constructs a FlatMap node
  _ <- Tell.tell(x * 2)  // constructs another FlatMap node
} yield x * 2            // still just a description
// Only executes when the runtime interprets it
```

The crux: ZIO's `for`-comprehension produces a *value* (an inert tree of `FlatMap`/`Succeed` nodes). Koka's function produces a *result* (eagerly, with handlers intercepting effects via continuations). Same expressiveness, completely different execution model.
