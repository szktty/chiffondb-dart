/// Marks a class as a node type in the ChiffonDB graph schema.
///
/// The class name becomes the node type name in the DSL.
/// Each instance field (excluding [Id]-annotated fields) becomes a property.
///
/// Example:
/// ```dart
/// @NodeType()
/// class Person {
///   @Id() RecordId? id;
///   String name = '';
///   int age = 0;
/// }
/// ```
class NodeType {
  const NodeType();
}

/// Marks a class as an edge type in the ChiffonDB graph schema.
///
/// [F] is the source node type and [T] is the target node type.
/// The type arguments are resolved at code generation time via the analyzer.
///
/// Example:
/// ```dart
/// @EdgeType<Person, Person>()
/// class Follows {
///   @Id() RecordId? id;
///   DateTime since = DateTime.now();
/// }
/// ```
class EdgeType<F, T> {
  const EdgeType();
}

/// Marks a field as the record ID of a node or edge.
///
/// The field type must be `RecordId?`.
class Id {
  const Id();
}
