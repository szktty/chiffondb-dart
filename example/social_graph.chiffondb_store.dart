// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// SchemaLibraryGenerator
// **************************************************************************

// ignore_for_file: depend_on_referenced_packages

part of 'social_graph.dart';

// ---- ChiffonStore (auto-generated) ----

/// 全スキーマ DSL 定数リスト。各アノテーション付きクラスの断片を連結する。
const $allSchemaDsl = [
  $PersonSchemaDsl,
  $CompanySchemaDsl,
  $FollowsSchemaDsl,
  $WorksAtSchemaDsl,
];

/// [Connection] をラップしてスキーマ適用と型安全操作を提供するクラス。
class ChiffonStore {
  final Connection conn;

  const ChiffonStore(this.conn);

  /// 全スキーマを applySchema に送信する（冪等）。
  Future<void> applyAllSchemas() {
    final dsl = $allSchemaDsl.join('\n');
    return conn.applySchema(schemaText: dsl);
  }
}

// ---- JSON utilities (内部使用) ----

String $chiffonEncodeJson(Map<String, dynamic> map) =>
    jsonEncode(map);

Map<String, dynamic> $chiffonDecodeJson(String json) =>
    (jsonDecode(json) as Map).cast<String, dynamic>();

List<dynamic> $chiffonDecodeJsonList(String json) =>
    jsonDecode(json) as List<dynamic>;
