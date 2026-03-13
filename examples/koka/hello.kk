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
