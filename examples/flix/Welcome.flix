// Welcome effect example in Flix.
// Two effects: Ask and Tell.
// The implementations (handlers) in main are swappable without changing the logic.

// --- Effect declarations ---

eff Ask {
    pub def ask(prompt: String): String
}

eff Tell {
    pub def tell(message: String): Unit
}


// --- Core logic ---

def greet(): Unit \ {Ask, Tell} =
    let name = Ask.ask("What is your name? ");
    Tell.tell("Hello, ${name}!")


// --- Main: wire up console handlers ---

def main(): Unit \ IO =
    run {
        greet()
    } with Ask {
        def ask(prompt, resume) =
            // VERIFY: Console.print vs print, Console.readLine vs readline
            Console.print(prompt);
            resume(Console.readLine() |> Option.getWithDefault(""))
    } with Tell {
        def tell(message, resume) =
            println(message);
            resume()
    }


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// EFFECT SET WITH MULTIPLE EFFECTS
//
//   def greet(): Unit \ {Ask, Tell} =
//
// When a function performs more than one effect, the effect set uses curly
// braces: `{Ask, Tell}`.
//
//
// AN EFFECT THAT RETURNS A VALUE
//
//   pub def ask(prompt: String): String
//
// The `ask` operation returns `String`. In its handler, `resume(value)` passes
// that value back to the point where `ask` was performed. The `name` variable
// in `greet` receives whatever string the handler passes to `resume`.
//
//
// STRING INTERPOLATION
//
//   Tell.tell("Hello, ${name}!")
//
// `${}` interpolates a variable into a string literal.
//
//
// MULTIPLE WITH CLAUSES
//
//   run { ... } with Ask { ... } with Tell { ... }
//
// Multiple `with` clauses can be chained onto a single `run` block, one per
// effect. Each handler handles its own effect independently.
//
//
// PIPELINE OPERATOR AND OPTION HANDLING
//
//   resume(Console.readLine() |> Option.getWithDefault(""))
//
// `Console.readLine()` returns `Option[String]` because reading may fail or
// return nothing. The `|>` operator pipes the result into the next function,
// unwrapping the Option and substituting an empty string if nothing was read.
// The resulting string is passed to `resume`, which delivers it back to the
// `Ask.ask(...)` call in the core logic.
