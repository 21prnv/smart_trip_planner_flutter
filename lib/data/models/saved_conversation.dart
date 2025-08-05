import 'package:hive/hive.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';

part 'saved_conversation.g.dart';

@HiveType(typeId: 1)
class SavedConversation extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String initialPrompt;

  @HiveField(3)
  late List<ChatMessage> messages;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  @HiveField(6)
  Itinerary? currentItinerary;

  SavedConversation();

  SavedConversation.create({
    required this.id,
    required this.title,
    required this.initialPrompt,
    required this.messages,
    this.currentItinerary,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  void addMessage(ChatMessage message) {
    messages.add(message);
    updatedAt = DateTime.now();
  }

  void updateCurrentItinerary(Itinerary itinerary) {
    currentItinerary = itinerary;
    updatedAt = DateTime.now();
  }
}
