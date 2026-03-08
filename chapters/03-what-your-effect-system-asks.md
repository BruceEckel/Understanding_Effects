# What Your Effect System Asks of You

## No Free Lunch

Making effects visible is not free.

You gain something real.
The problems from Chapter 1 become detectable.
The invisible wiring gets a diagram.
The compiler or runtime catches effect mismatches
before they become runtime surprises.

But you pay in changed ways of working.
Functions need effect declarations,
or return types that carry effect information.
Code that was once a straightforward call site
might need a handler, or a type annotation that wasn't there before.
Mental models that worked for years need updating.

The two families ask for different things.

A built-in effect system asks you to think about effects
the way you already think about types.
Once that habit forms, the system mostly stays out of your way.
The compiler's enforcement is present,
but the code looks like code.

An add-on effect system asks for something more fundamental:
a different mental model for what running a program means.
Instead of writing computations that execute,
you write descriptions of computations that will be executed.
That shift touches everything:
how you sequence operations, how you handle errors,
how you test, how you read code written by others.

Neither of these is free.
Neither is the same cost.

Understanding what each approach asks of you
is what lets you choose between them,
and what lets you work effectively in whichever one you find yourself using.

## The Built-in Experience

The first thing to notice about built-in effect systems
is how much of the mental model you already have.

You already know that type annotations describe what a function accepts and returns.
Effect annotations extend that same idea: they describe what a function does.
Declaring effects is not a new kind of activity.
It is the same activity applied to a new dimension of behavior.

In practice, you rarely write effect annotations by hand.
The compiler infers them from what you call,
the same way it infers return types in languages with type inference.
You annotate explicitly when you want to constrain a function:
to say that it must remain effect-free, or that it may only use specific effects.

```koka
// Constrained to be effect-free: the compiler rejects any effectful call inside
fun add(x: int, y: int): int
  x + y

// Declared to perform console I/O
fun greet(name: string): <console> ()
  println("Hello, " ++ name)
```

Performing an effect looks like a function call.
There is no special keyword, no wrapper syntax.
You call the operation, the compiler adds the effect to your function's row, and the code moves on.

```koka
// Both effects appear because the function performs both
fun describe-division(x: int, y: int): <console,fail> ()
  if y == 0 then fail("cannot divide by zero")
  println(show(x) ++ " / " ++ show(y) ++ " = " ++ show(x / y))
```

The body reads like ordinary sequential code.
The signature is where the effects live.

Writing a handler is the one genuinely new concept.
Think of it as a generalized `catch` block.
A `catch` block intercepts exceptions and decides what to do when one is thrown.
A handler intercepts effect operations and decides what to do when one is performed.

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

<!-- VERIFY: Koka handler syntax, ctl vs fun distinction in handlers, effect row in action parameter type -->

`ctl` is used for operations that can abort, like `fail`.
`fun` is used for operations that always complete normally, like `println`.
The handler wraps a block of code and intercepts whichever effects it declares.
Code inside `on-failure` can call `fail` freely.
The handler decides what failure means.
Code inside `silently` can call `println` freely.
The handler decides what printing means.

This is the **perform**-and-**handle** model.
You perform an effect by calling an operation.
You handle it by installing a handler that provides the implementation.
The compiler enforces that every effect is handled before execution.
No effect reaches the runtime unaccounted for.

The model will feel familiar if you already know exceptions.
The built-in system is that same idea, generalized to every kind of effect.

## The Add-on Experience

The add-on mental model has one foundational rule, and everything follows from it:
a `ZIO` value is not a running computation. It is a description of one.

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
Every operation that could have an effect must return a `ZIO`.
Code that mixes description-building with direct imperative calls will compile.
But it will not behave as you expect,
because the imperative part runs at description-build time, not execution time.
That failure mode is subtle and the bugs it produces are hard to trace.

The system works when you commit to the model.
Once you do, the return type of every function tells you
whether it is a pure description, what effects it might perform,
and what it requires from the environment to run.

## Delayed Execution: An Artifact, Not a Feature

After working through both experiences, a question becomes available:
is the description/execution split essential to effect management?

The answer is no.

