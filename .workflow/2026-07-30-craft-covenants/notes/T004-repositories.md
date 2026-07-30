# T004 — repository covenants

Added `craft-code-quality/references/repositories.md`.

- Defines repositories as domain/application persistence ports with infrastructure adapters.
- Limits repositories to aggregate storage or query semantics that need a contract.
- Rejects mandatory generic `IRepository<T>` CRUD wrappers.
- Keeps concrete database APIs in adapters and directs enforcement to the architecture-test
  assets' `BannedSymbols.txt` guidance.
- Keeps the domain independent of persistence frameworks.
