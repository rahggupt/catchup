import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/mock_data_service.dart';
import '../providers/ai_chat_provider.dart';

class EnhancedAiChatScreen extends ConsumerStatefulWidget {
  const EnhancedAiChatScreen({super.key});

  @override
  ConsumerState<EnhancedAiChatScreen> createState() => _EnhancedAiChatScreenState();
}

class _EnhancedAiChatScreenState extends ConsumerState<EnhancedAiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQueries = [
    'Today\'s Top from My Sources',
    'Summarize AI Ethics Collection',
    'Explain blockchain in 50 words',
    'Compare articles on climate tech',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final message = _textController.text.trim();
    final selectedCollection = ref.read(selectedChatCollectionProvider);

    ref.read(chatMessagesProvider.notifier).sendMessage(
          message,
          collectionId: selectedCollection,
        );

    _textController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCollectionFilter() {
    final collections = MockDataService.getMockCollections();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Collection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Collections'),
              leading: const Icon(Icons.select_all),
              onTap: () {
                ref.read(selectedChatCollectionProvider.notifier).state = null;
                Navigator.pop(context);
              },
              selected: ref.read(selectedChatCollectionProvider) == null,
            ),
            ...collections.map((collection) {
              return ListTile(
                title: Text(collection.name),
                leading: const Icon(Icons.folder_outlined),
                onTap: () {
                  ref.read(selectedChatCollectionProvider.notifier).state =
                      collection.id;
                  Navigator.pop(context);
                },
                selected:
                    ref.read(selectedChatCollectionProvider) == collection.id,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final selectedCollection = ref.watch(selectedChatCollectionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 24),
            SizedBox(width: 8),
            Text('Ask AI'),
          ],
        ),
        actions: [
          if (selectedCollection != null)
            Chip(
              label: const Text('Filtered'),
              onDeleted: () {
                ref.read(selectedChatCollectionProvider.notifier).state = null;
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCollectionFilter,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show chat history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  messages.length + (messages.length == 1 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && messages.length == 1) {
                  // Suggested queries
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Try asking:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedQueries.map((query) {
                          return ActionChip(
                            label: Text(query),
                            onPressed: () {
                              _textController.text = query;
                              _sendMessage();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }

                final message = messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          // Input Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderGray),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // TODO: Attach article
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.mic_outlined),
                  onPressed: () {
                    // TODO: Voice input
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppTheme.primaryBlue,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryBlue : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isLoading)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Thinking...'),
                ],
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textDark,
                  fontSize: 14,
                ),
              ),
            if (message.citations != null && message.citations!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderGray),
              const SizedBox(height: 8),
              const Text(
                'Sources:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 4),
              ...message.citations!.map((citation) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.link,
                        size: 12,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${citation['title']} - ${citation['source']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

