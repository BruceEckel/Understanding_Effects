// Welcome effect example in Koka.
// Two effects: Ask and Tell.
// The implementations (handlers) in main are swappable without changing the logic.

// --- Effect declarations ---

effect ask
  fun ask(prompt : string) : string

effect tell
  fun tell(message : string) : ()


// --- Core logic ---

fun greet() : <ask,tell> ()
  val name = ask("What is your name? ")
  tell("Hello, " ++ name ++ "!")


// --- Main: wire up console handlers ---

fun main() : console ()
  with fun ask(prompt)
    print(prompt)
    readline()
  with fun tell(message)
    println(message)
  greet()


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// MULTIPLE EFFECTS IN THE EFFECT ROW
//
//   fun greet() : <ask,tell> ()
//
// The effect row can list multiple effects, separated by commas. `greet`
// performs both `ask` and `tell`.
//
//
// AN EFFECT THAT RETURNS A VALUE
//
//   fun ask(prompt : string) : string
//
// Unlike `tell`, which returns `()`, the `ask` operation returns `string`.
// The handler for `ask` must supply that string — it decides what value the
// caller receives when it performs `ask`. Here `readline()` reads from stdin
// and its return value becomes the result of the `ask` call in `greet`.
//
//
// STRING CONCATENATION
//
//   tell("Hello, " ++ name ++ "!")
//
// `++` is Koka's string concatenation operator.
//
//
// STACKING MULTIPLE HANDLERS
//
//   with fun ask(prompt)
//     print(prompt)
//     readline()
//   with fun tell(message)
//     println(message)
//   greet()
//
// Multiple `with` handlers can be stacked before the expression they scope
// over. Each handler handles one effect; together they satisfy the full
// `<ask,tell>` effect row required by `greet`. `print` (no trailing newline)
// displays the prompt, then `readline()` reads a line from stdin. The return
// value of the handler body is what the `ask(...)` call in `greet` receives.
