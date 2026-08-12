class Term {
  final int? id;
  final int studysetId;
  final String term;
  final String definition;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Term({
    this.id,
    required this.studysetId,
    required this.term,
    required this.definition,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studysetId': studysetId,
      'term': term,
      'definition': definition,
      'sortOrder': sortOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Term.fromMap(Map<String, dynamic> map) {
    return Term(
      id: map['id'],
      studysetId: map['studysetId'],
      term: map['term'],
      definition: map['definition'],
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Term copyWith({
    int? id,
    int? studysetId,
    String? term,
    String? definition,
    int? sortOrder,
  }) {
    return Term(
      id: id ?? this.id,
      studysetId: studysetId ?? this.studysetId,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
