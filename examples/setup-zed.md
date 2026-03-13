# Setting Up the Examples in Zed

## Zed

Download and install Zed from **zed.dev**.

<!-- VERIFY: Zed Windows support status — as of mid-2025 it was in preview -->

---

## TypeScript / Effect.ts

Files: `effect-ts/hello.ts`, `effect-ts/welcome.ts`, `effect-ts/session.ts`

### 1. Install Node.js

Download and install Node.js (LTS version) from **nodejs.org**.
The installer includes `npm`. Verify the installation:

```
node --version
npm --version
```

### 2. Install dependencies

From the `examples/effect-ts` directory:

```
npm init -y
npm install effect
npm install --save-dev typescript @types/node tsx
```

`tsx` is a TypeScript runner that executes `.ts` files directly without a separate compile step.

### 3. Add a TypeScript config

Create `examples/effect-ts/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true
  }
}
```

<!-- VERIFY: exact tsconfig settings required by current Effect.ts version -->

### 4. Zed setup

Zed has built-in TypeScript support. Open the `examples/effect-ts` folder in Zed.
Type checking activates automatically once `node_modules` is present.

### 5. Run an example

```
npx tsx hello.ts
```

---

## Scala / ZIO

Files: `scala-zio/Hello.scala`, `scala-zio/Welcome.scala`, `scala-zio/Session.scala`

### 1. Install a JDK

Download and install a JDK (version 11 or later) from **adoptium.net** (Eclipse Temurin).
Verify:

```
java --version
```

### 2. Install sbt

Download and install sbt from **scala-sbt.org**. Verify:

```
sbt --version
```

### 3. Set up the project

Create `examples/scala-zio/build.sbt`:

```scala
scalaVersion := "3.3.3"
libraryDependencies += "dev.zio" %% "zio" % "2.1.9"
```

<!-- VERIFY: current Scala 3 and ZIO 2 versions -->

Create `examples/scala-zio/project/build.properties`:

```
sbt.version=1.10.0
```

<!-- VERIFY: current sbt version -->

Place each `.scala` file under `examples/scala-zio/src/main/scala/`.

### 4. Zed setup

Install the **Scala** extension from Zed's extension marketplace.
It uses Metals, the Scala language server.

Open `examples/scala-zio` in Zed. Metals will import the sbt project automatically
on first open — this takes a few minutes while it downloads the Scala toolchain and ZIO.

### 5. Run an example

From the `examples/scala-zio` directory:

```
sbt run
```

If multiple `Main` objects exist (one per file), sbt will ask which to run,
or you can specify:

```
sbt "runMain Main"
```

---

## Koka

Files: `koka/hello.kk`, `koka/welcome.kk`, `koka/session.kk`

### 1. Install Koka

<!-- VERIFY: Koka Windows installer availability and command -->

On macOS or Linux:

```
curl -sSL https://github.com/koka-lang/koka/releases/latest/download/install.sh | sh
```

On Windows, download the release binary from the GitHub releases page at
**github.com/koka-lang/koka/releases**.

Verify:

```
koka --version
```

### 2. Zed setup

<!-- VERIFY: Koka extension availability in Zed's marketplace -->

Search for **Koka** in Zed's extension marketplace. If unavailable, open the `.kk`
files as plain text; type checking and error reporting require running the compiler
from the terminal instead.

### 3. Run an example

```
koka hello.kk
```

---

## Flix

Files: `flix/Hello.flix`, `flix/Welcome.flix`, `flix/Session.flix`

### 1. Install a JDK

If not already installed (see Scala section above). Flix requires JDK 21 or later.

<!-- VERIFY: minimum JDK version for current Flix release -->

### 2. Download Flix

Download `flix.jar` from **flix.dev**. Place it in the `examples/flix` directory,
or somewhere on your PATH.

### 3. Initialize the project

From the `examples/flix` directory:

```
java -jar flix.jar init
```

This creates a standard Flix project layout with a `src/` directory.
Move the `.flix` files into `src/`.

<!-- VERIFY: exact project layout created by flix init -->

### 4. Zed setup

<!-- VERIFY: Flix extension availability in Zed's marketplace -->

Search for **Flix** in Zed's extension marketplace. The Flix compiler includes
a language server, which the extension uses for type checking and inline errors.

### 5. Run an example

```
java -jar flix.jar run
```
