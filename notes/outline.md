# Understanding Effects — Chapter Outline

## Chapter 1: A Gentle Introduction to Effects

### The Hidden Life of Functions
- A familiar scenario: a function that looks pure but isn't
- The gap between a function's signature and what it actually does

### What Is an Effect?
- Definition: anything a function does beyond computing a return value
- Effects as observable interactions with the world outside the function

### A Tour of Common Effects
- State: reading or modifying values beyond the function's scope
- I/O: interacting with the outside world (console, files, network)
- Exceptions: signaling failure and altering control flow
- Concurrency: coordinating with other computations
- Nondeterminism: producing different results under the same inputs
- The unifying thread: all are "something extra" happening

### Why Effects Matter
- Effects are everywhere — most useful programs are effectful
- Unmanaged effects make programs hard to reason about, test, and compose
- The invisible wiring problem: when effects are implicit, bugs hide

### The Central Tension
- Effects are necessary but dangerous when uncontrolled
- What would it mean for a language to help us manage them?


## Chapter 2: Effect Systems — Native vs Library

### Two Paths to the Same Problem
- Different languages have taken fundamentally different approaches
- The split is historical and practical, not theoretical

### Native Effect Systems
- The language tracks effects in the type system alongside ordinary types
- Direct-style code: you write normal-looking sequential programs
- The compiler knows which effects a function performs
- Pseudocode examples in Koka: declaring and handling effects
- Languages in this family: Koka, Eff, Effekt, Unison, Flix

### Library Effect Systems
- Languages not originally designed around effects
- Libraries provide effect management on top of existing type systems
- The key mechanism: constructing descriptions of programs, not executing them directly
- Examples in Scala/ZIO: building and interpreting effect descriptions
- Libraries in this family: ZIO, Cats Effect, Kyo (Scala); polysemy, effectful (Haskell)

### Why the Split Exists
- Some languages were designed from scratch with effects as a goal
- Others had thriving ecosystems and needed a compatible retrofit
- Neither approach is wrong — they reflect different design priorities

### What They Share
- Both make effects visible rather than implicit
- Both separate what effects a computation performs from how they are handled
- Both enable the compiler or runtime to enforce effect discipline


## Chapter 3: What Your Effect System Asks of You

### No Free Lunch
- An effect system changes how you think and write code
- The two approaches change it in different ways
- Understanding the tradeoffs lets you choose wisely

### The Native Experience
- Declaring effects on functions — an extension of what you already do with types
- Performing effects: looks like a function call, acts like a function call
- Writing handlers: similar to catch blocks, but generalized
- Mental model: "perform and handle" — close to how you think about exceptions

### The Library Experience
- A different mental model: description then execution
- Building programs as values — nothing runs until you say so
- Composing descriptions with combinators
- The interpreter/runtime as the boundary between description and action

### Delayed Execution: An Artifact, Not a Feature
- Delayed execution is not intrinsic to effect management
- It emerged as a byproduct of the library mechanism
- Native systems prove the separation of concerns is achievable without it
- The cost: a conceptual layer the programmer must internalize and manage

### Living with Each Approach
- Composability: free composition vs. transformer stacking
- Testability: both enable substitution, through different mechanisms
- Error messages and debugging: how each approach surfaces problems
- Learning curve: direct style vs. the description/execution split
- API design: how each approach shapes the interfaces you write

### Choosing Your Tradeoffs
- Library systems: enormous ecosystem investment, battle-tested runtimes, broad adoption
- Native systems: conceptual elegance, lower cognitive overhead, direct-style clarity
- The reader should leave equipped to evaluate either approach for their own context
