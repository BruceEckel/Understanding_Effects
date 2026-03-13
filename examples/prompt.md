I want to create an introductory Effect example that will be expressed in four languages:
- Koka
- Flix
- Scala ZIO
- TypeScript Effect.ts

There are four Effects:
- Ask: Takes a prompt and produces a string from a data source, presumably the console but could be any source.
- Tell: Consumes a string, presumably prints it to the console but could send to some other sink.
- Store: Consumes a string and stores it. Returns an ID.
- Fetch: Consumes an ID and retrieves the corresponding string from a data source.
Because these are Effects, the data sources and sinks can be swapped out without changing the core logic of the program.
They could be backed by a database, a file system, a remote API, operating system call or test system.

The Effects are used in two functions:
- inquire: Says hello to the user and asks for their name. Stores the name.
- greet: Fetches the name and greets the user.
These two functions are used in main.

Take care to ensure the correctness of the implementation.
Choose the simplest implementation that works, as this is for an introductory example.
