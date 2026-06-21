// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'social_graph.dart';

// **************************************************************************
// SchemaLibraryGenerator
// **************************************************************************

// ignore_for_file: depend_on_referenced_packages

// ---- ChiffonStore (auto-generated) ----

/// List of all schema DSL constants. Each annotated class contributes one fragment.
const $allSchemaDsl = [
  $PersonSchemaDsl,
  $CompanySchemaDsl,
  $FollowsSchemaDsl,
  $WorksAtSchemaDsl,
];

/// Wraps a [Connection] and provides schema application and type-safe operations.
class ChiffonStore {
  final Connection conn;

  const ChiffonStore(this.conn);

  /// Applies all schemas to the database (idempotent).
  Future<void> applyAllSchemas() {
    final dsl = $allSchemaDsl.join('\n');
    return conn.applySchema(schemaText: dsl);
  }
}

// ---- JSON utilities (internal) ----

String $chiffonEncodeJson(Map<String, dynamic> map) => jsonEncode(map);

Map<String, dynamic> $chiffonDecodeJson(String json) =>
    (jsonDecode(json) as Map).cast<String, dynamic>();

List<dynamic> $chiffonDecodeJsonList(String json) =>
    jsonDecode(json) as List<dynamic>;
