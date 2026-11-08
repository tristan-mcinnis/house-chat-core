# HouseChatCore: agent contract

Canonical file. `AGENTS.md` is a symlink to this file so every runtime reads one contract.

## What this is

The shared chat core for Quick Launch and RTI: one chat schema, two owner-only
archives, the retrieval policy, slash commands, and document selection and
extraction. `README.md` is the API handoff. Foundation only: no UI, no network,
no model call.

It is a library organ with no app and no installed artifact. Consumers
(quick-launch, rti) pin it by GitHub URL and semver tag, so an app builds from
a fresh clone with no sibling folders. A release is a tag: patch for a fix,
minor for new public API, major for a changed schema contract or a removed
public symbol.

## Floor and rule

- Floor: macOS 14. `swift-tools-version: 6.0`, Swift 6 language mode. Tests use Swift Testing.
- The Swift rule is `../design-system/SWIFT.md`. It is linked, not copied; read it before concurrency or test work.
- The deployment target wins over any skill or article. Raising the floor is a deliberate act recorded here and in `Package.swift`.

## Build and test

Build and test: `make build`, `make test`; warnings are errors.

```bash
make build            # swift build, warnings are errors
make test             # scrub gate, swift test, warnings are errors
```

Both apps record the pinned version and revision in their `Info.plist` from
their committed `Package.resolved` (`scripts/stamp-package-pins.py` in each
app), so an installed build names the exact tag it shipped with.

To release: `make test`, tag `vX.Y.Z`, push the tag, then raise the `from:`
pin in quick-launch (`Package.swift`) and rti (`RTI/project.yml`), resolve, and
commit there.

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
(`scripts/scrub.sh`) first. The global pre-push hook (`~/.config/git/hooks`) runs `make test`, scrub first, on every push.
Private tokens belong in the untracked `.scrub-private`, never in a tracked file.
Work and commit here, not through a consumer's checkout (`.build/checkouts` is read-only source).
