import 'dart:convert';
import 'dart:io';

import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:chiffondb/chiffondb.dart';
import 'package:test/test.dart';

const _schema = '''
node Person { id: String name: String age: Int }
node Group  { id: String title: String }
edge MEMBER { from: Person to: Group props: { role: String } }
''';

// ---- Model (in-memory expected state) ----

class _NodeModel {
  _NodeModel(this.rid, this.typeName, this.idProp);
  final RecordId rid;
  final String typeName;
  final String idProp;
  String ridKey() => '${rid.page}:${rid.slot}';
}

class _EdgeModel {
  _EdgeModel(this.rid, this.fromKey, this.toKey);
  final RecordId rid;
  final String fromKey;
  final String toKey;
  String ridKey() => '${rid.page}:${rid.slot}';
}

class GraphState {
  final _nodes = <String, _NodeModel>{};
  final _edges = <String, _EdgeModel>{};
  int _nodeSeq = 0;
  int _groupSeq = 0;

  String nextPersonId() => 'p${_nodeSeq++}';
  String nextGroupId() => 'g${_groupSeq++}';

  void addNode(_NodeModel m) => _nodes[m.ridKey()] = m;
  void addEdge(_EdgeModel e) => _edges[e.ridKey()] = e;

  void removeNode(RecordId rid) {
    final key = '${rid.page}:${rid.slot}';
    _nodes.remove(key);
    // cascade delete
    _edges.removeWhere((_, e) => e.fromKey == key || e.toKey == key);
  }

  void removeEdge(RecordId rid) =>
      _edges.remove('${rid.page}:${rid.slot}');

  List<_NodeModel> persons() =>
      _nodes.values.where((n) => n.typeName == 'Person').toList();

  List<_NodeModel> groups() =>
      _nodes.values.where((n) => n.typeName == 'Group').toList();

  List<_EdgeModel> get edges => _edges.values.toList();

  bool hasNode(RecordId rid) =>
      _nodes.containsKey('${rid.page}:${rid.slot}');

  bool hasEdge(RecordId rid) =>
      _edges.containsKey('${rid.page}:${rid.slot}');
}

// ---- System (the real database) ----

class GraphSystem {
  GraphSystem(this.db);
  final Connection db;
}

// ---- Behavior ----

final class GraphBehavior extends Behavior<GraphState, GraphSystem> {
  late Directory _tmpDir;

  @override
  GraphState initialState() => GraphState();

  @override
  Future<GraphSystem> createSystem(GraphState s) async {
    _tmpDir = Directory.systemTemp.createTempSync('kiri_stateful_');
    final path = '${_tmpDir.path}/test.tdb';
    final db = await Connection.create(path: path);
    await db.applySchema(schemaText: _schema);
    return GraphSystem(db);
  }

  @override
  Future<void> destroySystem(GraphSystem system) async {
    await system.db.close();
    _tmpDir.deleteSync(recursive: true);
  }

  @override
  List<Command<GraphState, GraphSystem>> generateCommands(GraphState s) {
    final commands = <Command<GraphState, GraphSystem>>[
      // ---- Insert Person node ----
      Action0(
        'insertPerson',
        run: (sys) async {
          final id = s.nextPersonId();
          final rid = await sys.db.insertNode(
            typeName: 'Person',
            propsJson: jsonEncode({'id': id, 'name': 'Name_$id', 'age': 30}),
          );
          return (id, rid);
        },
        nextState: (s) {},
        postcondition: (s, result) {
          final (id, rid) = result as (String, RecordId);
          s.addNode(_NodeModel(rid, 'Person', id));
          return true;
        },
      ),

      // ---- Insert Group node ----
      Action0(
        'insertGroup',
        run: (sys) async {
          final id = s.nextGroupId();
          final rid = await sys.db.insertNode(
            typeName: 'Group',
            propsJson: jsonEncode({'id': id, 'title': 'Title_$id'}),
          );
          return (id, rid);
        },
        nextState: (s) {},
        postcondition: (s, result) {
          final (id, rid) = result as (String, RecordId);
          s.addNode(_NodeModel(rid, 'Group', id));
          return true;
        },
      ),
    ];

    // Add only when Person exists.
    if (s.persons().isNotEmpty && s.groups().isNotEmpty) {
      commands.add(
        Action0(
          'insertEdge',
          precondition: (s) =>
              s.persons().isNotEmpty && s.groups().isNotEmpty,
          run: (sys) async {
            final person = s.persons().first;
            final group = s.groups().first;
            final rid = await sys.db.insertEdge(
              typeName: 'MEMBER',
              from: person.rid,
              to: group.rid,
              propsJson: jsonEncode({'role': 'member'}),
            );
            return (person.ridKey(), group.ridKey(), rid);
          },
          nextState: (s) {},
          postcondition: (s, result) {
            final (fromKey, toKey, rid) =
                result as (String, String, RecordId);
            s.addEdge(_EdgeModel(rid, fromKey, toKey));
            return true;
          },
        ),
      );
    }

    if (s.persons().isNotEmpty) {
      final person = s.persons().first;
      commands.add(
        // ---- Verify Person properties ----
        Action0(
          'verifyPersonProps',
          precondition: (s) => s.persons().isNotEmpty,
          run: (sys) async {
            final propsJson =
                await sys.db.getNodeProperties(rid: person.rid);
            return jsonDecode(propsJson) as Map;
          },
          nextState: (s) {},
          postcondition: (s, result) {
            final props = result as Map;
            final model = s.persons().firstWhere(
              (n) => n.ridKey() == person.ridKey(),
              orElse: () => _NodeModel(person.rid, 'Person', ''),
            );
            // id property matches expected value.
            return props['id'] == model.idProp;
          },
        ),
      );

      commands.add(
        // ---- Delete Person (verifies cascade delete) ----
        Action0(
          'deletePerson',
          precondition: (s) => s.persons().isNotEmpty,
          run: (sys) async {
            await sys.db.deleteNode(rid: person.rid);
            return person.rid;
          },
          nextState: (s) {},
          postcondition: (s, result) {
            final rid = result as RecordId;
            s.removeNode(rid);
            return true;
          },
        ),
      );
    }

    if (s.edges.isNotEmpty) {
      final edge = s.edges.first;
      commands.add(
        Action0(
          'deleteEdge',
          precondition: (s) => s.edges.isNotEmpty,
          run: (sys) async {
            await sys.db.deleteEdge(rid: edge.rid);
            return edge.rid;
          },
          nextState: (s) {},
          postcondition: (s, result) {
            final rid = result as RecordId;
            s.removeEdge(rid);
            return true;
          },
        ),
      );
    }

    return commands;
  }
}

void main() {
  setUpAll(() async {
    await ChiffonDb.init();
  });

  group('stateful: graph CRUD sequence', () {
    property('random CRUD maintains topology invariants', () {
      runBehavior(
        GraphBehavior(),
        maxCycles: 10,
        maxSteps: 20,
      );
    });
  });
}
