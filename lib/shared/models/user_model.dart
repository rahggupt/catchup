import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String firstName;
  final String lastName;
  final String? avatar;
  final String? bio;
  final UserStats stats;
  final UserSettings settings;
  final AiProviderConfig aiProvider;
  final DateTime createdAt;
  
  const UserModel({
    required this.uid,
    required this.email,
    this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.avatar,
    this.bio,
    required this.stats,
    required this.settings,
    required this.aiProvider,
    required this.createdAt,
  });
  
  String get fullName => '$firstName $lastName';
  
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      stats: UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      settings: UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      aiProvider: AiProviderConfig.fromJson(json['ai_provider'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'bio': bio,
      'stats': stats.toJson(),
      'settings': settings.toJson(),
      'ai_provider': aiProvider.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? avatar,
    String? bio,
    UserStats? stats,
    UserSettings? settings,
    AiProviderConfig? aiProvider,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      aiProvider: aiProvider ?? this.aiProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        uid,
        email,
        phoneNumber,
        firstName,
        lastName,
        avatar,
        bio,
        stats,
        settings,
        aiProvider,
        createdAt,
      ];
}

class UserStats extends Equatable {
  final int articles;
  final int collections;
  final int chats;
  
  const UserStats({
    required this.articles,
    required this.collections,
    required this.chats,
  });
  
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      articles: json['articles'] as int? ?? 0,
      collections: json['collections'] as int? ?? 0,
      chats: json['chats'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'articles': articles,
      'collections': collections,
      'chats': chats,
    };
  }
  
  UserStats copyWith({
    int? articles,
    int? collections,
    int? chats,
  }) {
    return UserStats(
      articles: articles ?? this.articles,
      collections: collections ?? this.collections,
      chats: chats ?? this.chats,
    );
  }
  
  @override
  List<Object?> get props => [articles, collections, chats];
}

class UserSettings extends Equatable {
  final bool anonymousAdds;
  final bool friendUpdates;
  
  const UserSettings({
    required this.anonymousAdds,
    required this.friendUpdates,
  });
  
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      anonymousAdds: json['anonymous_adds'] as bool? ?? false,
      friendUpdates: json['friend_updates'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'anonymous_adds': anonymousAdds,
      'friend_updates': friendUpdates,
    };
  }
  
  UserSettings copyWith({
    bool? anonymousAdds,
    bool? friendUpdates,
  }) {
    return UserSettings(
      anonymousAdds: anonymousAdds ?? this.anonymousAdds,
      friendUpdates: friendUpdates ?? this.friendUpdates,
    );
  }
  
  @override
  List<Object?> get props => [anonymousAdds, friendUpdates];
}

class AiProviderConfig extends Equatable {
  final String provider; // 'gemini', 'openai', 'anthropic', 'custom'
  final String? apiKey; // null for default provider
  
  const AiProviderConfig({
    required this.provider,
    this.apiKey,
  });
  
  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    return AiProviderConfig(
      provider: json['provider'] as String? ?? 'gemini',
      apiKey: json['api_key'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'api_key': apiKey,
    };
  }
  
  AiProviderConfig copyWith({
    String? provider,
    String? apiKey,
  }) {
    return AiProviderConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
    );
  }
  
  @override
  List<Object?> get props => [provider, apiKey];
}

