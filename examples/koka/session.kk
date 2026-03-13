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
