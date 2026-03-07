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
