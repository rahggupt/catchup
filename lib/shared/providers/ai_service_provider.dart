import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../../core/constants/app_constants.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

/// Provider for AI Service with user's custom API keys
final aiServiceProvider = FutureProvider<AIService>((ref) async {
  final aiConfig = await ref.watch(userAIConfigProvider.future);
  final provider = aiConfig['provider'] as String? ?? 'gemini';
  final customKey = aiConfig['api_key'] as String?;
  
  return AIService(
    geminiApiKey: AppConstants.geminiApiKey,
    qdrantUrl: AppConstants.qdrantUrl,
    qdrantKey: AppConstants.qdrantApiKey,
    huggingFaceKey: AppConstants.huggingFaceApiKey,
    aiProvider: provider,
    customGeminiKey: provider == 'gemini' ? customKey : null,
    customPerplexityKey: provider == 'perplexity' ? customKey : null,
  );
});

