# A Gentle Introduction to Effects

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
you had to know every line,
and every line of everything it calls.

Most functions in most programs have this hidden life.
They reach out to databases, files, shared state,
services running somewhere else entirely.
They log. They cache. They throw exceptions
that travel up call stacks invisible from the call site.

A program that never reached out would be useless.
But when this reaching-out is invisible,
when it hides behind ordinary-looking function calls,
the code becomes hard to reason about:

- Can you call this function in a test without mocking half the world?
- If you call it twice with the same arguments, do you get the same result?
- Does it behave differently in a different environment?
- Does it fail silently, loudly, or not at all?

You cannot answer these questions by reading the function's signature.
You must know the implementation.
You must trust that you found everything it depends on,
everything it changes,
everything that might go wrong.

This gap, between what a function's signature tells you
and what the function actually does,
turns out to be a fundamental problem.
This problem shows up wherever programs get complex enough to matter.

## The Leaky Abstraction

Let’s create a function that moves us in a direction at a velocity. Here’s a logical approach:

```
def travel(d: Direction, v: Velocity): Distance = {  
  ...  
}
```

When we call `travel` we decide what direction and velocity we want to use. But to implement this function we’ll need some kind of motive force. Suppose there is an `engine` library:

```
import engine

def travel(d: Direction, v: Velocity): Distance = {  
  ...  
  engine.go(speed = 50)  
  ...  
}
```

We construct code by using libraries. This is a powerful approach and it has gotten us far. 

There's a big problem when using libraries. 
This abstraction assumes there will be no repercussions from using `engine`, 
that it's just a magical black box we don't have to think about. 
If that happens to be true for a library, there's nothing to worry about.

With `engine`, however, that's probably not the case. 
Engines are complicated beasts; they require fuel and lubrication, 
they generate heat, they need maintenance, they can fail. 
Sometimes they halt and catch fire. 
It's basically a global variable that we are un-traceably modifying in `travel`. 
Treating it as a pure black box with no side effects is probably asking for trouble. 

It's a leaky abstraction, and you must compensate using careful and tedious coding. 
Without a type system to handle the bookkeeping and ensure nothing slips through, 
you can only keep track of what you can hold in your head. 
This challenge has limited the scale of systems since we began building them.

The main problem is that we sneak `engine` into `travel`: 
the function signature for `travel` doesn't show that we use the problematic `engine` in the implementation.
We just use it directly in our code as if there are no consequences.

One solution is to add this information into the argument list:

```
def travel(d: Direction, v: Velocity, e: engine): Distance = {  
  ...  
  e.go(speed = 50)  
  ...  
}
```

Now it's clear that `travel` uses an `engine`, and we have the added bonus that the particular implementation of `engine` can be determined at the function call site\!

Doing this for every library gets tedious fast. It appears there are function arguments that we want to vary regularly, and those that might be set up at the beginning and never change. Default arguments don’t help here because there must always *be* a default. There might be a default `engine` but in the general case you want something customized for your needs.

We can use dependency injection to initialize the `engine`–along with any other libraries we use–thus removing the need to provide them at the call site. But this complicates the ability of the dependency injector to know that `travel` uses `engine`, so it falls back on the programmer. And if `engine` itself requires other libraries, the dependency injector must discover those and provide them for `engine` before providing `engine` to `travel`. Without somehow capturing that information in the type system, the dependency injector eventually succumbs to scaling problems.

What if we create an additional channel to convey this information? This way, we can separate the information we typically want to provide at every function call (direction and velocity) from the information that normally stays the same across function calls. We still have the option to change the latter information between function calls but we don’t have to trip over it every time we call the function. It can be expressed like this:

```
def travel(d: Direction, v: Velocity): Distance \ engine = {  
  ...  
  engine.go(speed = 50)  
  ...  
}
```

Now `engine` is part of the type signature without encumbering the argument list. 

