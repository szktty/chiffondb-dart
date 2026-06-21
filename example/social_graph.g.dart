// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_graph.dart';

// **************************************************************************
// NodeTypeGenerator
// **************************************************************************

// ---- Person (NodeType) ----

extension $PersonStoreExtension on ChiffonStore {
  /// Inserts a [Person] node and returns its [RecordId].
  Future<RecordId> insertPerson(Person instance) {
    return conn.insertNode(
      typeName: 'Person',
      propsJson: $encodePerson(instance),
    );
  }

  /// Fetches a [Person] node by [RecordId]. Returns null if not found.
  Future<Person?> getPerson(RecordId id) async {
    final json = await conn.getNodeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodePerson(json);
  }

  /// Updates the properties of a [Person] node.
  Future<void> updatePerson(RecordId id, Person instance) {
    return conn.updateNodeProperties(
      rid: id,
      propsJson: $encodePerson(instance),
    );
  }

  /// Returns all [Person] nodes.
  Future<List<Person>> listPersons() async {
    final json = await conn.listNodes(typeName: 'Person');
    return $decodeListPerson(json);
  }
}

/// Encodes a [Person] instance to a JSON string.
String $encodePerson(Person instance) {
  final map = <String, dynamic>{'name': instance.name, 'age': instance.age};
  return $chiffonEncodeJson(map);
}

/// Decodes a JSON string to a [Person] instance.
Person $decodePerson(String json) {
  final map = $chiffonDecodeJson(json);
  return Person()
    ..name = map['name'] as String
    ..age = map['age'] as int;
}

