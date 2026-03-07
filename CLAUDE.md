# Understanding Effects

A three-chapter opening section for a book on effect systems in programming.

## Audience

Mainstream programmers (Java, Python, TypeScript background) who have never encountered formal effect systems. No assumed functional programming knowledge. Technically precise but accessible.

## Structure

Three chapters in a section titled "Understanding Effects":

1. **A Gentle Introduction to Effects** — What effects are, why they matter, no code
2. **Effect Systems: Built-in vs Add-on** — Two families of solution and how they arose
3. **What Your Effect System Asks of You** — Programmer-facing consequences and tradeoffs

See `notes/outline.md` for the detailed chapter outline.

## Key Decisions

- Use "built-in" and "add-on" instead of "algebraic" and "monadic"
- Delayed execution is framed as an **artifact** of the add-on approach, not intrinsic to effect management
- Avoid the word "monad" — show the shape of add-on systems without naming the underlying abstraction
- Chapter 1 has no code — purely conceptual, grounded in problems the reader already feels
- Built-in examples use **Koka** syntax (purpose-built around effects, clean and readable)
- Add-on examples use **Scala/ZIO** real syntax, showing the pattern without naming monads
- Chapter 1 must establish why mainstream programmers should care, in terms they already feel — not "effects are a formal concept" but "you've been bitten by this problem"

## Writing Style

- Active voice
- Concise explanations — no padding
- Technically precise but never academic
- Push back on oversimplified framing
- Use semantic line breaks in markdown source
- No condescension toward the reader or toward any approach (add-on systems are not "worse," they have different tradeoffs)

## File Layout

```
chapters/
  01-gentle-introduction.md
  02-builtin-vs-addon.md
  03-what-your-effect-system-asks.md
notes/
  outline.md
  style-decisions.md
```

## Workflow

- Write one chapter at a time, iterate to completion before moving to the next
- Within each chapter, work section by section
- Chapter 1 first (establishes voice and abstraction level)
- Chapter 2 second (settles pseudocode conventions)
- Chapter 3 last (draws on everything before it)