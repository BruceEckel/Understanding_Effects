# What Your Effect System Asks of You

Functions need Effect declarations or return types that carry Effect information.
Code that was once a straightforward call site
might need a handler, or a type annotation that wasn't there before.

A native Effect system asks you to think about Effects
the way you already think about types.
Once that habit forms, the system mostly stays out of your way.
The compiler's enforcement is present,
but the code looks like code.

A library Effect system asks for something more fundamental:
a different mental model for what running a program means.
Instead of writing computations that execute,
you write descriptions of computations that will be executed.
That shift touches everything:
how you sequence operations, how you handle errors,
how you test, how you read code written by others.

## The Native Experience

The first thing to notice about native Effect systems
is how much of the mental model you already have.

In practice, you rarely write Effect annotations by hand.
The compiler infers them from what you call,
the same way it infers return types in languages with type inference.
You annotate explicitly when you want to constrain a function:
to say that it must remain Effect-free, or that it may only use specific Effects.

```koka
// Pure, so the compiler rejects any Effectful call in the body:
fun add(x: int, y: int): int
  x + y

// Declared to perform console I/O
fun greet(name: string): <console> ()
  println("Hello, " ++ name)
```

Performing an Effect looks like a function call.
There is no special keyword, no wrapper syntax.
You call the operation, the compiler adds the Effect to your function's row, and the code moves on.

```koka
// Both Effects appear because the function performs both
fun describe-division(x: int, y: int): <console,fail> ()
  if y == 0 then fail("cannot divide by zero")
  println(show(x) ++ " / " ++ show(y) ++ " = " ++ show(x / y))
```

The body reads like ordinary sequential code.
The signature is where the Effects live.

Writing a handler is the one genuinely new concept.
Think of it as a generalized `catch` block.
A `catch` block intercepts exceptions and decides what to do when one is thrown.
A handler intercepts Effect operations and decides what to do when one is performed.

```koka
// Handle failure by returning a default value
fun on-failure(default: int, action: () -> <fail> int): int
  with handler
    ctl fail(_msg) -> default
  action()

// Handle console output by discarding it
fun silently(action: () -> <console> a): a
  with handler
    fun println(_msg) -> ()
  action()
```

<!-- VERIFY: Koka handler syntax, ctl vs fun distinction in handlers, Effect row in action parameter type -->

`ctl` is used for operations that can abort, like `fail`.
`fun` is used for operations that always complete normally, like `println`.
The handler wraps a block of code and intercepts whichever Effects it declares.
Code inside `on-failure` can call `fail` freely.
The handler decides what failure means.
Code inside `silently` can call `println` freely.
The handler decides what printing means.

This is the *perform-and-handle* model.
You perform an Effect by calling an operation.
You handle it by installing a handler that provides the implementation.
The compiler enforces that every Effect is handled before execution.
No Effect reaches the runtime unaccounted for.

This model feels similar to exceptions.
The native system is that same idea, generalized to every kind of Effect.

Flix uses the same perform-and-handle model with different syntax.
You still perform Effects by calling operations.
You still install handlers to give those operations their meaning.
The handler wraps the computation using `run ... with`:

```flix
// Handle failure by returning a default value
def withDefault(default: Int32, f: Unit -> Int32 \ Fail): Int32 =
    run f() with Fail {
        def fail(_msg) = default
    }

// Handle console output by discarding it
def silently(f: Unit -> a \ Console): a =
    run f() with Console {
        def println(_msg) = ()
    }
```

<!-- VERIFY: Flix handler syntax (run ... with EffName { def op(...) = ... }), Unit -> a \ Eff function type syntax, Console Effect name and println operation -->

`run ... with` is Flix's handler construct where Koka uses `with handler`.
The names differ; the structure does not.

## The Addon Experience

The library mental model has one foundational rule, and everything follows from it:
a value is not a running computation. It is a description of one.

When you write `ZIO.attempt(readLine())`, nothing reads a line.
When you write `ZIO.fail("not found")`, nothing fails.
You have built a value that, when executed, will perform those actions.
The difference matters everywhere.

You sequence descriptions using for-comprehensions.
Each `<-` says: when this description runs, bind its result to this name.

