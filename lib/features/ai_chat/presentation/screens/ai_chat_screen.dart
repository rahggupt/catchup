import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/article_model.dart';
import '../../../../shared/services/logger_service.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../providers/chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final ArticleModel? article; // Optional article for context
  
  const AiChatScreen({
    super.key,
    this.article,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final LoggerService _logger = LoggerService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasRequestedSummary = false;

  final List<String> _suggestedQueries = [
    'Summarize latest articles',
    'What are the main topics?',
    'Explain key concepts',
    'Compare different viewpoints',
  ];

  @override
  void initState() {
    super.initState();
    // If article provided, auto-request summary after build
    if (widget.article != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestArticleSummary();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _requestArticleSummary() async {
    if (_hasRequestedSummary || widget.article == null) return;
    _hasRequestedSummary = true;
    
    print('📖 Auto-requesting summary for article: ${widget.article!.title}');
    
    try {
      await ref.read(sendArticleSummaryProvider)(widget.article!);
      _scrollToBottom();
    } catch (e) {
      print('❌ Error requesting article summary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate summary: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    // Check if AI is already thinking
    if (ref.read(isAiThinkingProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for AI to respond'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _textController.clear();
    
    try {
      await ref.read(sendMessageProvider)(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(userCollectionsProvider);
    final selectedCollection = ref.watch(selectedChatCollectionProvider);
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isThinking = ref.watch(isAiThinkingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            Text(widget.article != null ? 'Article Summary' : 'Ask AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(chatMessagesProvider);
              ref.read(currentChatSessionProvider.notifier).state = null;
            },
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collection Selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGray.withOpacity(0.5)),
              ),
            ),
            child: collectionsAsync.when(
              data: (collections) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All Sources'),
                      selected: selectedCollection == null,
                      onSelected: (_) {
                        ref.read(selectedChatCollectionProvider.notifier).state = null;
                        ref.read(currentChatSessionProvider.notifier).state = null;
                      },
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: selectedCollection == null ? Colors.white : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...collections.map((collection) {
                    final isSelected = selectedCollection == collection.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(collection.name),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(selectedChatCollectionProvider.notifier).state = collection.id;
                          ref.read(currentChatSessionProvider.notifier).state = null;
                        },
                        selectedColor: AppTheme.secondaryPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading collections')),
            ),
          ),

          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  // Welcome screen with suggestions
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 32),
                      const Icon(
                        Icons.auto_awesome,
                        size: 64,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hello! I\'m your AI assistant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedCollection != null
                            ? 'I can help you understand articles in this collection'
                            : 'I can help you explore your articles and sources',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Try asking:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedQueries.map((query) {
                          return ActionChip(
                            label: Text(
                              query,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () {
                              _textController.text = query;
                            },
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.borderGray),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }

                // Chat messages display
                // Log message order for debugging
                if (messages.isNotEmpty) {
                  _logger.info('Displaying ${messages.length} messages in order', category: 'Chat');
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator
                    if (isThinking && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'AI is thinking...',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final message = messages[index];
                    final isUser = message['role'] == 'user';
                    final content = message['content'] as String;
                    final timestamp = message['created_at'] as String?;
                    
                    // Format timestamp if available
                    String? timeText;
                    if (timestamp != null) {
                      try {
                        final dateTime = DateTime.parse(timestamp);
                        timeText = DateFormat('HH:mm').format(dateTime.toLocal());
                      } catch (e) {
                        // Ignore parse errors
                      }
                    }

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primaryBlue : AppTheme.backgroundLight,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppTheme.textDark,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            if (timeText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeText,
                                style: TextStyle(
                                  color: isUser ? Colors.white.withOpacity(0.7) : AppTheme.textGray,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading messages',
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Input Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderGray),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !isThinking,
                    decoration: InputDecoration(
                      hintText: isThinking ? 'AI is responding...' : 'Ask anything...',
                      filled: true,
                      fillColor: isThinking 
                          ? AppTheme.backgroundLight.withOpacity(0.5)
                          : AppTheme.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: _textController.text.isNotEmpty && !isThinking
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _textController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isThinking
                        ? AppTheme.textGray.withOpacity(0.3)
                        : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isThinking ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: isThinking ? null : _sendMessage,
                    tooltip: isThinking ? 'Please wait' : 'Send message',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

