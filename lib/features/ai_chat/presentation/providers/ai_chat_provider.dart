import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/rag_service.dart';

// RAG service provider
final ragServiceProvider = Provider<RAGService>((ref) {
  return RAGService();
});

// Chat messages provider
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref.read(ragServiceProvider));
});

class ChatMessage {
  final String id;
  final String role; // 'user' or 'ai'
  final String content;
  final List<Map<String, dynamic>>? citations;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    List<Map<String, dynamic>>? citations,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final RAGService _ragService;

  ChatMessagesNotifier(this._ragService) : super([
    ChatMessage(
      id: 'welcome',
      role: 'ai',
      content:
          'Hello! I\'m your AI assistant. I can help you summarize articles, explain concepts, or discuss ideas from your collections. What would you like to know?',
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String message, {String? collectionId}) async {
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    state = [...state, userMessage];

    // Add loading message
    final loadingMessage = ChatMessage(
      id: 'loading',
      role: 'ai',
      content: 'Thinking...',
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, loadingMessage];

    try {
      // Query RAG service
      final response = await _ragService.query(
        question: message,
        collectionId: collectionId,
      );

      // Remove loading message and add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'ai',
        content: response['answer'] as String,
        citations: response['citations'] as List<Map<String, dynamic>>?,
        timestamp: DateTime.now(),
      );

      state = [...state.where((m) => m.id != 'loading'), aiMessage];
    } catch (e) {
      // Remove loading and add error message
      final errorMessage = ChatMessage(
        id: 'error',
        role: 'ai',
        content: 'Sorry, I encountered an error: ${e.toString()}',
        timestamp: DateTime.now(),
      );

      state = [...state.where((m) => m.id != 'loading'), errorMessage];
    }
  }

  void clearChat() {
    state = [state.first]; // Keep welcome message
  }
}

// Selected collection filter provider
final selectedChatCollectionProvider = StateProvider<String?>((ref) => null);

