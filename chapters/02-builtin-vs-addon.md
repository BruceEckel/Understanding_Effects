# Effect Systems: Built-in vs Add-on

## Two Paths to the Same Problem

Languages have been grappling with the effect visibility problem for decades,
and they have not all arrived at the same answer.
Some languages were designed from the start with effects as a first-class concern.
Others found effect management as a later need,
addressed by libraries that work within the constraints of existing language designs.

These two families look different from the inside.
Programs written in the first family look like ordinary sequential code.
Effect information lives in type signatures, tracked by the compiler.
Programs written in the second family work differently:
you construct descriptions of what a program should do, then execute those descriptions.

The difference is not philosophical.
It did not arise because one school of thought was right and another wrong.
It arose from the history of specific languages and their communities:
what problems they were designed to solve,
when they were designed,
and what constraints they had to work within.

This chapter looks at both families and where the difference comes from.

## Built-in Effect Systems

In a built-in effect system, effects live in the type system alongside ordinary types.
A function's signature carries two pieces of information: what it returns, and what effects it performs.
Both are visible in the signature.
Neither requires reading the implementation to discover.

The code itself looks like ordinary sequential programming.
You call functions, bind values, return results.
The compiler observes what you call and tracks the effects,
the same way it tracks whether a value is an integer or a string.

Here is what that looks like in Koka, a language built around this approach.
A function with no effects shows only a return type.
A function with effects names them in the signature:

```koka
// No effects: takes two ints, returns an int, nothing else
fun add(x: int, y: int): int
  x + y

// Console effect: the signature declares it openly
fun greet(name: string): <console> ()
  println("Hello, " ++ name)
```

The angle brackets hold the **effect row**: the set of effects this function performs.
`add` has an empty effect row, so nothing appears there.
`greet` performs console I/O, so `<console>` appears in its signature.

Notice where that information lives: in the type, not the argument list.
A caller sees what `greet` does without `greet` needing to accept the console as a parameter.
The effect row is a dedicated channel for this information,
separate from inputs and separate from the return value.

Effect annotations propagate automatically.
If a function calls `greet`, the compiler adds `console` to its own effect row.
The compiler infers them from what you call.
You can annotate explicitly when you want to constrain what a function is allowed to do.

Effects also need to be fulfilled somewhere.
Something must decide what actually happens when a function signals a failure,
or asks for a configuration value, or reaches for the console.
In a built-in system, that mechanism is the **handler**:
a construct that intercepts an effect and provides its implementation.

Here is a custom effect and a handler that gives it meaning:

```koka
// Declare a custom effect: this computation can signal failure
effect fail
  ctl fail(msg: string): a

// A function that uses the effect — the signature names it
fun safe-divide(x: int, y: int): <fail> int
  if y == 0 then fail("division by zero")
  else x / y

// A handler: decides what "fail" means in this context
fun with-default(default: int, action: () -> <fail> int): int
  with handler
    ctl fail(_msg) -> default
  action()

// with-default(0) { safe-divide(10, 0) }  =>  0
// with-default(0) { safe-divide(10, 2) }  =>  5
```

<!-- VERIFY: Koka effect declaration syntax (effect/ctl), handler syntax (with handler / ctl), and angle-bracket effect row in signatures -->

`safe-divide` does not decide what happens when division fails.
Its caller installs a handler that makes that decision.
The effect in the type ensures you cannot call `safe-divide` in a context
where failure has no handler — the compiler catches that before you run anything.

The code reads sequentially.
The effects are visible in the types.
The handlers connect effects to implementations.

Flix takes the same approach with different notation.
Effects appear after a backslash in function signatures
rather than in angle brackets,
but the information occupies the same position:
what the function returns, and what it does beyond that.

```flix
// No effects: signature shows only the return type
def add(x: Int32, y: Int32): Int32 = x + y

// IO effect declared after the backslash
def greet(name: String): Unit \ IO =
    println("Hello, ${name}")

// A custom effect and a function that uses it
eff Fail {
    def fail(msg: String): a
}

def safeDivide(x: Int32, y: Int32): Int32 \ Fail =
    if (y == 0) do Fail.fail("division by zero")
    else x / y
```

<!-- VERIFY: Flix backslash effect set notation, eff/def declaration syntax inside eff block, do keyword for performing effects, IO effect name -->

Angle brackets or backslash, the discipline is the same:
effects in the signature, inferred by the compiler,
required to be handled before execution proceeds.

Languages in this family include Koka, Eff, Effekt, Unison, and Flix.

## Add-on Effect Systems

Not every language with a thriving ecosystem could be rebuilt from scratch.
Java, Scala, and Python had decades of libraries, tooling, and production code.
Redesigning their type systems around effects was not an option.

Library authors found a different path.
Rather than asking the compiler to track effects natively,
they used the existing type system to encode effect information into the types of values.
The approach works, but it requires a shift in mechanism:
instead of writing a computation and having the compiler observe its effects,
you build a **description** of a computation and execute that description later.

