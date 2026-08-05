# CODING_RULES.md — Engineering Standards, Security Rules & Strict Constraints

## 1. Core Principles & Code Standards

1. **Immutability First**:
   - Always create new objects or data structures when updating state.
   - Do not mutate parameters or shared global state in place.

2. **File & Function Scoping**:
   - Keep functions small (<50 lines of code) and focused on a single responsibility.
   - Keep files lean (200-400 lines typical, 800 lines maximum).
   - High cohesion, low coupling across feature boundaries.

3. **Explicit Error Handling**:
   - Check and handle errors at every boundary.
   - Fail fast with descriptive contextual error messages.
   - Log detailed context server-side; present friendly messages to users.

4. **Testing Requirements**:
   - Enforce 80%+ test coverage across unit and integration tests.
   - Practice TDD: Write failing tests (RED) first, write minimal implementation (GREEN), then refactor (IMPROVE).

---

## 2. Security Guidelines

1. **Zero Secret Exposure**:
   - NEVER hardcode secrets, API keys, private keys, or tokens in source files or tests.
   - Read credentials exclusively from environment variables or secure key vaults.

2. **Boundary Validation & Sanitization**:
   - Validate all user inputs and external payload data at system boundaries.
   - Use parameterized SQL queries for all database read/write operations.
   - Sanitize all rendered output against XSS and HTML injection.

3. **Cryptographic Integrity**:
   - Zeroize memory buffers holding secret keys immediately after cryptographic handshakes.
   - Verify mTLS certificates and Noise protocol keys strictly on every tunnel handshake.

---

## 3. STRICT "DO NOT DO" RULES (नाही करायच्या गोष्टी)

> [!CAUTION]
> The following non-negotiable rules must be followed at all times without exception:

1. **Never Leave TODOs or Unimplemented Stubs**:
   - Do NOT leave `// TODO`, `// WIP`, or placeholder stub implementations (`panic("not implemented")`, empty returns) in production code.

2. **Never Drop Existing Functions or API Interfaces**:
   - Do NOT remove, rename, or drop existing exported functions, methods, or gRPC RPC endpoints without backwards-compatible deprecation and migration updates across all callers.

3. **Never Swallow Errors Silently**:
   - Do NOT use blank error catches (`catch (_) {}`, `_ = err` without justification), silent try/except wrappers, or return empty/dummy fallback values when an upstream call fails.

4. **Never Hardcode Secrets, Keys, or Credentials**:
   - Do NOT commit hardcoded tokens, passwords, private keys, or test credentials into the codebase.

5. **Never Mutate Shared State In-Place**:
   - Do NOT alter existing state objects in-place; construct and return clean new copies.

6. **Never Perform Blocking Calls on Main UI / Event Loops**:
   - Do NOT invoke synchronous blocking locks, synchronous thread joins, or long delays on main event loops or UI threads.

7. **Never Declare Success Without Running Build & Test Verification**:
   - Do NOT mark a task or bug fix as complete until concrete build and automated test verification commands (`make go-test`, `make rust-test`, `make flutter-analyze`, etc.) have passed.
