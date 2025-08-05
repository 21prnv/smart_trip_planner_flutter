import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';

abstract class ConversationRepository {
  Future<void> saveConversation(SavedConversation conversation);

  Future<List<SavedConversation>> getAllConversations();

  Future<SavedConversation?> getConversationById(String id);

  Future<void> updateConversation(SavedConversation conversation);

  Future<void> deleteConversation(String id);

  Future<List<SavedConversation>> searchConversations(String query);

  Future<List<SavedConversation>> getRecentConversations();

  Future<void> addMessageToConversation(
      String conversationId, ChatMessage message);

  Future<void> updateConversationItinerary(
      String conversationId, Itinerary itinerary);
}
