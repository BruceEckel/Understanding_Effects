// Introductory effect example in Flix.
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
            def ask(prompt, k) =
                // VERIFY: Console.print vs print, Console.readLine vs readline
                Console.print(prompt);
                k(Console.readLine() |> Option.getWithDefault(""))
        } with Tell {
            def tell(message, k) =
                println(message);
                k()
        } with Store {
            def store(value, k) =
                let c = deref counter + 1;
                counter := c;
                db := Map.insert(c, value, deref db);
                k(c)
        } with Fetch {
            def fetch(id, k) =
                // VERIFY: Map.getWithDefault argument order
                k(Map.getWithDefault(id, "", deref db))
        }
    }
