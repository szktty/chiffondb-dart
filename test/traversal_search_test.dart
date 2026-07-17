import 'dart:convert';
import 'dart:io';

import 'package:chiffondb/chiffondb.dart';
import 'package:test/test.dart';

// Exercises the search features added in ChiffonDB's
// feature/json-search-and-labels (squash-merged as 4b49f9b):
//
//   * `any_key_contains` recurses into `Json`-typed properties (matching
//     strings nested inside an aggregated JSON value).
//   * Property paths: `filter.property`, `OrderBy.key`, and a
//     property-reference `key` accept `{ "path": [...] }` to resolve a nested
//     scalar inside a `Json` value, in addition to a flat top-level key.
//
// These are pure command-JSON semantics, so no FFI signature change or binding
// regeneration is involved — the queries are built as raw JSON and sent through
// `Connection.executeTraversal`.

const _schema = '''
node Book {
    id: String
    title: String
    props: Json
}
''';

Future<Connection> _makeDb() async {
  final dir = Directory.systemTemp.createTempSync('traversal_search_');
  final db = await Connection.create(path: '${dir.path}/test.tdb');
  await db.applySchema(schemaText: _schema);
  return db;
}

Future<void> _addBook(
  Connection db,
  String id,
  String title,
  Map<String, dynamic> props,
) async {
  await db.insertNode(
    typeName: 'Book',
    propsJson: jsonEncode({'id': id, 'title': title, 'props': props}),
  );
}

/// Runs a traversal and returns the decoded list of node-property maps.
Future<List<Map<String, dynamic>>> _query(
  Connection db,
  Map<String, dynamic> command,
) async {
  final raw = await db.executeTraversal(commandJson: jsonEncode(command));
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

Map<String, dynamic> _allBooks(List<Map<String, dynamic>> steps) => {
  'version': 1,
  'start': {'type': 'AllNodes', 'label': 'Book', 'key': '', 'value': null},
  'steps': steps,
  'collect': {
    'type': 'Nodes',
    'properties': ['id'],
  },
};

List<String> _ids(List<Map<String, dynamic>> rows) =>
    rows.map((r) => r['id'] as String).toList();

void main() {
  setUpAll(() async {
    await ChiffonDb.init();
  });

  group('any_key_contains recurses into Json properties', () {
    late Connection db;

    setUp(() async {
      db = await _makeDb();
      // "ryoma" appears only nested inside props.author.name, never at the top
      // level — so a match proves the recursion into the Json value.
      await _addBook(db, 'b1', 'Sakamoto', {
        'year': 1867,
        'author': {'name': 'ryoma'},
      });
      await _addBook(db, 'b2', 'Other', {
        'year': 1900,
        'author': {'name': 'saigo'},
      });
    });

    tearDown(() async => db.close());

    test('matches a string nested inside a Json value', () async {
      final rows = await _query(
        db,
        _allBooks([
          {'action': 'Filter', 'any_key_contains': 'ryoma'},
        ]),
      );
      expect(_ids(rows), ['b1']);
    });

    test('is case-insensitive', () async {
      final rows = await _query(
        db,
        _allBooks([
          {'action': 'Filter', 'any_key_contains': 'RYOMA'},
        ]),
      );
      expect(_ids(rows), ['b1']);
    });

    test('does not match object keys, only string values', () async {
      // "author" is a key inside the Json value, never a string value.
      final rows = await _query(
        db,
        _allBooks([
          {'action': 'Filter', 'any_key_contains': 'author'},
        ]),
      );
      expect(rows, isEmpty);
    });
  });

  group('property paths into a Json value', () {
    late Connection db;

    setUp(() async {
      db = await _makeDb();
      await _addBook(db, 'b1', 'First', {'year': 1867, 'rank': 2});
      await _addBook(db, 'b2', 'Second', {'year': 1900, 'rank': 1});
      await _addBook(db, 'b3', 'Third', {'year': 1850, 'rank': 3});
    });

    tearDown(() async => db.close());

    test('filter on a nested scalar path', () async {
      final rows = await _query(
        db,
        _allBooks([
          {
            'action': 'Filter',
            'filter': {
              'property': {
                'path': ['props', 'year'],
              },
              'operator': 'Equals',
              'value': 1867,
            },
          },
        ]),
      );
      expect(_ids(rows), ['b1']);
    });

    test('filter with a comparison operator on a nested path', () async {
      final rows = await _query(
        db,
        _allBooks([
          {
            'action': 'Filter',
            'filter': {
              'property': {
                'path': ['props', 'year'],
              },
              'operator': 'GreaterThan',
              'value': 1860,
            },
          },
        ]),
      );
      expect(_ids(rows)..sort(), ['b1', 'b2']);
    });

    test('OrderBy on a nested path sorts by the nested scalar', () async {
      final rows = await _query(
        db,
        _allBooks([
          {
            'action': 'OrderBy',
            'order_by': {
              'key': {
                'path': ['props', 'year'],
              },
              'direction': 'Asc',
            },
          },
        ]),
      );
      // 1850 (b3) < 1867 (b1) < 1900 (b2)
      expect(_ids(rows), ['b3', 'b1', 'b2']);
    });

    test('a missing nested path resolves to absent (no match)', () async {
      final rows = await _query(
        db,
        _allBooks([
          {
            'action': 'Filter',
            'filter': {
              'property': {
                'path': ['props', 'nonexistent'],
              },
              'operator': 'Exists',
            },
          },
        ]),
      );
      expect(rows, isEmpty);
    });

    test(
      'property-reference with a nested-path key compares two nested scalars',
      () async {
        // Keep only books where props.year equals props.sameYear.
        final db2 = await _makeDb();
        await _addBook(db2, 'match', 'Match', {'year': 1867, 'sameYear': 1867});
        await _addBook(db2, 'nomatch', 'NoMatch', {
          'year': 1867,
          'sameYear': 1900,
        });
        final rows = await _query(
          db2,
          _allBooks([
            {
              'action': 'Filter',
              'filter': {
                'property': {
                  'path': ['props', 'year'],
                },
                'operator': 'PropertyEquals',
                'value': {
                  'type': 'property',
                  'key': {
                    'path': ['props', 'sameYear'],
                  },
                },
              },
            },
          ]),
        );
        expect(_ids(rows), ['match']);
        await db2.close();
      },
    );

    test('a flat top-level key still works (backward compatible)', () async {
      final rows = await _query(
        db,
        _allBooks([
          {
            'action': 'Filter',
            'filter': {'property': 'id', 'operator': 'Equals', 'value': 'b2'},
          },
        ]),
      );
      expect(_ids(rows), ['b2']);
    });
  });
}
