Let’s create a function that moves us in a direction at a velocity. Here’s a logical approach:

**`def travel(d: Direction, v: Velocity): Distance = {`**  
  **`...`**  
**`}`**

When we call **travel** we decide what direction and velocity we want to use. But to implement this function we’ll need some kind of motive force. Suppose there is an **engine** library:

**`import engine`**

**`def travel(d: Direction, v: Velocity): Distance = {`**  
  **`...`**  
  **`engine.go(speed = 50)`**  
  **`...`**  
**`}`**

We construct code by using libraries. This is a powerful approach and it has gotten us far. 

There’s a problem. This abstraction assumes there will be no repercussions from using **engine**, that it’s just a magical black box we don’t have to think about. If that does happen to be true for a library, there’s nothing to worry about.

With **engine**, however, that’s probably not the case. Engines are complicated beasts; they require fuel and lubrication, they generate heat, they need maintenance, they can fail. Sometimes they halt and catch fire. It’s basically a global variable that we are un-traceably modifying in **travel**. Treating it as a pure black box with no side effects is probably asking for trouble. 

It’s a leaky abstraction, and you must compensate using careful and tedious coding. But without a type system to do the bookkeeping for you and ensure nothing is missed, this approach doesn’t scale. We’ve been unsuccessfully throwing ourselves against this challenge since we started building large systems.

The main problem is that we sneak **engine** into **travel**: the function signature for **travel** doesn’t show that we use the problematic **engine** in the implementation. We just use it directly in our code as if there are no consequences.

One solution is to add this information into the argument list:

**`def travel(d: Direction, v: Velocity, e: engine): Distance = {`**  
  **`...`**  
  **`e.go(speed = 50)`**  
  **`...`**  
**`}`**

Now it’s clear that **travel** uses an **engine**, and we have the added bonus that the particular implementation of **engine** can be determined at the function call site\!

Doing this for every library gets tedious fast. It appears there are function arguments that we want to vary regularly, and those that might be set up at the beginning and never change. Default arguments don’t help here because there must always *be* a default. There might be a default **engine** but in the general case you want something customized for your needs.

We can use dependency injection to initialize the **engine**–along with any other libraries we use–thus removing the need to provide them at the call site. But this complicates the ability of the dependency injector to know that **travel** uses **engine**, so it falls back on the programmer. And if **engine** itself requires other libraries, the dependency injector must discover those and provide them for **engine** before providing **engine** to **travel**. Without somehow capturing that information in the type system, the dependency injector eventually succumbs to scaling problems.

What if we create an additional channel to convey this information? This way, we can separate the information we typically want to provide at every function call (direction and velocity) from the information that normally stays the same across function calls. We still have the option to change the latter information between function calls but we don’t have to trip over it every time we call the function. It can be expressed like this:

**`def travel(d: Direction, v: Velocity): Distance \ engine = {`**  
  **`...`**  
  **`engine.go(speed = 50)`**  
  **`...`**  
**`}`**

Now **engine** is part of the type signature without encumbering the argument list. 

* Previously we were implicitly using **engine**, an element global to **travel** that has its own state. Now it is explicit.  
* The compiler ensures **engine** appears in the type signature.   
* If another function uses **travel**, it too must indicate in its type signature that **engine** is being used.  
* When a dependency injector needs to know what **travel** uses, it can see it in the signature.   
* If the system changes the implementation of **engine**, we immediately know what functions are affected. 

The fact that **engine** has an impact on the system is now visible to the compiler, and ensured through type checking. Using this second channel, we provide that information without mucking up the argument list.