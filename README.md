# chiffondb

Dart / Flutter bindings for [ChiffonDB](https://github.com/szktty/chiffondb) — a lightweight embedded property graph database written in Rust.

## Compatibility

| chiffondb (Dart) | chiffondb (Rust) |
|------------------|-----------------|
| 0.1.0            | 0.1.0           |

### Supported platforms

| Platform | Architecture     |
|----------|------------------|
| macOS    | arm64 (Apple silicon) |
| iOS      | arm64            |
| Linux    | x86_64           |
| Windows  | x86_64           |
| Android  | arm64, x86_64    |

macOS and iOS are **arm64-only**; Intel (x86_64) Macs are not supported. The
build hook contributes no native asset for x86_64 Apple targets, so a universal
macOS build produces an arm64-only `chiffondb_ffi.framework`.

## Features

- **`Connection` API** — create, open, and query a ChiffonDB database from Dart via FFI.
- **Schema management** — apply a graph schema DSL and inspect type definitions at runtime.
- **CRUD** — insert, update, patch, and delete nodes and edges with JSON properties.
- **Traversal & Cypher** — execute JSON AST traversal commands or Cypher queries (experimental).
- **Path finding** — shortest path and connecting subgraph queries.
- **Label management** — add and remove secondary labels on nodes and edges.
- **Transactions** — begin / commit / rollback.
- **Code generation** — `@NodeType` / `@EdgeType` annotations for schema-driven, type-safe Dart code (via [`chiffondb_generator`](https://pub.dev/packages/chiffondb_generator)).

## Installation

```yaml
dependencies:
  chiffondb: ^0.1.0

dev_dependencies:
  chiffondb_generator: ^0.1.0
  build_runner: ^2.4.0
```

The package hook downloads the pre-built native library from [GitHub Releases](https://github.com/szktty/chiffondb/releases) automatically on first build. No Rust toolchain is required.

## Quick start

### Initialize

Call `ChiffonDb.init()` once before using any `Connection` API:

```dart
import 'package:chiffondb/chiffondb.dart';

Future<void> main() async {
  await ChiffonDb.init();
  final conn = await Connection.openInMemory();
  // ...
  await conn.close();
}
```

### Apply a schema

```dart
await conn.applySchema(schemaText: '''
  node Person {
    name: String
    age:  Int
  }
  node Company {
    name:     String
    industry: String
  }
  edge WORKS_AT {
    from: Person
    to:   Company
    props: {
      role: String
    }
  }
''');
```

### CRUD

```dart
// Insert nodes
final alice = await conn.insertNode(
  typeName: 'Person',
  propsJson: '{"name":"Alice","age":30}',
);
final acme = await conn.insertNode(
  typeName: 'Company',
  propsJson: '{"name":"ACME Corp","industry":"Technology"}',
);

// Insert edge
await conn.insertEdge(
  typeName: 'WORKS_AT',
  from: alice,
  to: acme,
  propsJson: '{"role":"Engineer"}',
);

// Read
final props = await conn.getNodeProperties(rid: alice);
print(props); // {"name":"Alice","age":30}

// Update (overwrite)
await conn.updateNodeProperties(
  rid: alice,
  propsJson: '{"name":"Alice","age":31}',
);

// Patch (merge)
await conn.patchNodeProperties(
  rid: alice,
  patchJson: '{"age":31}',
);

// Delete
await conn.deleteNode(rid: alice); // cascades to connected edges
```

### Traversal

```dart
final result = await conn.executeTraversal(commandJson: '''
{
  "version": 1,
  "start": { "type": "Node", "label": "Person", "key": "name", "value": "Alice" },
  "steps": [
    { "action": "OutEdges", "label": "WORKS_AT" },
    { "action": "OutNodes", "label": "Company" }
  ],
  "collect": { "type": "Nodes", "properties": ["name"] }
}
''');
print(result); // [{"name":"ACME Corp"}]
```

### Cypher (experimental)

```dart
final result = await conn.executeCypher(
  query: 'MATCH (p:Person) WHERE p.age > 20 RETURN p.name, p.age',
);
print(result); // [{"p.name":"Alice","p.age":30}]
```

### Transactions

```dart
await conn.beginTransaction();
try {
  await conn.insertNode(typeName: 'Person', propsJson: '{"name":"Bob","age":25}');
  await conn.commitTransaction();
} catch (e) {
  await conn.rollbackTransaction();
}
```

## Code generation

Use `@NodeType` and `@EdgeType` annotations to generate type-safe store extensions. See [`chiffondb_generator`](https://pub.dev/packages/chiffondb_generator) for details.

```dart
import 'package:chiffondb/chiffondb.dart';

part 'social_graph.g.dart';
part 'social_graph.chiffondb_store.dart';

@NodeType()
class Person {
  @Id()
  RecordId? id;
  String name = '';
  int age = 0;
}

@EdgeType<Person, Person>()
class Follows {
  @Id()
  RecordId? id;
  DateTime since = DateTime.now();
}
```

Run the generator:

```sh
dart run build_runner build
```

Then use the generated `ChiffonStore`:

```dart
await ChiffonDb.init();
final conn = await Connection.open(path: 'social.db');
final store = ChiffonStore(conn);

await store.applyAllSchemas();

final aliceId = await store.insertPerson(Person()..name = 'Alice'..age = 30);
final bobId   = await store.insertPerson(Person()..name = 'Bob'..age = 25);
await store.insertFollows(aliceId, bobId, Follows()..since = DateTime.now());

final alice = await store.getPerson(aliceId);
print('${alice?.name}, ${alice?.age}'); // Alice, 30

await conn.close();
```

## Native library

The package hook fetches the pre-built native library from GitHub Releases on first build. To use a locally built library instead, set one of:

| Variable | Description |
|----------|-------------|
| `CHIFFONDB_CORE_LIB` | Absolute path to the `.dylib` / `.so` / `.dll` |
| `CHIFFONDB_CORE_ROOT` | Path to the Rust workspace root; searches `target/{release,debug}/` |
| `CHIFFONDB_USE_RELEASE=1` | Force download from GitHub Releases even if a local build exists |
| `CHIFFONDB_HOOK_SKIP=1` | Skip the hook entirely (FFI unavailable) |

## Author

SUZUKI Tetsuya <tetsuya.suzuki@gmail.com>

## License

[Apache License 2.0](LICENSE)