* Previously we were implicitly using `engine`, an element global to `travel` that has its own state. Now it is explicit.  
* The compiler ensures `engine` appears in the type signature.   
* If another function uses `travel`, it too must indicate in its type signature that `engine` is being used.  
* When a dependency injector needs to know what `travel` uses, it can see it in the signature.   
* If the system changes the implementation of `engine`, we immediately know what functions are affected. 

The fact that `engine` has an impact on the system is now visible to the compiler, and ensured through type checking. Using this second channel, we provide that information without mucking up the argument list.

## What Is an Effect?

An Effect is an interaction with the world outside the function.
Common examples include:

- Reading configuration
- Writing to the audit log
- Fetching the exchange rate
- Reading from a database
- Writing to a log
- Throwing an exception
- Modifying a shared counter
- Sending a request to another service

Consider a function that takes two numbers and returns their sum.
It needs nothing from the world beyond its arguments.
It leaves no trace.
Call it a hundred times and get the same result each time.
That function has no effects.

Many functions are not like that.
They need things from the world.
They leave traces in the world.
The concept of an effect draws a line between the two:
computation on one side, interaction with the outside world on the other.

That line matters because the two sides behave differently.
You can reason about computation by reading code alone.
To reason about effects, you need context:

- What environment the function runs in
- What state the world is in when it executes
- What might fail
- What might change

When effects are invisible, when nothing in the code signals their presence,
that context is hidden.
This means you must keep track of effects yourself.
You must discover and understand the effects of your code by reading its documentation, testing it, and observing its behavior.
Because we can't always trust documentation (it may be outdated, incomplete, or wrong), you must be ready to read the source code of the functions you call.

When programs are small, these are relatively manageable activites.
As systems scale, these activities become increasingly challenging.
A large portion of programming activity is consumed through managing effects by hand.

## A Taxonomy of Common Effects

The most familiar Effect is `state`: reading or modifying a value outside the function's own scope.
A method that increments a counter on its object has a state effect.
A function that reads from a global configuration object has a state effect.
So does any function that mutates its arguments.
State effects are the ones most often left implicit.
The counter increments, the configuration gets read,
and nothing in the function's signature mentions either.

`I/O` covers interactions with the world beyond the program's own memory:
writing to the console, reading from a file, sending a network request.
These are slow compared to computation, they can fail for reasons outside your control,
and they are often irreversible.
You can reset a counter.
You cannot un-send a request.

`Exceptions` are effects too, though programmers rarely think of them as such.
When a function throws, it does not return a value in the ordinary sense.
It jumps to a catch block somewhere up the call stack, bypassing everything in between.
The function's return type says nothing about this possibility.
You can read a signature and have no idea whether calling that function
might skip its caller entirely and surface twenty frames up.

`Concurrency` enters when a function coordinates with computations running in parallel.
Acquiring a lock, posting to a message queue, waiting for another task to complete:
these are effects because they involve something outside the function's own thread of execution.
A function that looks simple acquires a lock the caller already holds, and the program deadlocks.
Nothing in the signature warned you.

`Nondeterminism` is the subtlest kind.
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

## The Central Tension

You cannot write useful programs without effects.
They are not incidental. They are the point.
When a user clicks a button, something must happen.
When data must persist, it must be written somewhere.
When two services must coordinate, they must communicate.
Remove all effects, and you have removed everything the program was built to do.

The tension is not between effects and correctness.
It is between effects and visibility.

A program with explicit effects has the same power as one where effects are hidden.
It can still read from databases, write to logs, throw exceptions, coordinate across threads.
But the programmer working on it, the test suite validating it, and the compiler processing it
all know what each function does.
The wiring has a diagram.

The question is whether a language can draw that diagram.
Whether the mechanisms that make type errors visible at compile time
can make effect errors visible too.
Whether the compiler can tell you, before you run anything,
that a function you expected to be effect-free is secretly reaching out to the network.
Whether the things now only discoverable by reading every line
can instead be right there, in the interface.

This question is answered in the rest of this book.
