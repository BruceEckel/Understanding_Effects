// Session effect example in Koka.
// Four effects: Ask, Tell, Store, Fetch.
// The implementations (handlers) in main are swappable without changing the logic.

// --- Effect declarations ---

effect ask
  fun ask(prompt : string) : string

effect tell
  fun tell(message : string) : ()

effect store
  fun store(value : string) : int

effect fetch
  fun fetch(id : int) : string


// --- Core logic ---

fun inquire() : <ask,tell,store> int
  tell("Hello!")
  val name = ask("What is your name? ")
  store(name)

fun greet(id : int) : <fetch,tell> ()
  val name = fetch(id)
  tell("Hello, " ++ name ++ "!")


// --- Helper for the in-memory store ---

fun lookup(db : list<(int,string)>, id : int) : string
  match db
    Nil              -> ""
    Cons((k,v),rest) -> if k == id then v else lookup(rest, id)


// --- Main: wire up console and in-memory handlers ---

// VERIFY: var introduces a local-state effect; the exact effect row for main
//         may need to be <console,st<h>> or simply <io> rather than just console.
fun main() : console ()
  var db      : list<(int,string)> := []
  var counter : int                := 0
  with fun store(value)
    counter := counter + 1
    db      := Cons((counter, value), db)
    counter
  with fun fetch(id)
    lookup(db, id)
  with fun ask(prompt)
    print(prompt)
    readline()
  with fun tell(message)
    println(message)
  val id = inquire()
  greet(id)


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// EFFECTS WITH NON-UNIT RETURN TYPES
//
//   fun store(value : string) : int
//   fun fetch(id : int) : string
//
// `store` takes a string and returns an int (the storage ID). `fetch` takes
// that int and returns the stored string. Effects can return arbitrary types,
// not just unit. The two logic functions are coordinated through this int:
// `inquire` stores a name and returns its ID; `greet` takes that ID and
// fetches the name back.
//
//
// SEPARATE LOGIC FUNCTIONS WITH DIFFERENT EFFECT ROWS
//
//   fun inquire() : <ask,tell,store> int
//   fun greet(id : int) : <fetch,tell> ()
//
// The two phases of the program are split into separate functions, each
// declaring only the effects it actually needs. `inquire` does not need
// `fetch`; `greet` does not need `ask` or `store`. The type system enforces
// this boundary.
//
//
// MUTABLE STATE WITH `var`
//
//   var db      : list<(int,string)> := []
//   var counter : int                := 0
//
// `var` declares a mutable local variable. `:=` assigns to it. The type
// `list<(int,string)>` is a list of integer-string pairs (tuples). These
// variables live in `main` and are closed over by the `store` and `fetch`
// handlers, so each handler call can read and update shared state.
//
//
// HANDLER THAT RETURNS A VALUE
//
//   with fun store(value)
//     counter := counter + 1
//     db      := Cons((counter, value), db)
//     counter
//
// The last expression in the handler body is its return value — the value
// passed back to the `store(...)` call in the core logic. Here `counter`
// (after incrementing) is returned as the storage ID.
//
//
// PATTERN MATCHING WITH `match`
//
//   match db
//     Nil              -> ""
//     Cons((k,v),rest) -> if k == id then v else lookup(rest, id)
//
// `match` branches on the shape of a value. `Nil` matches an empty list;
// `Cons((k,v), rest)` matches a non-empty list, destructuring the head tuple
// into key `k` and value `v`, with the tail bound to `rest`. The helper
// `lookup` recurses until it finds the matching key.
