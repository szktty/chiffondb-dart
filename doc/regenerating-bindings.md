# Regenerating the flutter_rust_bridge bindings

This package's Dart API under `lib/src/generated/` is produced by
[flutter_rust_bridge][frb] (frb) from the Rust `chiffondb-ffi` crate. You only
need to regenerate when the **Rust FFI surface changes** (a new/changed method
on `Connection`, a new DTO, etc.). Features that merely change traversal/Cypher
*command JSON* semantics do **not** need regeneration — see
`test/traversal_search_test.dart` for that style.

This is the canonical procedure; the skill at
`.claude/skills/chiffondb-dart/SKILL.md` has the condensed version.

## Layout

```
chiffondb/                 (sibling Rust workspace, default ../chiffondb/)
  chiffondb-core/          pure-Rust engine; defines Connection in src/api/mod.rs
  chiffondb-ffi/           thin FFI crate: `pub use chiffondb_core::api;`
    src/frb_generated.rs   <- frb Rust output
chiffondb-dart/            (this package)
  lib/src/generated/       <- frb Dart output
```

`Connection` and its DTOs live in **`chiffondb-core`**. `chiffondb-ffi` does not
redefine them; it re-exports the module. This single fact drives the one
non-obvious rule below.

## The one rule that matters: dual `--rust-input`

frb is invoked with explicit CLI arguments — there is **no
`flutter_rust_bridge.yaml`** in either repo. The `--rust-input` must name
**both** the FFI crate's module and the re-exported core module:

```
--rust-input "crate::api,chiffondb-core::api"
```

If you pass only `crate::api`, frb sees the `pub use chiffondb_core::api;`
re-export but does **not** descend into the dependency crate's source to read the
method bodies. It then emits an almost-empty binding: `api.dart` is not
regenerated at all, and `frb_generated.dart` loses thousands of lines (every
`Connection` method silently disappears). The build still prints `Done!`, so the
failure is easy to miss — always verify the output (below).

This was the original working configuration, preserved at
`rinne-graph/tanabata-dart/archive/flutter_rust_bridge.yaml`.

## Full command

```bash
cd ../chiffondb/chiffondb/chiffondb-ffi   # the FFI crate

flutter_rust_bridge_codegen generate \
  --rust-input "crate::api,chiffondb-core::api" \
  --rust-root  "$PWD" \
  --rust-output "$PWD/src/frb_generated.rs" \
  --dart-output "<abs path>/chiffondb-dart/lib/src/generated" \
  --dart-root   "<abs path>/chiffondb-dart"
```

frb prints `Installing Flutter version via FVM… Done!` — this is **normal**. frb
runs `dart fix` / `dart format` / `rustfmt` on its output and resolves the Dart
toolchain through FVM; it is not an error.

## After generating: rebuild the dylib

The Dart bindings embed a content hash that must match the compiled Rust
library. If you regenerate `frb_generated.rs` but run the old dylib,
`ChiffonDb.init()` aborts with:

> Content hash on Dart side (…) is different from Rust side (…), indicating
> out-of-sync code.

So always rebuild before testing:

```bash
(cd ../chiffondb/chiffondb && cargo build -p chiffondb-ffi)
```

The test loader and `hook/build.dart` pick up the local
`target/{debug,release}/libchiffondb_ffi.*` automatically (see
`lib/src/init.dart`).

## Verify the output

```bash
# Dart side: method count must not drop, new methods must appear.
grep -c 'Future<' lib/src/generated/third_party/chiffondb_core/api.dart   # ~51

# The diff must be confined to generated files only:
git status --short lib/src/generated/                # dart
git -C ../chiffondb/chiffondb status --short chiffondb-ffi/src/frb_generated.rs

# Gates (mirror CI):
dart format --output=none --set-exit-if-changed .
CHIFFONDB_HOOK_SKIP=1 dart analyze --fatal-infos
dart test --concurrency=1
```

A correct regeneration is **additive**: existing methods stay, new ones are
added. A diff that *deletes* large chunks of `frb_generated.dart` means the dual
`--rust-input` rule was violated — discard the output
(`git checkout -- lib/src/generated/`) and rerun with both inputs.

## Why `Connection` needs no `#[frb(opaque)]`

`Connection` wraps `inner: Option<Database>`, and `Database` reaches fixed-size
page arrays (`[u8; PAGE_SIZE]`) whose const-based length frb's parser cannot
evaluate. One might expect to need `#[frb(opaque)]` on `Connection` to stop frb
recursing into it (the predecessor `tanabota` project did exactly that).

It is **not** needed here. With the dual `--rust-input`, frb resolves the API
correctly and already treats `Connection` as an opaque handle
(`RustAutoOpaqueInner<Connection>` in `frb_generated.rs`); it never recurses into
`Database`. Adding `#[frb(opaque)]` would force a `flutter_rust_bridge`
dependency into `chiffondb-core`, which is intentionally **pure Rust**. Keep the
core dependency-free; fix generation problems with the codegen invocation, not by
annotating the engine.

The earlier "methods vanish" symptom looked like the tanabota opaque problem but
was caused solely by a single `--rust-input`. Don't conflate the two.

## Pitfall checklist

- [ ] `--rust-input "crate::api,chiffondb-core::api"` (both modules)
- [ ] Rebuilt the dylib (`cargo build -p chiffondb-ffi`) before `dart test`
- [ ] Diff confined to generated files (Dart + `frb_generated.rs`)
- [ ] Method count did not shrink; new methods present
- [ ] `dart format` / `dart analyze --fatal-infos` / `dart test` all green
- [ ] CHANGELOG notes this is an **FFI/binding** change (vs. command-JSON only)

[frb]: https://cjycode.com/flutter_rust_bridge/
