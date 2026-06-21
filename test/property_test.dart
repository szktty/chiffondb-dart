import 'dart:convert';
import 'dart:io';

import 'package:kiri_check/kiri_check.dart';
import 'package:chiffondb/chiffondb.dart';
import 'package:test/test.dart';

// --- Schema ---
const _schema = '''
node Item {
    id: String
    name: String
    count: Int
    score: Float
    active: Boolean
    tags: List<String>
}
node Target { id: String }
edge LINK { from: Item to: Target props: { weight: Float } }
''';

// --- Helpers ---
Future<Connection> makeDb() async {
  final dir = Directory.systemTemp.createTempSync('kc_test_');
  final path = '${dir.path}/test.tdb';
  final db = await Connection.create(path: path);
  await db.applySchema(schemaText: _schema);
  return db;
}

void main() {
  setUpAll(() async {
    await ChiffonDb.init();
  });

  // ---- applySchema ----
  group('applySchema', () {
    test('valid schema succeeds', () async {
      final db = await makeDb();
      await db.close();
    });

    test('invalid schema returns error', () async {
      final dir = Directory.systemTemp.createTempSync('kc_test_');
      final db = await Connection.create(path: '${dir.path}/test.tdb');
      expect(
        () => db.applySchema(schemaText: 'node { broken }'),
        throwsA(anything),
      );
      await db.close();
    });

    test('unknown edge endpoint fails validation', () async {
      final dir = Directory.systemTemp.createTempSync('kc_test_');
      final db = await Connection.create(path: '${dir.path}/test.tdb');
      expect(
        () => db.applySchema(
          schemaText: 'edge BAD { from: Ghost to: Unknown }',
        ),
        throwsA(anything),
      );
      await db.close();
    });
  });

  // ---- Property round-trip by type ----
  group('node property roundtrip', () {
    test('string property', () async {
      final db = await makeDb();
      final rid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'x', 'name': 'hello'}),
      );
      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      expect(props['name'], equals('hello'));
      await db.close();
    });

    test('int property', () async {
      final db = await makeDb();
      final rid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'x', 'count': 42}),
      );
      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      expect(props['count'], equals(42));
      await db.close();
    });

    test('float property', () async {
      final db = await makeDb();
      final rid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'x', 'score': 3.14}),
      );
      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      expect((props['score'] as num).toDouble(), closeTo(3.14, 1e-6));
      await db.close();
    });

    test('boolean property', () async {
      final db = await makeDb();
      final rid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'x', 'active': true}),
      );
      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      expect(props['active'], isTrue);
      await db.close();
    });

    test('list property', () async {
      final db = await makeDb();
      final tags = ['alpha', 'beta', 'gamma'];
      final rid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'x', 'tags': tags}),
      );
      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      expect(props['tags'], equals(tags));
      await db.close();
    });

    test('edge property roundtrip', () async {
      final db = await makeDb();
      final itemRid = await db.insertNode(
        typeName: 'Item',
        propsJson: jsonEncode({'id': 'i1'}),
      );
      final targetRid = await db.insertNode(
        typeName: 'Target',
        propsJson: jsonEncode({'id': 't1'}),
      );
      final edgeRid = await db.insertEdge(
        typeName: 'LINK',
        from: itemRid,
        to: targetRid,
        propsJson: jsonEncode({'weight': 0.75}),
      );
      final props =
          jsonDecode(await db.getEdgeProperties(rid: edgeRid)) as Map;
      expect((props['weight'] as num).toDouble(), closeTo(0.75, 1e-6));
      await db.close();
    });
  });

  // ---- kiri_check property-based tests ----
  group('kiri_check', () {
    // String round-trip
    property('string value roundtrip', () {
      forAll(
        // ASCII only (safe for JSON serialisation)
        string(
          maxLength: 100,
          characterSet:
              CharacterSet.all(CharacterEncoding.ascii),
        ),
        (s) async {
          // exclude control characters
          if (s.codeUnits.any((c) => c < 0x20 || c == 0x7F)) return;
          final db = await makeDb();
          final rid = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'x', 'name': s}),
          );
          final props =
              jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
          expect(props['name'], equals(s));
          await db.close();
        },
      );
    });

    // Integer round-trip
    property('int value roundtrip', () {
      forAll(
        integer(min: -1000000, max: 1000000),
        (n) async {
          final db = await makeDb();
          final rid = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'x', 'count': n}),
          );
          final props =
              jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
          expect(props['count'], equals(n));
          await db.close();
        },
      );
    });

    // Float round-trip
    property('float value roundtrip', () {
      forAll(
        float(min: -1e6, max: 1e6, nan: false, infinity: false),
        (f) async {
          final db = await makeDb();
          final rid = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'x', 'score': f}),
          );
          final props =
              jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
          expect(
            (props['score'] as num).toDouble(),
            closeTo(f, f.abs() * 1e-6 + 1e-9),
          );
          await db.close();
        },
      );
    });

    // Boolean round-trip
    property('bool value roundtrip', () {
      forAll(
        boolean(),
        (b) async {
          final db = await makeDb();
          final rid = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'x', 'active': b}),
          );
          final props =
              jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
          expect(props['active'], equals(b));
          await db.close();
        },
      );
    });

    // properties do not bleed across nodes
    property('multiple nodes have independent properties', () {
      final safeString = string(
        maxLength: 20,
        characterSet: CharacterSet.all(CharacterEncoding.ascii),
      );
      forAll(
        combine2(safeString, safeString),
        (pair) async {
          final (name1, name2) = pair;
          if (name1.codeUnits.any((c) => c < 0x20 || c == 0x7F)) return;
          if (name2.codeUnits.any((c) => c < 0x20 || c == 0x7F)) return;

          final db = await makeDb();
          final rid1 = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'n1', 'name': name1}),
          );
          final rid2 = await db.insertNode(
            typeName: 'Item',
            propsJson: jsonEncode({'id': 'n2', 'name': name2}),
          );
          final p1 = jsonDecode(await db.getNodeProperties(rid: rid1)) as Map;
          final p2 = jsonDecode(await db.getNodeProperties(rid: rid2)) as Map;
          expect(p1['name'], equals(name1));
          expect(p2['name'], equals(name2));
          await db.close();
        },
      );
    });

  });
}
