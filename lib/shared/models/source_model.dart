import 'package:equatable/equatable.dart';

class SourceModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String url;
  final List<String> topics;
  final bool active;
  final int? articleCount; // Number of articles to fetch per source (default 5)
  final DateTime addedAt;
  
  const SourceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.url,
    required this.topics,
    required this.active,
    this.articleCount = 5,
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
      articleCount: json['article_count'] as int? ?? 5,
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
      'article_count': articleCount ?? 5,
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
    int? articleCount,
    DateTime? addedAt,
  }) {
    return SourceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      url: url ?? this.url,
      topics: topics ?? this.topics,
      active: active ?? this.active,
      articleCount: articleCount ?? this.articleCount,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  @override
  List<Object?> get props => [id, userId, name, url, topics, active, articleCount, addedAt];
}

