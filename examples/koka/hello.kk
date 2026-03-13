// Introductory effect example in Koka.
// One effect: Tell.
// The implementation (handler) in main is swappable without changing the logic.

// --- Effect declaration ---

effect tell
  fun tell(message : string) : ()


// --- Core logic ---

fun hello() : <tell> ()
  tell("Hello, World!")


// --- Main: wire up console handler ---

fun main() : console ()
  with fun tell(message)
    println(message)
  hello()


// =============================================================================
// SYNTAX GUIDE
// =============================================================================
//
// EFFECT DECLARATION
//
//   effect tell
//     fun tell(message : string) : ()
//
// The `effect` keyword declares a named effect. Inside it, `fun` lists the
// operations that belong to this effect. Here there is one operation, also
// called `tell`, which takes a string and returns `()` (unit — nothing useful).
// This is the interface: it says what can be asked of the effect, not how it
// is answered.
//
//
// EFFECT ROW IN THE TYPE SIGNATURE
//
//   fun hello() : <tell> ()
//
// The angle-bracket portion `<tell>` is the effect row — the set of effects
// this function may perform. The `()` after it is the return type (unit).
// Koka tracks effects in the type system: if a function calls `tell`, the
// compiler requires `tell` to appear in its effect row.
//
//
// PERFORMING AN EFFECT
//
//   tell("Hello, World!")
//
// Calling `tell(...)` inside `hello` performs the `tell` effect. The runtime
// suspends the function and hands control to whichever handler is currently
// installed for `tell`. The handler decides what actually happens.
//
//
// THE HANDLER
//
//   with fun tell(message)
//     println(message)
//   hello()
//
// `with fun tell(message)` installs a handler for the `tell` effect. The body
// (`println(message)`) is what runs whenever `tell` is performed. Using `fun`
// here (rather than `ctl`) means this is a simple resuming handler: after the
// body runs, execution automatically resumes where the effect was performed.
//
// The handler is scoped to the expression that follows it — `hello()` on the
// next line. Every `tell` performed inside `hello()` is caught by this handler.
//
//
// THE `console` EFFECT
//
//   fun main() : console ()
//
// `console` is a native Koka effect covering standard I/O. `println` is a
// console operation, so `main` carries the `console` effect in its type. The
// `tell` effect is handled inside `main` and no longer appears in the row.
