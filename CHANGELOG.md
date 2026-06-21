# Changelog

## 0.1.0

First release.

- Dart FFI bindings for [ChiffonDB](https://github.com/szktty/chiffondb) via flutter_rust_bridge.
- `Connection` API: open/create, CRUD for nodes and edges, schema management,
  JSON AST traversal, Cypher queries, path-finding, label management,
  transaction support, and integrity checks.
- `ChiffonDb.init()` entry point for loading the native library.
- `@NodeType` / `@EdgeType` annotations for schema-driven code generation
  (see [`chiffondb_generator`](https://pub.dev/packages/chiffondb_generator)).
