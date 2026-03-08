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

The angle brackets hold the **effect row** — the set of effects this function performs.
`add` has an empty effect row, so nothing appears there.
`greet` performs console I/O, so `<console>` appears in its signature.

Effect annotations propagate automatically.
If a function calls `greet`, the compiler adds `console` to its own effect row.
You do not have to declare your effects manually — the compiler infers them from what you call.
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
Languages in this family include Koka, Eff, Effekt, Unison, and Flix.
