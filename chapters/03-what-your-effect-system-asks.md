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
