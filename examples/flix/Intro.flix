// Introductory effect example in Flix.
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
