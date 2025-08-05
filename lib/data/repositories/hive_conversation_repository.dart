import 'package:hive/hive.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/repositories/conversation_repository.dart';

class HiveConversationRepository implements ConversationRepository {
  static const String _conversationsBoxName = 'conversations';
  static const String _messagesBoxName = 'messages';

  late Box<SavedConversation> _conversationsBox;
  late Box<ChatMessage> _messagesBox;

  Future<void> initialize() async {
    _conversationsBox =
        await Hive.openBox<SavedConversation>(_conversationsBoxName);
    _messagesBox = await Hive.openBox<ChatMessage>(_messagesBoxName);
  }

  @override
  Future<void> saveConversation(SavedConversation conversation) async {
    await _conversationsBox.put(conversation.id, conversation);

    // Save all messages
    for (var message in conversation.messages) {
      await _messagesBox.put(
          '${conversation.id}_${message.timestamp.millisecondsSinceEpoch}',
          message);
    }
  }

  @override
  Future<List<SavedConversation>> getAllConversations() async {
    return _conversationsBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<SavedConversation?> getConversationById(String id) async {
    return _conversationsBox.get(id);
  }

  @override
  Future<void> updateConversation(SavedConversation conversation) async {
    conversation.updatedAt = DateTime.now();
    await _conversationsBox.put(conversation.id, conversation);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _conversationsBox.delete(id);

    // Delete all associated messages
    final messageKeys =
        _messagesBox.keys.where((key) => key.toString().startsWith('${id}_'));
    await _messagesBox.deleteAll(messageKeys);
  }

  @override
  Future<List<SavedConversation>> searchConversations(String query) async {
    final lowercaseQuery = query.toLowerCase();

    return _conversationsBox.values.where((conversation) {
      return conversation.title.toLowerCase().contains(lowercaseQuery) ||
          conversation.initialPrompt.toLowerCase().contains(lowercaseQuery) ||
          conversation.messages.any((message) =>
              message.content.toLowerCase().contains(lowercaseQuery));
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<SavedConversation>> getRecentConversations() async {
    return _conversationsBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))
      ..take(10);
  }

  @override
  Future<void> addMessageToConversation(
      String conversationId, ChatMessage message) async {
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      conversation.addMessage(message);
      await updateConversation(conversation);

      // Save the message
      await _messagesBox.put(
          '${conversationId}_${message.timestamp.millisecondsSinceEpoch}',
          message);
    }
  }

  @override
  Future<void> updateConversationItinerary(
      String conversationId, Itinerary itinerary) async {
    final conversation = await getConversationById(conversationId);
    if (conversation != null) {
      conversation.updateCurrentItinerary(itinerary);
      await updateConversation(conversation);
    }
  }
}
