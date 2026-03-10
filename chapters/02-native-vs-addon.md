# Effect Systems: Native vs Addon

Ideally, Effects are directly supported by the language; we'll call this a native Effect system.
It's also possible to implement an Effect System as an addon library for an existing language,
as long as that language has a type system.

These two approaches produce different programming experiences.
Programs written in a native Effect system look like ordinary sequential code.
Effect information lives in type signatures, tracked by the compiler.
Programs written for an addon Effect system work differently:
you construct descriptions of what a program should do, then execute those descriptions.

You'll have a better programming experience with a native Effect system.
However, it's highly likely that you don't have the flexibility to change languages,
in which case an addon Effect system allows you to use Effects with your language of choice.

## Native Effect Systems

In a native Effect system, Effects live in the type system alongside ordinary types.
A function's signature carries two pieces of information: what it returns, and what Effects it performs.

The function body looks like ordinary sequential programming.
You call functions, bind values, return results.
The compiler observes what you call and tracks the Effects,
the same way it tracks whether a value is an integer or a string.

Here is what that looks like in Koka, a language with native Effects.
A function with no Effects shows only a return type.
A function with Effects names them in the signature:

```koka
// Takes two ints, returns an int, no Effects:
fun add(x: int, y: int): int
  x + y

// The console Effect is part of the signature:
fun greet(name: string): <console> ()
  println("Hello, " ++ name)
```

The angle brackets hold the **Effect row**: the set of Effects this function performs.
`add` has an empty Effect row, so nothing appears there.
`greet` performs console I/O, so `<console>` appears in its signature, and `()` indicates it returns nothing.

Here is the same example in Flix:

```flix
// No Effects:
def add(x: Int32, y: Int32): Int32 = x + y

// The backslash begins the Effect row
def greet(name: String): Unit \ IO =
    println("Hello, ${name}")
```

Flix Effects appear after a backslash in function signatures
rather than within angle brackets.

The Effect information becomes part of the type.
The caller sees that `greet` uses the `console` or `IO` Effect.

With a native system, Effect annotations propagate automatically.
If a function calls `greet`, the compiler adds `console` or `IO` to its own Effect row.
The compiler infers the Effects from what you call.
You can also annotate explicitly when you want to constrain what a function is allowed to do.

Effects must be fulfilled at some point.
Something must decide what actually happens when a function signals a failure,
or asks for a configuration value, or uses the console.
In a native system, that mechanism is the **handler**:
a construct that intercepts an Effect and provides its implementation.

Here is a custom Effect with a handler:

```koka
// Declare a custom Effect that can fail:
Effect fail
  ctl fail(msg: string): a

// A function that uses the Effect:
fun safe-divide(x: int, y: int): <fail> int
  if y == 0 then fail("division by zero")
  else x / y

// The handler decides what "fail" means in this context:
fun with-default(default: int, action: () -> <fail> int): int
  with handler
    ctl fail(_msg) -> default
  action()

// with-default(0) { safe-divide(10, 0) }  =>  0
// with-default(0) { safe-divide(10, 2) }  =>  5
```

<!-- VERIFY: Koka Effect declaration syntax (Effect/ctl), handler syntax (with handler / ctl), and angle-bracket Effect row in signatures -->

`safe-divide` does not decide what happens when division fails.
Its caller installs a handler that makes that decision.
The Effect in the type ensures you cannot call `safe-divide` in a context
where failure has no handler — the compiler catches that before you run anything.

The code reads sequentially.
The Effects are visible in the types.
The handlers connect Effects to implementations.

Here's the Flix equivalent:

```flix
// A custom Effect and a function that uses it
eff Fail {
    def fail(msg: String): a
}

def safeDivide(x: Int32, y: Int32): Int32 \ Fail =
    if (y == 0) do Fail.fail("division by zero")
    else x / y
```

<!-- VERIFY: Flix backslash Effect set notation, eff/def declaration syntax inside eff block, do keyword for performing Effects, IO Effect name -->

The compiler ensures that all Effects have handlers.

Languages in this family include Koka, Eff, Effekt, Unison, and Flix.

## Addon Effect Systems

It is not practical to require you to change languages to use Effects.
If you've already committed to a language, you may not be able to switch.

To solve this problem, designers created *addon Effect systems*, implemented as libraries.
In an existing language, the compiler doesn't track Effects,
they used the existing type system to encode Effect information into the return type.
The approach requires a shift in mechanism:
instead of writing a computation and having the compiler observe its Effects,
you build a **description** of a computation and execute that description later.

In the Scala ZIO library, that description is a value of type `ZIO[R, E, A]`.
The three type parameters carry the Effect information:
`R` is the environment the computation requires,
`E` is the type of error it can produce,
and `A` is the type of value it produces on success.

```scala
// Requires no environment (Any)
// Can fail with an exception (Throwable)
// Produces an Int on success
def safeDivide(x: Int, y: Int): ZIO[Any, Throwable, Int] =
  ZIO.attempt(x / y)
```