In ZIO, a widely-used Scala library, that description is a value of type `ZIO[R, E, A]`.
The three type parameters carry the effect information:
`R` is the environment the computation requires,
`E` is the type of error it can produce,
and `A` is the type of value it produces on success.

```scala
// A description of a computation that:
// - requires no environment (Any)
// - can fail with an exception (Throwable)
// - produces an Int on success
def safeDivide(x: Int, y: Int): ZIO[Any, Throwable, Int] =
  ZIO.attempt(x / y)

// Nothing has run. safeDivide returns a description, not a result.
```

You combine descriptions using for-comprehensions —
Scala's syntax for chaining operations where each step can use the result of the previous one:

```scala
val program: ZIO[Any, Throwable, Unit] =
  for
    line <- ZIO.attempt(readLine())
    _    <- ZIO.attempt(println(s"Hello, $line"))
  yield ()
```

`program` is still a value.
Nothing has run.

Execution happens at a single boundary, the runtime entry point:

```scala
object Main extends ZIOAppDefault:
  def run = program
```

Everything above `run` is description.
`run` is where description becomes action.

This boundary is not incidental. It is the mechanism.
The compiler sees what effects a function might perform by looking at its return type,
the same way it inspects any other type.
But the effects are encoded in a library type, not tracked natively by the language.

Effect, a TypeScript library, uses the same approach.
Its description type is `Effect<Success, Error, Requirements>` —
the type parameters carry effect information in the same three roles,
with different names.

```typescript
// A description that can fail with Error, requires no environment
const safeDivide = (x: number, y: number): Effect.Effect<number, Error> =>
  y === 0
    ? Effect.fail(new Error("division by zero"))
    : Effect.succeed(x / y)

// Nothing has run. safeDivide returns a description, not a result.
```

Descriptions compose using generator syntax:

```typescript
const greet: Effect.Effect<void> = Effect.gen(function* () {
  const line = yield* Effect.sync(() => readLineSync())
  yield* Effect.sync(() => console.log(`Hello, ${line}`))
})
```

`greet` is still a value. Nothing has run.

Execution happens at the boundary:

```typescript
Effect.runSync(greet)
```

<!-- VERIFY: Effect.ts type parameter order (Effect<A, E, R>), generator yield* syntax, Effect.sync for wrapping synchronous side effects, runSync vs runPromise -->

The description/execution split works identically in TypeScript.
The library controls execution; everything above the boundary is description.

Libraries in this family include ZIO, Cats Effect, and Kyo in Scala;
polysemy and effectful in Haskell; and Effect in TypeScript.

## Why the Split Exists

The two families did not emerge from competing theories about the right way to manage effects.
They emerged from different starting points.

Languages like Koka and Eff were designed from scratch by researchers
whose central goal was exploring what a language built around effects could look like.
With no existing codebase to preserve and no compatibility constraints to honor,
they could put effects into the type system at the foundation.
Everything else in the language was built around that choice.

Scala arrived at its approach by a different route.
It had years of production use, a large library ecosystem, and deep interoperability with Java.
Redesigning the language's type system from scratch was not possible.
But Scala's type system was expressive enough that library authors could encode effect information
into types without any compiler changes.
ZIO and Cats Effect are the result: full-featured effect systems built entirely as libraries,
working within the language as it already existed.

The constraint shaped the mechanism.
The description/execution split is a natural consequence of encoding effects into values
in a language that was not designed for them.
To track whether a function is effectful, the type must carry that information.
To make that type meaningful, execution must be deferred to a boundary the library controls.
That is what makes the mechanism work.

Neither starting point was wrong.
A language designed around effects from the ground up can offer things a library cannot.
It can provide tighter compiler integration, cleaner error messages,
and syntax that feels native rather than adapted.
A library built on top of an established language brings something different:
the entire ecosystem of that language, its tooling, its community,
and years of production experience.
Choosing between them is not a matter of correctness.
It is a matter of context.

## What They Share

The two families look different from the outside and work differently on the inside.
But they share something worth naming before moving on.

Both make effects visible.
In a built-in system, the effect row in a function's signature tells you what that function does.
In an add-on system, the type parameters of the description type tell you the same thing.
The mechanism is different.
The result is the same: effects you can see without reading the body.

Both separate the declaration of effects from their implementation.
In Koka, a function declares a `<fail>` effect without deciding what failure means.
A handler somewhere up the call stack makes that decision.
In ZIO, a function returns a `ZIO[R, E, A]` without deciding what environment it runs in
or how its errors are resolved.
The caller provides that through configuration.
Neither the function nor the description owns the implementation of its own effects.

Both let the compiler or runtime enforce effect discipline.
In a built-in system, the compiler rejects code that uses an unhandled effect.
In an add-on system, the type system rejects code that runs a description
with unsatisfied dependencies or unresolved error types.
The enforcement looks different, but the principle is the same:
you cannot ignore effects. The language, or the library, makes you account for them.

These three properties are what distinguish an effect system, of either kind,
from the invisible effects of Chapter 1.
The question is no longer whether effects exist.
It is how they are declared, who handles them, and what happens when you fail to account for them.

The next chapter looks at what living with those answers actually feels like.
