# Continuations

Every time a program calls a function,
it implicitly records a promise:
when this function returns,
resume here, with this value, and carry on.

That promise is a **continuation**.
It is the rest of the computation from a given point —
every step that remains between here and the program finishing.

In ordinary code the continuation is never named.
It lives in the call stack, and the machine manages it automatically.
When `greet` calls `readLine`,
the call stack records that when `readLine` returns,
`greet` should pick up where it left off,
bind the result to `name`,
and continue.
You do not write this.
The language handles it.

## You have already been using them

The continuation surfaces whenever synchronous and asynchronous code mix.
A callback is an explicit continuation:

```typescript
readLine((name) => {
  console.log("Hello, " + name)
})
```

The function passed to `readLine` is the rest of the computation after `readLine` finishes.
That rest was always implicit.
The callback makes it a value you hand over explicitly.

`async`/`await` hides the callback but does the same thing under the hood:

```typescript
const name = await readLine()
console.log("Hello, " + name)
```

When `await` suspends,
the runtime captures a continuation —
"resume at this line with `name` bound to whatever the promise resolves to" —
and invokes it later.
The continuation exists; you just do not see it.

Exceptions work by abandoning continuations.
When you throw, the runtime walks up the call stack looking for a matching `catch`.
Everything between the throw site and the catch block —
all those waiting continuations —
is discarded.
Throwing does not resume the computation; it discards it.

## What explicit continuations make possible

A runtime that lets you manipulate continuations directly gives you more than async/await provides.
Async/await can resume a suspended computation once, when a promise resolves.
An explicit continuation can be invoked any number of times, or not at all,
by whoever holds it.

Calling it once is what async/await does.
Not calling it is what throwing an exception does.
Calling it more than once is something neither callbacks nor exceptions can express.
A retry mechanism can capture the continuation at a failed operation
and invoke it again with a fresh value.
A backtracking search can invoke the same continuation once for each candidate answer,
collecting results, then discard it when no more answers exist.
These patterns require nothing more than a continuation and the freedom to call it when you choose.

## Continuations in effect handlers

Native effect systems are built atop continuations.

When a function performs an effect operation,
execution suspends and control passes to the current handler.
The handler receives the operation's arguments.
It also receives the continuation:
everything the function would do after that operation returns.
The handler decides what to do with it.

In Koka, `ctl` operations receive the continuation as a callable named `resume`:

```koka
with handler
  ctl ask(prompt)
    resume("Alice")  // resume the computation with a fixed value
action()
```

<!-- VERIFY: Koka ctl handler syntax, with handler block, resume call -->

Calling `resume("Alice")` causes the computation that called `ask` to continue
as if `ask` had returned `"Alice"`.
Not calling `resume` discards the continuation —
execution ends at the handler,
the same as an uncaught exception.
Calling `resume` multiple times replays the computation from the `ask` call
with a different value each time.

Koka's simpler `fun` form of a handler makes the continuation implicit.
The handler body runs,
and execution automatically returns to the call site with the result.
`fun` is appropriate when an operation always completes normally.
`ctl` is for operations that need explicit control over whether and how resumption happens —
including operations that might not resume at all.

Continuations are why effect handlers are strictly more expressive than exceptions.
An exception handler can only catch a thrown value or let it propagate.
An effect handler can resume once, resume with a different value,
resume multiple times, or discard the continuation entirely.
That range is why native effect systems can model
not just failure but also state, iteration, backtracking, and cooperative scheduling —
all as ordinary function calls with swappable handlers.
