import 'dart:convert';
import 'dart:io';

import 'package:chiffondb/chiffondb.dart';
import 'package:test/test.dart';

// Exercises the dynamic-label FFI added in ChiffonDB and exposed on `Connection`
// (commit ac71ce0). Unknown label names are minted a type id on the fly without
// `applySchema`, and the call reports whether each name was newly created. The
// schema below defines only `Person` / `FOLLOWS`, so any other label name is
// unknown and must be registered dynamically.
//
// This is an FFI/binding change: the methods below come from the regenerated
// flutter_rust_bridge bindings, not from raw command JSON.

const _schema = '''
node Person { id: String }
edge FOLLOWS { from: Person to: Person }
''';

Future<Connection> _makeDb() async {
  final dir = Directory.systemTemp.createTempSync('dynamic_labels_');
  final db = await Connection.create(path: '${dir.path}/test.tdb');
  await db.applySchema(schemaText: _schema);
  return db;
}

Map<String, dynamic> _decode(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

List<String> _labelList(String json) =>
    (jsonDecode(json) as List<dynamic>).cast<String>();

void main() {
  setUpAll(() async {
    await ChiffonDb.init();
  });

  group('insertNodeWithDynamicLabels', () {
    test(
      'mints an unknown additional label and reports created flags',
      () async {
        final db = await _makeDb();
        final result = await db.insertNodeWithDynamicLabels(
          primaryType: 'Person',
          additionalLabels: ['VIP'],
          propsJson: jsonEncode({'id': 'u1'}),
        );

        final assignments = _decode(result.assignmentsJson);
        // "Person" exists in the schema; "VIP" is newly minted.
        expect(assignments['Person']['created'], isFalse);
        expect(assignments['VIP']['created'], isTrue);
        expect(assignments['VIP']['id'], isA<int>());

        // The dynamic label resolves back through the standard label getter.
        final labels = _labelList(await db.getNodeLabels(rid: result.rid));
        expect(labels, containsAll(['Person', 'VIP']));
        await db.close();
      },
    );

    test('a second insert reuses the id and reports created=false', () async {
      final db = await _makeDb();
      final first = await db.insertNodeWithDynamicLabels(
        primaryType: 'Person',
        additionalLabels: ['VIP'],
        propsJson: jsonEncode({'id': 'u1'}),
      );
      final firstId = _decode(first.assignmentsJson)['VIP']['id'] as int;

      final second = await db.insertNodeWithDynamicLabels(
        primaryType: 'Person',
        additionalLabels: ['VIP'],
        propsJson: jsonEncode({'id': 'u2'}),
      );
      final vip = _decode(second.assignmentsJson)['VIP'];
      expect(vip['created'], isFalse);
      expect(vip['id'], equals(firstId));
      await db.close();
    });
  });

  group('addNodeLabelDynamic', () {
    test('registers an unknown name then reuses it', () async {
      final db = await _makeDb();
      final rid = await db.insertNode(
        typeName: 'Person',
        propsJson: jsonEncode({'id': 'u1'}),
      );

      final first = _decode(
        await db.addNodeLabelDynamic(rid: rid, typeName: 'Admin'),
      );
      expect(first['created'], isTrue);

      // Adding the same label again reuses the id and reports created=false.
      final second = _decode(
        await db.addNodeLabelDynamic(rid: rid, typeName: 'Admin'),
      );
      expect(second['created'], isFalse);
      expect(second['id'], equals(first['id']));

      final labels = _labelList(await db.getNodeLabels(rid: rid));
      expect(labels, containsAll(['Person', 'Admin']));
      await db.close();
    });
  });

  group('addEdgeLabelDynamic', () {
    test(
      'registers an unknown edge label and reflects it in getEdgeLabels',
      () async {
        final db = await _makeDb();
        final alice = await db.insertNode(
          typeName: 'Person',
          propsJson: jsonEncode({'id': 'u1'}),
        );
        final bob = await db.insertNode(
          typeName: 'Person',
          propsJson: jsonEncode({'id': 'u2'}),
        );
        final edge = await db.insertEdge(
          typeName: 'FOLLOWS',
          from: alice,
          to: bob,
          propsJson: '{}',
        );

        final assignment = _decode(
          await db.addEdgeLabelDynamic(rid: edge, typeName: 'BLOCKS'),
        );
        expect(assignment['created'], isTrue);
        expect(assignment['id'], isA<int>());

        final labels = _labelList(await db.getEdgeLabels(rid: edge));
        expect(labels, containsAll(['FOLLOWS', 'BLOCKS']));
        await db.close();
      },
    );
  });
}
