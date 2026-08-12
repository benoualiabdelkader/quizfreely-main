class Studyset {
  final int? id;
  final String title;
  final String? description;
  final String? remoteId; // ID on quizfreely.org server
  final DateTime createdAt;
  final DateTime updatedAt;

  Studyset({
    this.id,
    required this.title,
    this.description,
    this.remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description ?? '',
      'remoteId': remoteId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Studyset.fromMap(Map<String, dynamic> map) {
    return Studyset(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      remoteId: map['remoteId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] is int
              ? map['createdAt']
              : (map['createdAt'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] is int
              ? map['updatedAt']
              : (map['updatedAt'] as num).toInt()),
    );
  }

  Studyset copyWith({
    int? id,
    String? title,
    String? description,
    String? remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Studyset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
