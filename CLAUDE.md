# HouseChatCore: agent contract

Canonical file. `AGENTS.md` is a symlink to this file so every runtime reads one contract.

## What this is

The shared chat core for Quick Launch and RTI: one chat schema, two owner-only
archives, the retrieval policy, slash commands, and document selection and
extraction. `README.md` is the API handoff. Foundation only: no UI, no network,
no model call.

It is a library organ with no app and no installed artifact. Consumers
(`../quick-launch`, `../rti`) depend on it by relative path, so the repos stay
side by side under `house/`.

## Floor and rule

- Floor: macOS 14. `swift-tools-version: 6.0`, Swift 6 language mode. Tests use Swift Testing.
- The Swift rule is `../design-system/SWIFT.md`. It is linked, not copied; read it before concurrency or test work.
- The deployment target wins over any skill or article. Raising the floor is a deliberate act recorded here and in `Package.swift`.

## Build and test

```bash
swift build
make test             # scrub gate, swift test, provenance tests
```

Both apps stamp this package's commit and source hash into their `Info.plist`
with `scripts/chat-core-provenance.py` (called from `../quick-launch/scripts/build-app.sh`,
`../rti/scripts/install-local.sh` and `../rti/scripts/make-dmg.sh`). Callers pass
`--require-clean` to refuse a build from uncommitted package sources.

## Rules

- The schema is a shared contract. A change to a key, a required field or the
  date format breaks other writers of the schema and old files on disk.
  Update `Tests/Fixtures/thread-golden.json` in the same commit
  (see "Golden thread fixture" in `README.md`) and say so in the message.
- `HouseChatDocuments` depends on `HouseChatCore`, never the other way.
- No `/Users/...` paths, no secrets, no model or network calls.
- A consumer's legacy-format adapter stays in the consumer.

## Repository

Standalone git repo. Before any push run `make test`, which runs the scrub gate
(`scripts/scrub.sh`) first. `git config core.hooksPath .githooks` runs the gate on every push.
Private tokens belong in the untracked `.scrub-private`, never in a tracked file.
Work and commit here, not through a consumer's checkout.
