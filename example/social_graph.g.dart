// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_graph.dart';

// **************************************************************************
// NodeTypeGenerator
// **************************************************************************

// ---- Person (NodeType) ----

extension $PersonStoreExtension on ChiffonStore {
  /// [Person] ノードを挿入して RecordId を返す。
  Future<RecordId> insertPerson(Person instance) {
    return conn.insertNode(
      typeName: 'Person',
      propsJson: $encodePerson(instance),
    );
  }

  /// RecordId から [Person] を取得する。存在しない場合は null を返す。
  Future<Person?> getPerson(RecordId id) async {
    final json = await conn.getNodeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodePerson(json);
  }

  /// [Person] ノードのプロパティを更新する。
  Future<void> updatePerson(RecordId id, Person instance) {
    return conn.updateNodeProperties(
      rid: id,
      propsJson: $encodePerson(instance),
    );
  }

  /// [Person] ノードを全件取得する。
  Future<List<Person>> listPersons() async {
    final json = await conn.listNodes(typeName: 'Person');
    return $decodeListPerson(json);
  }
}

/// [Person] インスタンスを JSON 文字列にエンコードする。
String $encodePerson(Person instance) {
  final map = <String, dynamic>{'name': instance.name, 'age': instance.age};
  return $chiffonEncodeJson(map);
}

/// JSON 文字列から [Person] インスタンスをデコードする。
Person $decodePerson(String json) {
  final map = $chiffonDecodeJson(json);
  return Person()
    ..name = map['name'] as String
    ..age = map['age'] as int;
}

