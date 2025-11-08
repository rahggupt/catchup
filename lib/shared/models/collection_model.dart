import 'package:equatable/equatable.dart';

class CollectionModel extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String privacy; // 'private', 'invite', 'public'
  final List<String> collaboratorIds;
  final CollectionStats stats;
  final String? shareableLink;
  final String? coverImage;
  final String? preview;
  final DateTime createdAt;
  
  const CollectionModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.privacy,
    required this.collaboratorIds,
    required this.stats,
    this.shareableLink,
    this.coverImage,
    this.preview,
    required this.createdAt,
  });
  
  String get privacyLabel {
    switch (privacy) {
      case 'private':
        return 'Private';
      case 'invite':
        return 'Invite-Only';
      case 'public':
        return 'Shareable Link';
      default:
        return 'Private';
    }
  }
  
  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      privacy: json['privacy'] as String,
      collaboratorIds: (json['collaborator_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stats: CollectionStats.fromJson(json['stats'] as Map<String, dynamic>),
      shareableLink: json['shareable_link'] as String?,
      coverImage: json['cover_image'] as String?,
      preview: json['preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'privacy': privacy,
      'collaborator_ids': collaboratorIds,
      'stats': stats.toJson(),
      'shareable_link': shareableLink,
      'cover_image': coverImage,
      'preview': preview,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  CollectionModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? privacy,
    List<String>? collaboratorIds,
    CollectionStats? stats,
    String? shareableLink,
    String? coverImage,
    String? preview,
    DateTime? createdAt,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      privacy: privacy ?? this.privacy,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      stats: stats ?? this.stats,
      shareableLink: shareableLink ?? this.shareableLink,
      coverImage: coverImage ?? this.coverImage,
      preview: preview ?? this.preview,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        privacy,
        collaboratorIds,
        stats,
        shareableLink,
        coverImage,
        preview,
        createdAt,
      ];
}

class CollectionStats extends Equatable {
  final int articleCount;
  final int chatCount;
  final int contributorCount;
  
  const CollectionStats({
    required this.articleCount,
    required this.chatCount,
    required this.contributorCount,
  });
  
  factory CollectionStats.fromJson(Map<String, dynamic> json) {
    return CollectionStats(
      articleCount: json['article_count'] as int? ?? 0,
      chatCount: json['chat_count'] as int? ?? 0,
      contributorCount: json['contributor_count'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'article_count': articleCount,
      'chat_count': chatCount,
      'contributor_count': contributorCount,
    };
  }
  
  CollectionStats copyWith({
    int? articleCount,
    int? chatCount,
    int? contributorCount,
  }) {
    return CollectionStats(
      articleCount: articleCount ?? this.articleCount,
      chatCount: chatCount ?? this.chatCount,
      contributorCount: contributorCount ?? this.contributorCount,
    );
  }
  
  @override
  List<Object?> get props => [articleCount, chatCount, contributorCount];
}