Built-in systems achieve everything add-on systems achieve:
effects visible in types, effects that must be handled, code that cannot ignore effects.
They achieve this without delayed execution.
You write a call to `fail` and it looks like a function call.
The compiler tracks the effect.
Nothing is deferred.

Delayed execution exists in add-on systems because of how those systems are built,
not because effect management requires it.
To make effects visible in a language not designed for them,
the library encodes effect information into return types.
For that encoding to mean something, for the library to control how effects are fulfilled,
execution must be deferred.
The description/execution split is the shape a library takes
when it needs to manage effects from the outside.
It is a byproduct.
Many programmers come to value it for its own qualities.
But it is a byproduct.

The cost is a conceptual layer the programmer must carry everywhere.
You must always know whether a value is a description or an action.
You must know that descriptions compose but do not run.
You must know where the boundary is,
and that nothing outside it constitutes execution.
When you are deep in a large codebase built on an add-on system,
that layer is always present.

Built-in systems show that the layer is not required by the problem.
Knowing that helps you understand the tradeoff clearly.
If you choose an add-on system, you are not choosing delayed execution
because it is the natural way to manage effects.
You are accepting it as the cost of a library-based solution
in a language not built for effects from the start.

That is a legitimate choice.
Many teams make it deliberately, with full awareness of what it costs.
What matters is making it with clear eyes.

## Living with Each Approach

Effect systems change how code feels to work with day to day.
The differences show up across several dimensions,
and they run in different directions depending on which family you are using.

**Composability.**
In a built-in system, effects compose automatically.
A function that calls both a failing operation and a logging operation
accumulates both effects in its row.
There is nothing to declare beyond what the compiler already infers.
Two functions with different effects can be called together;
the combined row is their union.

In an add-on system, composition is managed explicitly through the type parameters.
Adding a new effect means extending `R` with an additional service requirement
or widening `E` with an additional error case.
The type system enforces that you have accounted for every effect,
but you do the accounting.

**Testability.**
Both approaches make testing effectful code tractable.
The mechanisms differ.

In a built-in system, you swap the handler.
A function that runs under a real-database handler in production
runs under an in-memory handler in tests.
The function's code does not change.

In ZIO, you swap the layer.
A function that requires a database service through its `R` parameter
receives a real implementation in production and a test implementation in tests.

```koka
// Production
with real-database-handler { run-query(params) }

// Test: substitute without changing run-query
with in-memory-handler { run-query(params) }
```

```scala
// Production
runQuery(params).provide(DatabaseLive.layer)

// Test: substitute without changing runQuery
runQuery(params).provide(DatabaseTest.layer)
```

<!-- VERIFY: Koka handler-as-argument syntax for these examples -->

The structure is parallel: the computation declares what it needs,
and the caller decides how to fulfill it.
Neither approach requires the computation itself to change.

**Error messages and debugging.**
Built-in systems tend to give tight, localized error messages.
If you call an effect operation without a handler, the compiler points to the call.
If you annotate a function as effect-free and it calls something effectful, the error is there.
The information is in the types and the types are close to the code.

Add-on systems can surface type errors at a distance from their source.
A mismatch in a composed `ZIO` type often appears where the descriptions are combined,
not where the problem was introduced.
Reading a type error involving multiple stacked `R` and `E` parameters
requires tracing the assembly back through several steps.
The information is present. Interpreting it takes practice.

**Learning curve.**
The built-in learning curve is largely additive.
Effect rows extend what you already know about return types.
Effect operations look like function calls.
Handlers resemble catch blocks.
The new concepts build on familiar ones.

The add-on learning curve requires a different kind of adjustment.
The individual pieces are learnable: the `ZIO` type, for-comprehensions, layers.
What takes time is the mental model itself.
Understanding that you are building descriptions, not executing code,
tends to settle through mistakes before it settles through explanation.
The mistakes are predictable: effects that run too early, logic that fires at build time.
They stop being surprises once the model is internalized.

**API design.**
In a built-in system, effects are part of a function's signature alongside its types.
A function that might fail and logs to console says so in its effect row.
Callers know what to expect and what to handle.

In an add-on system, the return type is the interface.
`ZIO[DatabaseService, QueryError, User]` tells a caller
what the function needs, what can go wrong, and what it produces on success.
Designing those type parameters well is its own craft:
specific enough to be informative, general enough not to overconstrain the caller.