/// JSON 配列文字列から [Person] リストをデコードする。
List<Person> $decodeListPerson(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodePersonFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Map から [Person] インスタンスを生成する。
Person $decodePersonFromMap(Map<String, dynamic> map) {
  return Person()
    ..name = map['name'] as String
    ..age = map['age'] as int;
}

/// DSL fragment for [Person]. [ChiffonStore.applyAllSchemas].
const $PersonSchemaDsl = r'''
node Person {
  name: String
  age: Int
}''';

// ---- Company (NodeType) ----

extension $CompanyStoreExtension on ChiffonStore {
  /// [Company] ノードを挿入して RecordId を返す。
  Future<RecordId> insertCompany(Company instance) {
    return conn.insertNode(
      typeName: 'Company',
      propsJson: $encodeCompany(instance),
    );
  }

  /// RecordId から [Company] を取得する。存在しない場合は null を返す。
  Future<Company?> getCompany(RecordId id) async {
    final json = await conn.getNodeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeCompany(json);
  }

  /// [Company] ノードのプロパティを更新する。
  Future<void> updateCompany(RecordId id, Company instance) {
    return conn.updateNodeProperties(
      rid: id,
      propsJson: $encodeCompany(instance),
    );
  }

  /// [Company] ノードを全件取得する。
  Future<List<Company>> listCompanys() async {
    final json = await conn.listNodes(typeName: 'Company');
    return $decodeListCompany(json);
  }
}

/// [Company] インスタンスを JSON 文字列にエンコードする。
String $encodeCompany(Company instance) {
  final map = <String, dynamic>{
    'name': instance.name,
    'industry': instance.industry,
  };
  return $chiffonEncodeJson(map);
}

/// JSON 文字列から [Company] インスタンスをデコードする。
Company $decodeCompany(String json) {
  final map = $chiffonDecodeJson(json);
  return Company()
    ..name = map['name'] as String
    ..industry = map['industry'] as String;
}

/// JSON 配列文字列から [Company] リストをデコードする。
List<Company> $decodeListCompany(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeCompanyFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Map から [Company] インスタンスを生成する。
Company $decodeCompanyFromMap(Map<String, dynamic> map) {
  return Company()
    ..name = map['name'] as String
    ..industry = map['industry'] as String;
}

/// DSL fragment for [Company]. [ChiffonStore.applyAllSchemas].
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
  /// [Follows] エッジを挿入して RecordId を返す。
  Future<RecordId> insertFollows(
    RecordId from,
    RecordId to,
    Follows instance,
  ) {
    return conn.insertEdge(
      typeName: 'Follows',
      from: from,
      to: to,
      propsJson: $encodeFollows(instance),
    );
  }

  /// RecordId から [Follows] を取得する。存在しない場合は null を返す。
  Future<Follows?> getFollows(RecordId id) async {
    final json = await conn.getEdgeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeFollows(json);
  }

  /// [Follows] エッジのプロパティを更新する。
  Future<void> updateFollows(RecordId id, Follows instance) {
    return conn.updateEdgeProperties(
      rid: id,
      propsJson: $encodeFollows(instance),
    );
  }

  /// [Follows] エッジを全件取得する。
  Future<List<Follows>> listFollowss() async {
    final json = await conn.listEdges(typeName: 'Follows');
    return $decodeListFollows(json);
  }
}

/// [Follows] インスタンスを JSON 文字列にエンコードする。
String $encodeFollows(Follows instance) {
  final map = <String, dynamic>{'since': instance.since.toIso8601String()};
  return $chiffonEncodeJson(map);
}

/// JSON 文字列から [Follows] インスタンスをデコードする。
Follows $decodeFollows(String json) {
  final map = $chiffonDecodeJson(json);
  return Follows()..since = DateTime.parse(map['since'] as String);
}

/// JSON 配列文字列から [Follows] リストをデコードする。
List<Follows> $decodeListFollows(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeFollowsFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Map から [Follows] インスタンスを生成する。
Follows $decodeFollowsFromMap(Map<String, dynamic> map) {
  return Follows()..since = DateTime.parse(map['since'] as String);
}

/// DSL fragment for [Follows]. [ChiffonStore.applyAllSchemas].
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
  /// [WorksAt] エッジを挿入して RecordId を返す。
  Future<RecordId> insertWorksAt(
    RecordId from,
    RecordId to,
    WorksAt instance,
  ) {
    return conn.insertEdge(
      typeName: 'WorksAt',
      from: from,
      to: to,
      propsJson: $encodeWorksAt(instance),
    );
  }

  /// RecordId から [WorksAt] を取得する。存在しない場合は null を返す。
  Future<WorksAt?> getWorksAt(RecordId id) async {
    final json = await conn.getEdgeProperties(rid: id);
    if (json.isEmpty) return null;
    return $decodeWorksAt(json);
  }

  /// [WorksAt] エッジのプロパティを更新する。
  Future<void> updateWorksAt(RecordId id, WorksAt instance) {
    return conn.updateEdgeProperties(
      rid: id,
      propsJson: $encodeWorksAt(instance),
    );
  }

  /// [WorksAt] エッジを全件取得する。
  Future<List<WorksAt>> listWorksAts() async {
    final json = await conn.listEdges(typeName: 'WorksAt');
    return $decodeListWorksAt(json);
  }
}

/// [WorksAt] インスタンスを JSON 文字列にエンコードする。
String $encodeWorksAt(WorksAt instance) {
  final map = <String, dynamic>{'role': instance.role};
  return $chiffonEncodeJson(map);
}

/// JSON 文字列から [WorksAt] インスタンスをデコードする。
WorksAt $decodeWorksAt(String json) {
  final map = $chiffonDecodeJson(json);
  return WorksAt()..role = map['role'] as String;
}

/// JSON 配列文字列から [WorksAt] リストをデコードする。
List<WorksAt> $decodeListWorksAt(String json) {
  final list = $chiffonDecodeJsonList(json);
  return list
      .map((e) => $decodeWorksAtFromMap(e as Map<String, dynamic>))
      .toList();
}

/// Map から [WorksAt] インスタンスを生成する。
WorksAt $decodeWorksAtFromMap(Map<String, dynamic> map) {
  return WorksAt()..role = map['role'] as String;
}

/// DSL fragment for [WorksAt]. [ChiffonStore.applyAllSchemas].
const $WorksAtSchemaDsl = r'''
edge WorksAt {
  from: Person
  to: Company
  props: {
    role: String
  }
}''';
