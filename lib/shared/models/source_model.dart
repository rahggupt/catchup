import 'package:equatable/equatable.dart';

class SourceModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String url;
  final List<String> topics;
  final bool active;
  final DateTime addedAt;
  
  const SourceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.topics,
    required this.active,
    required this.addedAt,
  });
  
  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      active: json['active'] as bool? ?? true,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'url': url,
      'topics': topics,
      'active': active,
      'added_at': addedAt.toIso8601String(),
    };
  }
  
  SourceModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? url,
    List<String>? topics,
    bool? active,
    DateTime? addedAt,
  }) {
    return SourceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      topics: topics ?? this.topics,
      active: active ?? this.active,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  @override
  List<Object?> get props => [id, userId, name, url, topics, active, addedAt];
}