Calling `safeDivide` doesn't execute the code — it returns a description, not a result.

Within a function, you compose descriptions using for-comprehensions.
Here is Scala's syntax for chaining operations where each step can use the result of the previous one:

```scala
val program: ZIO[Any, Throwable, Unit] =
  for
    line <- ZIO.attempt(readLine())
    _    <- ZIO.attempt(println(s"Hello, $line"))
  yield ()
```

`program` is also only a value, and defining it does not execute any code.

Execution happens at a the runtime entry point:

```scala
object Main extends ZIOAppDefault:
  def run = program
```

Sometimes we say that execution happens at the "edge".

Everything above `run` is description.
`run` is where description becomes action.

This boundary is not incidental. It is the mechanism.
The compiler sees what Effects a function might perform by looking at its return type,
the same way it inspects any other type.
But the Effects are encoded in a library type, not tracked natively by the language.

Effect, a TypeScript library, uses the same approach.
Its description type is `Effect<Success, Error, Requirements>`.
The type parameters carry Effect information in the same three roles,
with different names.

```typescript
// A description that can fail with Error, requires no environment
const safeDivide = (x: number, y: number): Effect.Effect<number, Error> =>
  y === 0
    ? Effect.fail(new Error("division by zero"))
    : Effect.succeed(x / y)

```

As before, nothing has run. `safeDivide` returns a description, not a result.

Descriptions compose using generator syntax:

```typescript
const greet: Effect.Effect<void> = Effect.gen(function* () {
  const line = yield* Effect.sync(() => readLineSync())
  yield* Effect.sync(() => console.log(`Hello, ${line}`))
})
```

`greet` is also still a value. Nothing has run.

Execution happens at the edge:

```typescript
Effect.runSync(greet)
```

<!-- VERIFY: Effect.ts type parameter order (Effect<A, E, R>), generator yield* syntax, Effect.sync for wrapping synchronous side Effects, runSync vs runPromise -->

Addon libraries require this description/execution split.
The library controls execution; everything above the boundary is description.

Libraries in this family include ZIO, Cats Effect, and Kyo in Scala;
polysemy and Effectful in Haskell; and Effect in TypeScript.

## Why the Split Exists

The two families did not emerge from competing theories about the right way to manage Effects.
They emerged from different starting points.

Languages like Koka and Eff were designed from scratch by researchers
whose central goal was exploring what a language built around Effects could look like.
With no existing codebase to preserve and no compatibility constraints to honor,
they could put Effects into the type system at the foundation.
Everything else in the language was built around that choice.

Scala arrived at its approach by a different route.
It had years of production use, a large library ecosystem, and deep interoperability with Java.
Redesigning the language's type system from scratch was not possible.
But Scala's type system was expressive enough that library authors could encode Effect information
into types without any compiler changes.
ZIO and Cats Effect are the result: full-featured Effect systems built entirely as libraries,
working within the language as it already existed.

The constraint shaped the mechanism.
The description/execution split is a natural consequence of encoding Effects into values
in a language that was not designed for them.
To track whether a function is Effectful, the type must carry that information.
To make that type meaningful, execution must be deferred to a boundary the library controls.
That is what makes the mechanism work.

Neither starting point was wrong.
A language designed around Effects from the ground up can offer things a library cannot.
It can provide tighter compiler integration, cleaner error messages,
and syntax that feels native rather than adapted.
A library built on top of an established language brings something different:
the entire ecosystem of that language, its tooling, its community,
and years of production experience.
Choosing between them is not a matter of correctness.
It is a matter of context.

## What They Share

The two families look different from the outside and work differently on the inside.
But both make Effects visible.
In a native system, the Effect row in a function's signature tells you what that function does.
In an addon system, the type parameters of the description type tell you the same thing.
The mechanism is different.
The result is the same: Effects you can see without reading the body.

Both separate the declaration of Effects from their implementation.
In Koka, a function declares a `<fail>` Effect without deciding what failure means.
A handler somewhere up the call stack makes that decision.
In ZIO, a function returns a `ZIO[R, E, A]` without deciding what environment it runs in
or how its errors are resolved.
The caller provides that through configuration.
Neither the function nor the description owns the implementation of its own Effects.

Both let the compiler or runtime enforce Effect discipline.
In a native system, the compiler rejects code that uses an unhandled Effect.
In an addon system, the type system rejects code that runs a description
with unsatisfied dependencies or unresolved error types.
The enforcement looks different, but the principle is the same:
you cannot ignore Effects. The language, or the library, makes you account for them.

These three properties are what distinguish an Effect system, of either kind,
from the invisible Effects of Chapter 1.
The question is no longer whether Effects exist.
It is how they are declared, who handles them, and what happens when you fail to account for them.

The next chapter looks at what living with those answers actually feels like.
