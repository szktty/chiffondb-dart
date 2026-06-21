import 'dart:convert';
import 'dart:io';

import 'package:chiffondb/chiffondb.dart';
import 'package:test/test.dart';

const _schema = '''
node User { id: String name: String }
node Project { id: String title: String isArchived: Boolean }
edge OWNS { from: User to: Project props: { role: String } }
''';

void main() {
  setUpAll(() async {
    await ChiffonDb.init();
  });

  group('Connection CRUD', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('chiffondb_test_');
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('create and open roundtrip', () async {
      final path = '${tmpDir.path}/test.tdb';
      final db = await Connection.create(path: path);
      await db.close();
      expect(File(path).existsSync(), isTrue);

      final db2 = await Connection.open(path: path);
      await db2.close();
    });

    test('insert node returns RecordId', () async {
      final db = await Connection.openInMemory();
      await db.applySchema(schemaText: _schema);
      final rid = await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      await db.close();

      expect(rid.page, greaterThanOrEqualTo(0));
      expect(rid.slot, greaterThanOrEqualTo(0));
    });

    test('insert edge and traverse', () async {
      final db = await Connection.openInMemory();
      await db.applySchema(schemaText: _schema);

      final userRid = await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      final projectRid = await db.insertNode(
        typeName: 'Project',
        propsJson: jsonEncode({'id': 'p1', 'title': 'Alpha', 'isArchived': false}),
      );
      await db.insertEdge(
        typeName: 'OWNS',
        from: userRid,
        to: projectRid,
        propsJson: jsonEncode({'role': 'owner'}),
      );

      final command = jsonEncode({
        'version': 1,
        'start': {'type': 'Node', 'label': 'User', 'key': 'id', 'value': 'u1'},
        'steps': [
          {'action': 'OutEdges', 'label': 'OWNS'},
          {
            'action': 'OutNodes',
            'label': 'Project',
            'filter': {'property': 'isArchived', 'operator': 'Equals', 'value': false},
          },
        ],
        'collect': {'type': 'Nodes', 'properties': ['id', 'title']},
      });

      final resultJson = await db.executeTraversal(commandJson: command);
      await db.close();

      final results = jsonDecode(resultJson) as List;
      expect(results.length, equals(1));
      expect(results[0]['id'], equals('p1'));
      expect(results[0]['title'], equals('Alpha'));
    });

    test('delete node cascades edges', () async {
      final db = await Connection.openInMemory();
      await db.applySchema(schemaText: _schema);

      final userRid = await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      final projectRid = await db.insertNode(
        typeName: 'Project',
        propsJson: jsonEncode({'id': 'p1', 'title': 'Alpha', 'isArchived': false}),
      );
      await db.insertEdge(
        typeName: 'OWNS',
        from: userRid,
        to: projectRid,
        propsJson: jsonEncode({'role': 'owner'}),
      );
      await db.deleteNode(rid: userRid);

      final command = jsonEncode({
        'version': 1,
        'start': {'type': 'Node', 'label': 'User', 'key': 'id', 'value': 'u1'},
        'steps': [],
        'collect': {'type': 'Nodes', 'properties': ['id']},
      });

      expect(
        () => db.executeTraversal(commandJson: command),
        throwsA(anything),
      );
      await db.close();
    });

    test('update node properties', () async {
      final db = await Connection.openInMemory();
      await db.applySchema(schemaText: _schema);

      final rid = await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      await db.updateNodeProperties(
        rid: rid,
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alicia'}),
      );

      final props = jsonDecode(await db.getNodeProperties(rid: rid)) as Map;
      await db.close();

      expect(props['name'], equals('Alicia'));
    });

    test('AllNodes traversal returns inserted nodes', () async {
      final db = await Connection.openInMemory();
      await db.applySchema(schemaText: _schema);

      await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u2', 'name': 'Bob'}),
      );

      final command = jsonEncode({
        'version': 1,
        'start': {'type': 'AllNodes', 'label': 'User'},
        'steps': [],
        'collect': {'type': 'Nodes', 'properties': ['id']},
      });

      final resultJson = await db.executeTraversal(commandJson: command);
      await db.close();

      final results = jsonDecode(resultJson) as List;
      expect(results.length, equals(2));
    });

    test('persist and reopen', () async {
      final path = '${tmpDir.path}/test.tdb';

      final db = await Connection.create(path: path);
      await db.applySchema(schemaText: _schema);
      await db.insertNode(
        typeName: 'User',
        propsJson: jsonEncode({'id': 'u1', 'name': 'Alice'}),
      );
      await db.close();

      final db2 = await Connection.open(path: path);
      final command = jsonEncode({
        'version': 1,
        'start': {'type': 'AllNodes', 'label': 'User'},
        'steps': [],
        'collect': {'type': 'Nodes', 'properties': ['id']},
      });
      final resultJson = await db2.executeTraversal(commandJson: command);
      await db2.close();

      final results = jsonDecode(resultJson) as List;
      expect(results.length, equals(1));
    });
  });
}
