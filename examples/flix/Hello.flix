// Introductory effect example in Flix.
// One effect: Tell.
// The implementation (handler) in main is swappable without changing the logic.

// --- Effect declaration ---

eff Tell {
    pub def tell(message: String): Unit
}


// --- Core logic ---

def hello(): Unit \ Tell =
    Tell.tell("Hello, World!")


// --- Main: wire up console handler ---

def main(): Unit \ IO =
    run {
        hello()
    } with Tell {
        def tell(message, resume) =
            println(message);
            resume()
    }


// =============================================================================
// SYNTAX GUIDE
// =============================================================================
//
// EFFECT DECLARATION
//
//   eff Tell {
//       pub def tell(message: String): Unit
//   }
//
// The `eff` keyword declares a named effect. Inside the braces, `pub def`
// lists the operations this effect exposes. `tell` takes a String and returns
// Unit (nothing useful). This is the interface — the what, not the how.
//
//
// EFFECT ANNOTATION
//
//   def hello(): Unit \ Tell =
//
// The backslash `\` separates the return type from the effect set. `Unit \ Tell`
// means: returns nothing, and may perform the Tell effect. Flix tracks effects
// in the type system; calling `Tell.tell(...)` without this annotation would
// be a type error.
//
//
// PERFORMING AN EFFECT
//
//   Tell.tell("Hello, World!")
//
// Effect operations are called through their effect name: `Tell.tell(...)`.
// This performs the effect. What actually happens depends on the handler
// installed by the caller.
//
//
// THE HANDLER
//
//   run {
//       hello()
//   } with Tell {
//       def tell(message, resume) =
//           println(message);
//           resume()
//   }
//
// `run { ... } with Tell { ... }` runs the block and installs a handler for
// the Tell effect. When `tell` is performed, the handler body executes.
//
// The `resume` parameter is the continuation — a function representing "the
// rest of the program from this point forward." Calling `resume()` passes
// control back to where the effect was performed. For `tell`, which returns
// Unit, we call `resume()` with no argument.
//
// The semicolon `;` separates sequential statements in Flix.
//
//
// EFFECT ON MAIN
//
//   def main(): Unit \ IO =
//
// After the handler is installed, the Tell effect is handled and no longer
// appears in `main`'s type. But `println` is an IO operation, so `main`
// carries `IO` — Flix's native effect for console and file I/O.
