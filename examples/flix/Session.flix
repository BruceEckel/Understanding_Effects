// Session effect example in Flix.
// Four effects: Ask, Tell, Store, Fetch.
// The implementations (handlers) in main are swappable without changing the logic.

// --- Effect declarations ---

eff Ask {
    pub def ask(prompt: String): String
}

eff Tell {
    pub def tell(message: String): Unit
}

eff Store {
    pub def store(value: String): Int32
}

eff Fetch {
    pub def fetch(id: Int32): String
}


// --- Core logic ---

def inquire(): Int32 \ {Ask, Tell, Store} =
    Tell.tell("Hello!");
    let name = Ask.ask("What is your name? ");
    Store.store(name)

def greet(id: Int32): Unit \ {Fetch, Tell} =
    let name = Fetch.fetch(id);
    Tell.tell("Hello, ${name}!")


// --- Main: wire up console and in-memory handlers ---

def main(): Unit \ IO =
    region rc {
        // VERIFY: Ref.fresh signature and deref/assignment syntax in current Flix
        let db      = Ref.fresh(rc, Map.empty());
        let counter = Ref.fresh(rc, 0);
        run {
            let id = inquire();
            greet(id)
        } with Ask {
            def ask(prompt, resume) =
                // VERIFY: Console.print vs print, Console.readLine vs readline
                Console.print(prompt);
                resume(Console.readLine() |> Option.getWithDefault(""))
        } with Tell {
            def tell(message, resume) =
                println(message);
                resume()
        } with Store {
            def store(value, resume) =
                let c = deref counter + 1;
                counter := c;
                db := Map.insert(c, value, deref db);
                resume(c)
        } with Fetch {
            def fetch(id, resume) =
                // VERIFY: Map.getWithDefault argument order
                resume(Map.getWithDefault(id, "", deref db))
        }
    }


// =============================================================================
// WHAT'S NEW IN THIS EXAMPLE
// =============================================================================
//
// EFFECTS WITH NON-UNIT RETURN TYPES
//
//   pub def store(value: String): Int32
//   pub def fetch(id: Int32): String
//
// `store` returns an Int32 (the storage ID) and `fetch` returns a String.
// Correspondingly, the handlers call `resume(c)` and `resume(string)` rather
// than `resume()`, passing the result back to the caller. Whatever is passed
// to `resume` is what the `Store.store(...)` or `Fetch.fetch(...)` call
// evaluates to in the core logic.
//
//
// REGION-SCOPED MUTABLE STATE
//
//   region rc {
//       let db      = Ref.fresh(rc, Map.empty());
//       let counter = Ref.fresh(rc, 0);
//       ...
//   }
//
// `region rc { ... }` creates a lexically scoped region for mutable memory.
// `Ref.fresh(rc, initial)` allocates a mutable reference in that region.
// Mutable state cannot escape the region; this gives the compiler and reader
// a clear boundary on where mutation can occur.
//
//
// READING AND WRITING REFS
//
//   let c = deref counter + 1;
//   counter := c;
//   db := Map.insert(c, value, deref db);
//
// `deref ref` reads the current value. `ref := value` writes a new value.
// `Map.insert(key, value, map)` returns a new map with the entry added;
// the result is written back into `db`.
//
//
// MAP LOOKUP WITH DEFAULT
//
//   Map.getWithDefault(id, "", deref db)
//
// Looks up `id` in the map. If the key is absent, returns the default `""`.