```scala
val greet: ZIO[Any, Throwable, Unit] =
  for
    line <- ZIO.attempt(readLine())
    _    <- ZIO.attempt(println(s"Hello, $line"))
  yield ()
```
<!-- convert to direct style -->

`greet` is a value.
No line has been read. No greeting has been printed.
The for-comprehension expresses the sequence; it does not perform it.

Error handling follows the same pattern.
You do not wrap descriptions in try/catch. You transform them.

```scala
val safe: ZIO[Any, Nothing, String] =
  ZIO.attempt(readLine())
    .map(_.trim)
    .catchAll(_ => ZIO.succeed("(no input)"))
```

`catchAll` takes a description that might fail
and returns a description that cannot.
The error type changes from `Throwable` to `Nothing` in the signature.
You have not handled an error yet. You have described how to handle one.

Execution begins at the boundary:

```scala
object Main extends ZIOAppDefault:
  def run = greet
```

Everything above `run` is description. `run` is where it becomes action.
The runtime evaluates the description, performs the I/O, and reports the result.

The discipline this asks for is consistency.
Every operation that could have an Effect must return a `ZIO`.
Code that mixes description-building with direct imperative calls will compile.
But it will not behave as you expect,
because the imperative part runs at description-build time, not execution time.
That failure mode is subtle and the bugs it produces are hard to trace.

The return type of every function tells you
whether it is a pure description, what Effects it might perform,
and what it requires from the environment to run.

Effect.ts brings the same mental model to TypeScript.
The type is `Effect.Effect<Success, Error, Requirements>`,
and generator syntax sequences descriptions the same way for-comprehensions do in Scala.

```typescript
const greet: Effect.Effect<void> = Effect.gen(function* () {
  const line = yield* Effect.sync(() => readLineSync())
  yield* Effect.sync(() => console.log(`Hello, ${line}`))
})

const safe: Effect.Effect<string, never> =
  Effect.sync(() => readLineSync()).pipe(
    Effect.map((s) => s.trim()),
    Effect.catchAll(() => Effect.succeed("(no input)"))
  )

// The execution boundary
Effect.runSync(greet)
```

<!-- VERIFY: Effect.ts generator yield* syntax, Effect.sync for synchronous side Effects, .pipe chaining with catchAll, Effect<A, never> when error is eliminated, runSync -->

The error type changes from `Error` to `never` when `catchAll` eliminates the failure case —
the same signal ZIO gives with `Nothing`.
`greet` is a value; `Effect.runSync` is where it becomes action.
The discipline is the same: descriptions compose, the boundary executes.

## Delayed Execution: An Artifact, Not a Feature

After working through both approaches, a question arises:
is the description/execution split essential to Effect management?

The answer is no.

Native systems achieve everything without delayed execution.
Delayed execution exists in library systems because of how those systems are built,
not because Effect management requires it.
To make Effects visible in a language not designed for them,
the library encodes Effect information into return types.
For that encoding to mean something, for the library to control how Effects are fulfilled,
execution must be deferred.
The description/execution split is the shape a library takes
when it needs to manage Effects from the outside.
It is an artifact.
The description model does enable patterns that programmers come to value.
Retry logic, timeouts, and guaranteed resource cleanup all require
control over when an Effect executes.
A description can be retried. An Effect that has already run cannot.
native systems reach the same goals through handlers.
A retry handler can invoke its continuation multiple times.
A timeout handler can abort before the deadline.
The capabilities are real, and the path through descriptions is not the only one.
But it is an artifact.

The cost is a conceptual layer the programmer must carry everywhere.
You must always know whether a value is a description or an action.
You must know that descriptions compose but do not run.
You must know where the boundary is,
and that nothing outside it constitutes execution.
When you are deep in a large codebase built on a library system,
that layer is always present.

Native systems show that the layer is not required by the problem.
Knowing that helps you understand the tradeoff clearly.
A library system does not use delayed execution
because it is the natural way to manage Effects.
It is the cost of a library-based solution
in a language not built for Effects from the start.

## Living with Each Approach

