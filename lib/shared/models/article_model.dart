import 'package:equatable/equatable.dart';

class ArticleModel extends Equatable {
  final String id;
  final String title;
  final String summary;
  final String? content;
  final String source;
  final String? author;
  final DateTime? publishedAt;
  final String? imageUrl;
  final String url;
  final String topic;
  final DateTime createdAt;
  
  const ArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    required this.source,
    this.author,
    this.publishedAt,
    this.imageUrl,
    required this.url,
    required this.topic,
    required this.createdAt,
  });
  
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String?,
      source: json['source'] as String,
      author: json['author'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      url: json['url'] as String,
      topic: json['topic'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'source': source,
      'author': author,
      'published_at': publishedAt?.toIso8601String(),
      'image_url': imageUrl,
      'url': url,
      'topic': topic,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  ArticleModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? source,
    String? author,
    DateTime? publishedAt,
    String? imageUrl,
    String? url,
    String? topic,
    DateTime? createdAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      source: source ?? this.source,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        content,
        source,
        author,
        publishedAt,
        imageUrl,
        url,
        topic,
        createdAt,
      ];
}

class FeedArticle extends Equatable {
  final ArticleModel article;
  final String status; // 'pending', 'read', 'dismissed'
  final DateTime addedAt;
  
  const FeedArticle({
    required this.article,
    required this.status,
    required this.addedAt,
  });
  
  factory FeedArticle.fromJson(Map<String, dynamic> json) {
    return FeedArticle(
      article: ArticleModel.fromJson(json['article'] as Map<String, dynamic>),
      status: json['status'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'article': article.toJson(),
      'status': status,
      'added_at': addedAt.toIso8601String(),
    };
  }
  
  FeedArticle copyWith({
    ArticleModel? article,
    String? status,
    DateTime? addedAt,
  }) {
    return FeedArticle(
      article: article ?? this.article,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  @override
  List<Object?> get props => [article, status, addedAt];
}

