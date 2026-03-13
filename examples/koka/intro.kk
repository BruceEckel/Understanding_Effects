// Introductory effect example in Koka.
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
