# Effect Systems: Native vs Library

Ideally, Effects are directly supported by the language; we'll call this a *native* Effect System.
It's also possible to implement an Effect System as a library for an existing language,
as long as that language has a type system.

These two approaches produce different programming experiences.
Programs written in a native Effect system look like ordinary sequential code.
Effect information lives in type signatures, tracked by the compiler.
Programs written for a library Effect system work differently:
you construct descriptions of what a program should do, then execute those descriptions.

You'll have a better programming experience with a native Effect system.
However, you might not have the flexibility to change languages,
in which case a library Effect system allows you to use Effects with your language of choice.

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

The angle brackets hold the *Effect row*: the set of Effects this function performs.
`add` has an empty Effect row, so nothing appears there.
`greet` performs console I/O, so `<console>` appears in its signature, and `()` indicates it returns nothing.

In Flix, function Effects appear after a backslash:

```flix
// No Effects:
def add(x: Int32, y: Int32): Int32 = x + y

// The backslash begins the Effect row
def greet(name: String): Unit \ IO =
    println("Hello, ${name}")
```

The Effect information becomes part of the type.
In both languages, the caller sees that `greet` uses the `console` or `IO` Effect.

With a native system, Effect annotations propagate automatically.
If a function calls `greet`, the compiler adds `console` or `IO` to its own Effect row.
The compiler infers the Effects from what you call.
You can also manually annotate explicitly when you want to constrain what a function is allowed to do.

Effects must be fulfilled at some point.
Something must decide what actually happens when a function signals a failure,
or asks for a configuration value, or uses the console.
In a native system, that mechanism is the *handler*:
a construct that intercepts an Effect and provides its implementation.

Here is a custom Effect with a handler in Koka:

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

## Library Effect Systems

It is not practical to require you to change languages to use Effects.
If you've already committed to a language, there are numerous reasons you might not be able to switch.

To solve this problem, designers created *library Effect systems*, implemented as libraries.
In this approach, the compiler doesn't track Effects.
Instead, a library uses the existing type system to encode Effect information into the return type.
The approach requires a shift in mechanism:
instead of writing a computation and having the compiler observe its Effects,
you build a *description* of a computation and execute that description later.

In the Scala ZIO library, that description is a return value of type `ZIO[R, E, A]`.
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

Calling `safeDivide` doesn't execute the code; it returns a description, not a result.

Within a function, you compose descriptions using for-comprehensions.
Here is Scala's syntax for chaining operations where each step can use the result of the previous one:

```scala
val program: ZIO[Any, Throwable, Unit] =
  for
    line <- ZIO.attempt(readLine())
    _    <- ZIO.attempt(println(s"Hello, $line"))
  yield ()
```

<!-- Convert to direct notation -->

`program` is also only a value, and defining it does not execute any code.

Execution happens at a the runtime entry point:

```scala
object Main extends ZIOAppDefault:
  def run = program
```

Everything above `run` is description.
`run` is where description becomes action.
Sometimes we say that execution happens at the "edge".

This boundary is not incidental. It is the mechanism.
The compiler sees what Effects a function might perform by looking at its return type,
the same way it inspects any other type.
The Effects are encoded in the type, not tracked natively by the language.

The TypeScript Effect library uses the same approach.
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

`safeDivide` produces a description, not a result.

In TypeScript Effect, descriptions compose with generator syntax:

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

Library systems require this description/execution split.
The library controls execution; everything above the boundary is description.

Libraries in this family include ZIO, Cats Effect, and Kyo in Scala;
polysemy and Effectful in Haskell; and Effect in TypeScript.

## What They Share

The two approaches look different from the outside and work differently on the inside.
But both make Effects visible.
In a native system, the Effect row in a function's signature tells you what that function does.
In a library system, Effects are packaged into the return type.
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
In a library system, the type system rejects code that runs a description
with unsatisfied dependencies or unresolved error types.
The enforcement looks different, but the principle is the same:
you cannot ignore Effects.
The language or library makes you account for them.
