# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Understanding Effects

A three-chapter opening section for a book on effect systems in programming.

## Audience

Mainstream programmers (Java, Python, TypeScript background) who have never encountered formal effect systems. No assumed functional programming knowledge. Technically precise but accessible.

## Structure

Three chapters in a section titled "Understanding Effects":

1. **A Gentle Introduction to Effects** — What effects are, why they matter, no code
2. **Effect Systems: Native vs Library** — Two families of solution and how they arose
3. **What Your Effect System Asks of You** — Programmer-facing consequences and tradeoffs

See `notes/outline.md` for the detailed chapter outline.

## Key Decisions

- Use "native" and "library" instead of "algebraic" and "monadic"
- Delayed execution is framed as an **artifact** of the library approach, not intrinsic to effect management
- Avoid the word "monad" — show the shape of library systems without naming the underlying abstraction
- Chapter 1 has no code — purely conceptual, grounded in problems the reader already feels
- Native examples use **Koka** and **Flix** syntax (both purpose-built around effects, different notations)
- Library examples use **Scala/ZIO** and **Effect.ts** real syntax, showing the pattern without naming monads
- Chapter 1 must establish why mainstream programmers should care, in terms they already feel — not "effects are a formal concept" but "you've been bitten by this problem"

## Writing Style

- Active voice
- Concise explanations — no padding
- Technically precise but never academic
- Push back on oversimplified framing
- Use semantic line breaks in markdown source
- No condescension toward the reader or toward any approach (library systems are not "worse," they have different tradeoffs)
- Write in prose paragraphs — no bullet-point lists in body text
- Reserve **bold** for terms being defined; use sparingly otherwise
- Keep code blocks under 15 lines where possible

### Sentence Style

- Prefer periods over em-dashes — break compound thoughts into separate sentences
- Split at "and": "slow, and sometimes X" → "slow. Sometimes X"
- Avoid trailing relative clauses ("one that...", "something that...") — repeat the noun and start a new sentence
- Bridge continuations ("and then X", "and trust that") become new sentences with an explicit subject
- Cut redundant words aggressively

### Vocabulary to Use

| Term | Meaning |
|------|---------|
| **effect** | anything a function does beyond computing a return value |
| **native effect system** | language where effects are tracked in the type system by design |
| **library effect system** | library providing effect management on top of an existing language |
| **handler** | the construct that determines how an effect is fulfilled |
| **perform** | invoking an effect operation |
| **artifact** | specifically for delayed execution: a byproduct of the mechanism, not intrinsic |
| **direct style** | code that looks like normal sequential programming |
| **description/execution split** | the mental model required by library systems |

### Vocabulary to Avoid

- **monad** — do not use in main text; footnote if absolutely necessary
- **algebraic effects** — use "native" instead; footnote or "further reading" only
- **functor**, **applicative** — unnecessary for this audience
- **flatMap** — show in code examples but never make it a vocabulary word
- **pure/impure** — prefer "effectful" vs "effect-free" (avoids moralistic connotation)
- **referential transparency** — too formal; introduce the concept without the jargon

## File Layout

```
chapters/
  01-gentle-introduction.md
  02-native-vs-library.md
  03-what-your-effect-system-asks.md
notes/
  outline.md            — detailed section-by-section chapter outline
  style-decisions.md    — vocabulary guide and code example conventions
resources/
  DelayedExecution.md   — reference on why library systems require delayed execution
  New Introduction.md   — draft alternative introduction material
examples/
  prompt.md             — spec for the four-language introductory example
                          (Ask/Tell/Store/Fetch in Koka, Flix, Scala ZIO, Effect.ts)
```

When unsure about Koka, Flix, ZIO, or Effect.ts syntax, add a `<!-- VERIFY: description of uncertainty -->` comment rather than guessing.

## Workflow

- Write one chapter at a time, iterate to completion before moving to the next
- Within each chapter, work section by section
- Chapter 1 first (establishes voice and abstraction level)
- Chapter 2 second (settles pseudocode conventions)
- Chapter 3 last (draws on everything before it)