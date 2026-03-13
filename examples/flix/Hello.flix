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
