# T007 evidence — arch-test UI/domain rule

Verified after [T007](fbceb2b0-c27c-4eb7-a7e5-95f1a07ab50b).

- [x] `typescript-dependency-cruiser/.dependency-cruiser.js` adds `ui-must-not-depend-on-domain`
  (`from: ^src/ui` → `to: ^src/domain`)
- [x] README section "Prove the TypeScript UI/domain rule fails" documents canary +
  `npx depcruise` expectation