Effect systems change how code feels to work with day to day.
The differences show up across several dimensions,
and they run in different directions depending on which approach you are using.

**Composability.**
In a native system, Effects compose automatically.
A function that calls a failing operation and a logging operation
accumulates both Effects in its row.
There is nothing to declare beyond what the compiler already infers.
Two functions with different Effects can be called together, and
the combined row is their union.

In a library system, composition is managed explicitly through the type parameters.
Adding a new Effect means extending `R` with an additional service requirement
or widening `E` with an additional error case.
The type system enforces that you have accounted for every Effect,
but you do the accounting.

**Testability.**
Both approaches make testing Effectful code tractable.
The mechanisms differ.

In a native system, you swap the handler.
A function that runs under a real-database handler in production
runs under an in-memory handler in tests.
The function's code does not change.

In a library system, you swap the layer.
A function that requires a database service through its `R` parameter
receives a real implementation in production and a test implementation in tests.

```koka
// Production
with real-database-handler { run-query(params) }

// Test: substitute without changing run-query
with in-memory-handler { run-query(params) }
```

```flix
// Production
run runQuery(params) with realDatabaseHandler

// Test: substitute without changing runQuery
run runQuery(params) with inMemoryHandler
```

<!-- VERIFY: Koka handler-as-argument syntax; Flix run...with syntax for named handler values -->

```scala
// Production
runQuery(params).provide(DatabaseLive.layer)

// Test: substitute without changing runQuery
runQuery(params).provide(DatabaseTest.layer)
```

```typescript
// Production
Effect.runSync(runQuery(params).pipe(Effect.provide(DatabaseLive)))

// Test: substitute without changing runQuery
Effect.runSync(runQuery(params).pipe(Effect.provide(DatabaseTest)))
```

<!-- VERIFY: Effect.ts Effect.provide syntax, pipe placement relative to runSync -->

The structure is parallel across all four: the computation declares what it needs,
and the caller decides how to fulfill it.
Neither approach requires the computation itself to change.

**Error messages and debugging.**
native systems tend to give tight, localized error messages.
If you call an Effect operation without a handler, the compiler points to the call.
If you annotate a function as Effect-free and it calls something Effectful, the error is there.
The information is in the types and the types are close to the code.

library systems can surface type errors at a distance from their source.
A mismatch in a composed `ZIO` type often appears where the descriptions are combined,
not where the problem was introduced.
Reading a type error involving multiple stacked `R` and `E` parameters
requires tracing the assembly back through several steps.
The information is present. Interpreting it takes practice.

**Learning curve.**
The native learning curve is largely additive.
Effect rows extend what you already know about return types.
Effect operations look like function calls.
Handlers resemble catch blocks.
The new concepts build on familiar ones.

The library learning curve requires a different kind of adjustment.
The individual pieces are learnable: the `ZIO` type, for-comprehensions, layers.
What takes time is the mental model itself.
Understanding that you are building descriptions, not executing code,
tends to settle through mistakes before it settles through explanation.
The mistakes are predictable: Effects that run too early, logic that fires at build time.
They stop being surprises once the model is internalized.

**API design.**
In a native system, Effects are part of a function's signature alongside its types.
A function that might fail and logs to console says so in its Effect row.
Callers know what to expect and what to handle.

In a library system, the return type is the interface.
`ZIO[DatabaseService, QueryError, User]` tells a caller
what the function needs, what can go wrong, and what it produces on success.
Designing those type parameters well is its own craft:
specific enough to be informative, general enough not to overconstrain the caller.

## Choosing Your Tradeoffs

In practice, context decides more than principles do.
A team already working in Scala or TypeScript is not choosing between Effect systems in the abstract.
It is choosing which library to adopt in an ecosystem that already exists,
where the library model is the established path.
A team with more flexibility might weigh native systems seriously,
knowing that the conceptual overhead is lower
even if the ecosystem is still maturing.

The concepts transfer.
A programmer who understands the perform-and-handle model
can read ZIO or Effect code with comprehension.
A programmer fluent in descriptions and layers
can pick up a native system's Effect rows without starting from zero.
The vocabulary is shared even when the mechanisms differ.

The remainder of the book uses <specific language>.
