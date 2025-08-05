import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/data/repositories/conversation_repository.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';

class StorageService {
  final _repository = locator<ConversationRepository>();

  Future<void> saveConversation({
    required String id,
    required String title,
    required String initialPrompt,
    required List<Map<String, dynamic>> chatHistory,
    Itinerary? currentItinerary,
  }) async {
    final messages = <ChatMessage>[];

    for (var chatItem in chatHistory) {
      final userMessage = chatItem['user'] as String;
      final aiResponse = chatItem['aiResponse'];

      messages.add(ChatMessage.user(userMessage));

      if (aiResponse != null) {
        if (aiResponse is Itinerary) {
          messages.add(
              ChatMessage.ai('Generated itinerary', itinerary: aiResponse));
        } else if (aiResponse is String) {
          messages.add(ChatMessage.ai(aiResponse));
        }
      }
    }

    final conversation = SavedConversation.create(
      id: id,
      title: title,
      initialPrompt: initialPrompt,
      messages: messages,
      currentItinerary: currentItinerary,
    );

    await _repository.saveConversation(conversation);
  }

  Future<List<SavedConversation>> getAllConversations() async {
    return await _repository.getAllConversations();
  }

  Future<List<SavedConversation>> getRecentConversations() async {
    return await _repository.getRecentConversations();
  }

  /// Search conversations
  Future<List<SavedConversation>> searchConversations(String query) async {
    return await _repository.searchConversations(query);
  }

  /// Delete conversation
  Future<void> deleteConversation(String id) async {
    await _repository.deleteConversation(id);
  }

  /// Add a new message to an existing conversation
  Future<void> addMessageToConversation(
      String conversationId, ChatMessage message) async {
    await _repository.addMessageToConversation(conversationId, message);
  }

  /// Update itinerary in conversation
  Future<void> updateConversationItinerary(
      String conversationId, Itinerary itinerary) async {
    await _repository.updateConversationItinerary(conversationId, itinerary);
  }
}
