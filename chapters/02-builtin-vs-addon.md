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
