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

An effect system does three things:

1. **Tracks effects** — the type system knows which effects a function may perform.
2. **Separates the effect interface from its implementation** — a function declares *what* effects it uses, not *how* they're fulfilled.
3. **Binds the implementation later** — the implementation is supplied at a point after the function is defined, by some caller or context.

None of these require delayed execution. The confusion arises because library-based systems like ZIO and TypeScript Effect have no language-level support for points 1–3, so they must encode all three into a *data structure* that gets interpreted by a runtime. This collapses binding and execution into a single deferred step — making delayed execution feel like an inherent property of effect systems. It isn't. It's an implementation constraint imposed by the host language.

In a language with native algebraic effects (Koka, OCaml 5, Flix), binding happens via handlers at the call site, and execution proceeds eagerly. When the function hits an effect operation, the already-bound handler intercepts it via continuations and provides the implementation. Binding is still "later" relative to the function definition, satisfying point 3, but the function runs immediately — no thunks, no description trees, no interpretation step.

The distinction: library-based systems must defer execution *because* that's their only mechanism for deferred binding. Native systems separate the two — you bind via handlers, then execute eagerly with those bindings in scope.

## Thunks

When you write a ZIO `for`-comprehension, it desugars to `flatMap` calls:

```scala
Ask.ask.flatMap(x => Tell.tell(x * 2).map(_ => x * 2))
```

That lambda `x => ...` is the thunk. It's a closure that captures "what to do next, given a result." It gets stored inside a `FlatMap` data structure node — not executed. So the effect description is a tree of nodes connected by thunks.

The thunks aren't really about binding effect *implementations* — they're about *sequencing*. They encode the continuation of the computation. The binding of implementations happens elsewhere (in the `provide` / `provideLayer` step where you attach actual handlers to the effect interfaces).

At interpretation time, the runtime does both jobs in one pass: it walks the tree, encounters an effect node, looks up the bound implementation, gets a result, then *calls the thunk* with that result to obtain the next node. The thunk is the connective tissue that threads values through the chain.

In a native effect system, the language's continuation mechanism replaces exactly this role. Instead of manually encoding "what comes next" as a closure stored in a data structure, the runtime captures the actual call stack as a continuation. Same information, but extracted by the language machinery rather than built up by the programmer via `flatMap`.

So: thunks are part of *construction* (they get embedded in nodes) and part of *sequencing* (the runtime invokes them to step through the computation). They're the workaround for not having continuations.