/// Decodes a JSON array string to a list of [Person] instances.
List<Person> $decodeListPerson(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodePersonFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Constructs a [Person] instance from a [Map].
Person $decodePersonFromMap(Map<String, dynamic> map) {
  return Person()
    ..name = map['name'] as String
    ..age = map['age'] as int;
}

/// DSL fragment for [Person]. Used by [ChiffonStore.applyAllSchemas].
const $PersonSchemaDsl = r'''
node Person {
  name: String
  age: Int
}''';

// ---- Company (NodeType) ----

extension $CompanyStoreExtension on ChiffonStore {
  /// Inserts a [Company] node and returns its [RecordId].
  Future<RecordId> insertCompany(Company instance) {
    return conn.insertNode(
      typeName: 'Company',
      propsJson: $encodeCompany(instance),
    );
  }

  /// Fetches a [Company] node by [RecordId]. Returns null if not found.
  Future<Company?> getCompany(RecordId id) async {
    final json = await conn.getNodeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeCompany(json);
  }

  /// Updates the properties of a [Company] node.
  Future<void> updateCompany(RecordId id, Company instance) {
    return conn.updateNodeProperties(
      rid: id,
      propsJson: $encodeCompany(instance),
    );
  }

  /// Returns all [Company] nodes.
  Future<List<Company>> listCompanys() async {
    final json = await conn.listNodes(typeName: 'Company');
    return $decodeListCompany(json);
  }
}

/// Encodes a [Company] instance to a JSON string.
String $encodeCompany(Company instance) {
  final map = <String, dynamic>{
    'name': instance.name,
    'industry': instance.industry,
  };
  return $chiffonEncodeJson(map);
}

/// Decodes a JSON string to a [Company] instance.
Company $decodeCompany(String json) {
  final map = $chiffonDecodeJson(json);
  return Company()
    ..name = map['name'] as String
    ..industry = map['industry'] as String;
}

/// Decodes a JSON array string to a list of [Company] instances.
List<Company> $decodeListCompany(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeCompanyFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Constructs a [Company] instance from a [Map].
Company $decodeCompanyFromMap(Map<String, dynamic> map) {
  return Company()
    ..name = map['name'] as String
    ..industry = map['industry'] as String;
}

/// DSL fragment for [Company]. Used by [ChiffonStore.applyAllSchemas].
const $CompanySchemaDsl = r'''
node Company {
  name: String
  industry: String
}''';

// **************************************************************************
// EdgeTypeGenerator
// **************************************************************************

// ---- Follows (EdgeType<Person, Person>) ----

extension $FollowsStoreExtension on ChiffonStore {
  /// Inserts a [Follows] edge and returns its [RecordId].
  Future<RecordId> insertFollows(RecordId from, RecordId to, Follows instance) {
    return conn.insertEdge(
      typeName: 'Follows',
      from: from,
      to: to,
      propsJson: $encodeFollows(instance),
    );
  }

  /// Fetches a [Follows] edge by [RecordId]. Returns null if not found.
  Future<Follows?> getFollows(RecordId id) async {
    final json = await conn.getEdgeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeFollows(json);
  }

  /// Updates the properties of a [Follows] edge.
  Future<void> updateFollows(RecordId id, Follows instance) {
    return conn.updateEdgeProperties(
      rid: id,
      propsJson: $encodeFollows(instance),
    );
  }

  /// Returns all [Follows] edges.
  Future<List<Follows>> listFollowss() async {
    final json = await conn.listEdges(typeName: 'Follows');
    return $decodeListFollows(json);
  }
}

/// Encodes a [Follows] instance to a JSON string.
String $encodeFollows(Follows instance) {
  final map = <String, dynamic>{'since': instance.since.toIso8601String()};
  return $chiffonEncodeJson(map);
}

/// Decodes a JSON string to a [Follows] instance.
Follows $decodeFollows(String json) {
  final map = $chiffonDecodeJson(json);
  return Follows()..since = DateTime.parse(map['since'] as String);
}

/// Decodes a JSON array string to a list of [Follows] instances.
List<Follows> $decodeListFollows(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeFollowsFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Constructs a [Follows] instance from a [Map].
Follows $decodeFollowsFromMap(Map<String, dynamic> map) {
  return Follows()..since = DateTime.parse(map['since'] as String);
}

/// DSL fragment for [Follows]. Used by [ChiffonStore.applyAllSchemas].
const $FollowsSchemaDsl = r'''
edge Follows {
  from: Person
  to: Person
  props: {
    since: DateTime
  }
}''';

// ---- WorksAt (EdgeType<Person, Company>) ----

extension $WorksAtStoreExtension on ChiffonStore {
  /// Inserts a [WorksAt] edge and returns its [RecordId].
  Future<RecordId> insertWorksAt(RecordId from, RecordId to, WorksAt instance) {
    return conn.insertEdge(
      typeName: 'WorksAt',
      from: from,
      to: to,
      propsJson: $encodeWorksAt(instance),
    );
  }

  /// Fetches a [WorksAt] edge by [RecordId]. Returns null if not found.
  Future<WorksAt?> getWorksAt(RecordId id) async {
    final json = await conn.getEdgeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeWorksAt(json);
  }

  /// Updates the properties of a [WorksAt] edge.
  Future<void> updateWorksAt(RecordId id, WorksAt instance) {
    return conn.updateEdgeProperties(
      rid: id,
      propsJson: $encodeWorksAt(instance),
    );
  }

  /// Returns all [WorksAt] edges.
  Future<List<WorksAt>> listWorksAts() async {
    final json = await conn.listEdges(typeName: 'WorksAt');
    return $decodeListWorksAt(json);
  }
}

/// Encodes a [WorksAt] instance to a JSON string.
String $encodeWorksAt(WorksAt instance) {
  final map = <String, dynamic>{'role': instance.role};
  return $chiffonEncodeJson(map);
}

/// Decodes a JSON string to a [WorksAt] instance.
WorksAt $decodeWorksAt(String json) {
  final map = $chiffonDecodeJson(json);
  return WorksAt()..role = map['role'] as String;
}

/// Decodes a JSON array string to a list of [WorksAt] instances.
List<WorksAt> $decodeListWorksAt(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeWorksAtFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Constructs a [WorksAt] instance from a [Map].
WorksAt $decodeWorksAtFromMap(Map<String, dynamic> map) {
  return WorksAt()..role = map['role'] as String;
}

/// DSL fragment for [WorksAt]. Used by [ChiffonStore.applyAllSchemas].
const $WorksAtSchemaDsl = r'''
edge WorksAt {
  from: Person
  to: Company
  props: {
    role: String
  }
}''';
