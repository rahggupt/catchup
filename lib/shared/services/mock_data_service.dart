import '../models/article_model.dart';
import '../models/collection_model.dart';
import '../models/user_model.dart';
import '../models/source_model.dart';

/// Mock data service for development and testing
class MockDataService {
  static List<ArticleModel> getMockArticles() {
    return [
      ArticleModel(
        id: '1',
        title: 'The Future of AI: What Experts Predict for 2025',
        summary:
            'Leading AI researchers discuss groundbreaking developments expected this year, including advances in multimodal models, AI safety protocols, and practical applications in healthcare and climate science. The consensus points to more sophisticated reasoning capabilities while addressing ethical concerns.',
        source: 'Wired',
        author: 'Sarah Chen',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        topic: '#AI',
        imageUrl:
            'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80',
        url: 'https://wired.com/future-of-ai',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ArticleModel(
        id: '2',
        title: 'Climate Tech Startups Raise Record \$50B in Funding',
        summary:
            'Venture capital investment in climate technology reached unprecedented levels, with carbon capture, renewable energy storage, and sustainable agriculture leading the charge. Investors are betting big on solutions that can scale rapidly to meet 2030 climate goals.',
        source: 'MIT Tech Review',
        author: 'Alex Kumar',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        topic: '#Climate',
        imageUrl:
            'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&q=80',
        url: 'https://technologyreview.com/climate-tech-funding',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ArticleModel(
        id: '3',
        title: 'New Quantum Computing Breakthrough Achieves Error Correction',
        summary:
            'Scientists at leading research institutions have demonstrated a quantum computer that can correct its own errors in real-time, a crucial step toward practical quantum computing. This breakthrough could accelerate development of quantum systems for drug discovery and cryptography.',
        source: 'BBC Science',
        author: 'Dr. James Wong',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        topic: '#Tech',
        imageUrl:
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80',
        url: 'https://bbc.com/science/quantum-computing',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ArticleModel(
        id: '4',
        title: 'Global Policy Shift: 30 Countries Adopt AI Regulation Framework',
        summary:
            'In a historic move, major economies have agreed on unified AI governance standards covering transparency, accountability, and human oversight. The framework aims to balance innovation with public safety, setting precedent for international tech policy cooperation.',
        source: 'The Guardian',
        author: 'Emma Rodriguez',
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        topic: '#Politics',
        imageUrl:
            'https://images.unsplash.com/photo-1555374018-13a8994ab246?w=800&q=80',
        url: 'https://theguardian.com/ai-regulation',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ArticleModel(
        id: '5',
        title: 'Revolutionary Battery Technology Promises 1000-Mile Range EVs',
        summary:
            'A breakthrough in solid-state battery design could transform electric vehicles, offering triple the energy density of current lithium-ion batteries. Early prototypes show promise for commercial production by 2027, potentially eliminating range anxiety for EV owners.',
        source: 'The Verge',
        author: 'Michael Park',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        topic: '#Tech',
        imageUrl:
            'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800&q=80',
        url: 'https://theverge.com/battery-technology',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static List<CollectionModel> getMockCollections() {
    return [
      CollectionModel(
        id: '1',
        name: 'AI Ethics 2025',
        ownerId: 'mock-user',
        privacy: 'invite',
        collaboratorIds: ['user2', 'user3'],
        stats: const CollectionStats(
          articleCount: 12,
          chatCount: 3,
          contributorCount: 2,
        ),
        preview: 'Latest discussions on responsible AI development and governance frameworks',
        coverImage:
            'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      CollectionModel(
        id: '2',
        name: 'Climate Solutions',
        ownerId: 'mock-user',
        privacy: 'public',
        collaboratorIds: ['user2', 'user3', 'user4'],
        stats: const CollectionStats(
          articleCount: 8,
          chatCount: 5,
          contributorCount: 3,
        ),
        preview: 'Tracking innovations in renewable energy and carbon capture technology',
        shareableLink: 'https://catchup.app/c/climate-solutions',
        coverImage:
            'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=400&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      CollectionModel(
        id: '3',
        name: 'Quantum Computing',
        ownerId: 'mock-user',
        privacy: 'private',
        collaboratorIds: [],
        stats: const CollectionStats(
          articleCount: 6,
          chatCount: 2,
          contributorCount: 1,
        ),
        preview: 'Latest breakthroughs in quantum hardware and algorithms',
        coverImage:
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  static UserModel getMockUser() {
    return UserModel(
      uid: 'mock-user',
      email: 'jordan@example.com',
      firstName: 'Jordan',
      lastName: 'Smith',
      bio:
          'Tech enthusiast tracking AI, climate tech, and space exploration. Building knowledge for a better tomorrow.',
      stats: const UserStats(
        articles: 45,
        collections: 7,
        chats: 3,
      ),
      settings: const UserSettings(
        anonymousAdds: false,
        friendUpdates: true,
      ),
      aiProvider: const AiProviderConfig(
        provider: 'gemini',
        apiKey: null,
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );
  }

  static List<SourceModel> getMockSources() {
    return [
      SourceModel(
        id: '1',
        userId: 'mock-user',
        name: 'Wired',
        url: 'wired.com',
        topics: ['AI', 'Tech'],
        active: true,
        addedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      SourceModel(
        id: '2',
        userId: 'mock-user',
        name: 'MIT Tech Review',
        url: 'technologyreview.com',
        topics: ['Science', 'Innovation'],
        active: true,
        addedAt: DateTime.now().subtract(const Duration(days: 55)),
      ),
      SourceModel(
        id: '3',
        userId: 'mock-user',
        name: 'The Guardian',
        url: 'theguardian.com',
        topics: ['Politics', 'Climate'],
        active: false,
        addedAt: DateTime.now().subtract(const Duration(days: 50)),
      ),
    ];
  }
}

