# A Gentle Introduction to Effects

## The Hidden Life of Functions

Imagine you're debugging a test that has started failing intermittently.
The test calls a function you wrote last week.
A function that, by its name and parameters,
simply calculates a total price for a list of items.
The logic looks right.
The math checks out.
But sometimes the test is slow.
Sometimes, if you run it alongside another test,
one of them fails.

You dig in.
Three calls deep, inside a helper that formats currency,
you find it:
a read from a configuration service,
a write to an audit log,
and a network call to fetch the current exchange rate.

None of this appeared in the function signature.
None of it was in the name.
To discover what this function actually does,
you had to read every line,
and every line of everything it calls.

Most functions in most programs have a hidden life like this.
They reach out to databases, files, shared state,
services running somewhere else entirely.
They log. They cache. They throw exceptions
that travel up call stacks invisible from the call site.
None of that is inherently wrong.
A program that never reached out would be useless.
But when this reaching-out is invisible,
when it hides behind ordinary-looking function calls,
the code becomes hard to reason about.

Can you call this function in a test without mocking half the world?
If you call it twice with the same arguments, do you get the same result?
Does it behave differently in a different environment?
Does it fail silently, or loudly, or not at all?

You cannot answer any of these questions by reading the function's signature.
You have to read the implementation.
You must trust that you found everything it depends on,
everything it changes,
everything that might go wrong.

This gap, between what a function's signature tells you
and what the function actually does,
turns out to be a fundamental problem.
This problem shows up wherever programs get complex enough to matter.

## What Is an Effect?

The things that function was doing all have something in common.
Reading configuration, writing to the audit log, fetching the exchange rate:
none of them were part of computing a return value.
They were interactions with the world outside the function.

We have a word for those interactions: **effects**.

An effect is anything a function does beyond computing its return value.
When a function reads from a database, that is an effect.
When it writes to a log, that is an effect.
When it throws an exception, modifies a shared counter,
or sends a request to another service, those are effects too.

Consider a function that takes two numbers and returns their sum.
It needs nothing from the world beyond its arguments.
It leaves no trace.
Call it a hundred times and get the same result each time.
That function has no effects.

Most useful functions are not like that.
They need things from the world.
They leave traces in the world.
The concept of an effect draws a line between the two:
computation on one side, interaction with the outside world on the other.

That line matters because the two sides behave differently.
You can reason about computation by reading code alone.
To reason about effects, you need context:
what environment the function runs in,
what state the world is in when it executes,
what might fail, what might change.

When effects are invisible, when nothing in the code signals their presence,
that context is hidden.
That is the problem the previous section described.
This is its name.

## A Tour of Common Effects

That definition covers a lot of ground.
Effects come in distinct flavors, and most programs contain all of them.

The most familiar is **state**: reading or modifying a value outside the function's own scope.
A method that increments a counter on its object has a state effect.
A function that reads from a global configuration object has a state effect.
So does any function that mutates its arguments.
State effects are the ones most often left implicit.
The counter increments, the configuration gets read,
and nothing in the function's signature mentions either.

**I/O** covers interactions with the world beyond the program's own memory:
writing to the console, reading from a file, sending a network request.
These are slow compared to computation, they can fail for reasons outside your control,
and they are often irreversible.
You can reset a counter.
You cannot un-send a request.

**Exceptions** are effects too, though programmers rarely think of them as such.
When a function throws, it does not return a value in the ordinary sense.
It jumps to a catch block somewhere up the call stack, bypassing everything in between.
The function's return type says nothing about this possibility.
You can read a signature and have no idea whether calling that function
might skip its caller entirely and surface twenty frames up.

**Concurrency** enters when a function coordinates with computations running in parallel.
Acquiring a lock, posting to a message queue, waiting for another task to complete:
these are effects because they involve something outside the function's own thread of execution.
A function that looks simple acquires a lock the caller already holds, and the program deadlocks.
Nothing in the signature warned you.

**Nondeterminism** is the subtlest kind.
A nondeterministic function can return different results given identical inputs.
Reading the current time, generating a random number, sampling from a sensor:
call any of these twice and you may get two different answers.
The function's behavior depends on the state of the world at the moment it runs,
and that dependency is invisible from the outside.

Each of these is different in character.
But they share a common shape: something extra happens, beyond the return value.
That something is what a programmer needs to track, test around, and reason about.
And in most languages, nothing makes it visible.

## Why Effects Matter

Effects are not optional.
Consider a program that only computes return values, touching nothing else,
produces no output, stores nothing, communicates with no one.
The effects are the work.

The problem is not that effects exist.
The problem is what happens when they are invisible.

Consider what the invisible effects in that opening example cost.
They made the test slow, because nothing indicated it needed a running service.
They made tests interfere with each other, because nothing indicated they shared state.
They required reading three levels of implementation to diagnose a simple failure.
Every one of those costs came from the same source: the effects were hidden.

That cost scales.
In a small codebase, you can hold enough context in your head to stay ahead of it.
In a large one, you cannot.
A function you understand today gets called by a function written next week,
which gets called by code a colleague writes next month.
Each step adds invisible dependencies.
No one has the full picture.

The symptoms are familiar: tests that only fail when run together,
bugs that reproduce in production but not in development,
refactorings that break things they should never have touched.
These are not random failures.
They are the predictable result of effects flowing through a codebase
with nothing to mark their path.

Think of it as invisible wiring.
A building needs wiring to function,
but if it runs through the walls with no diagram,
every renovation is a hazard.
You cannot safely move a wall without knowing what runs through it.
Programs have the same problem.
Effects connect functions to the world and to each other.
When those connections are untracked, every change is a guess.
