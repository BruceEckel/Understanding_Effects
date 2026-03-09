# Style Decisions and Vocabulary Guide

## Vocabulary

### Use These Terms
- **effect** — anything a function does beyond computing a return value
- **built-in effect system** — a language where effects are tracked in the type system by design (replaces "algebraic effects" for the reader)
- **add-on effect system** — a library that provides effect management on top of an existing language (replaces "monadic effects" for the reader)
- **handler** — the construct that determines how an effect is fulfilled
- **perform** — invoking an effect operation (Koka uses this naturally)
- **artifact** — specifically for delayed execution: a byproduct of the add-on mechanism, not intrinsic to effect management
- **direct style** — code that looks like normal sequential programming
- **description/execution split** — the mental model required by add-on systems

### Avoid These Terms (or Use With Care)
- **monad** — do not use in the main text; if absolutely necessary, footnote it for readers who want to look it up
- **algebraic effects** — use "built-in" instead; can appear in a footnote or "for further reading"
- **functor**, **applicative** — unnecessary for this audience
- **flatMap** — show it in add-on code examples but don't make it a vocabulary word; describe what it does without naming the abstraction
- **pure/impure** — use sparingly; prefer "effectful" vs "effect-free" to avoid the moralistic connotation
- **referential transparency** — too formal for Chapter 1; introduce the concept without the jargon

## Code Examples

### Chapter 1
- No code at all
- Use plain-language descriptions and familiar analogies

### Chapter 2 — Built-in Examples
- Use **Koka** as primary, **Flix** as secondary (same concept, different notation)
- Keep examples short and focused on one concept each
- Annotate with comments explaining what the effect annotations mean
- Show the progression: function without effects → function with declared effects → handler

### Chapter 2 — Add-on Examples
- Use **Scala with ZIO** as primary, **TypeScript with Effect** as secondary
- Show the shape of the code without explaining the monadic machinery
- Focus on what the programmer sees: for-comprehensions/generators, the description type signature, the runtime boundary
- Let the reader notice the description/execution split without being lectured about it

### Chapter 3
- Use Koka and Flix for built-in, Scala/ZIO and Effect.ts for add-on
- Side by side where the contrast matters; keep examples parallel

## Tone

- Technically precise but conversational
- Active voice throughout
- Concise — no padding, no filler
- Respect the reader's intelligence without assuming FP background
- No condescension toward either approach
- Ground abstract concepts in problems the reader has already experienced
- When introducing a new idea, lead with the problem it solves, not the solution itself

## Sentence Style

- Prefer periods over em-dashes — break compound thoughts into separate sentences rather than bridging them with a dash
- Split compound sentences at "and": "slow, and sometimes X" becomes "slow. Sometimes X"
- Avoid trailing relative clauses ("one that...", "something that...") — repeat the noun and start a new sentence instead
- Bridge continuations ("and then X", "and trust that") should become new sentences with an explicit subject
- Cut redundant words aggressively; if context makes a word obvious, remove it

## Formatting

- Semantic line breaks in markdown source
- Minimal use of bold — reserve for terms being defined
- No bullet-point lists in prose (write in paragraphs)
- Code blocks should be short (under 15 lines where possible)
- Section headings should be evocative, not descriptive ("The Hidden Life of Functions" not "Introduction to Side Effects")


If unsure about Koka or ZIO syntax details, add a 
<!-- VERIFY: description of uncertainty --> comment 
in the markdown rather than guessing.
