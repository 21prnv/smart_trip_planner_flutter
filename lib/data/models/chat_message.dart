import 'package:hive/hive.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  late String role; // 'user' or 'ai'

  @HiveField(1)
  late String content;

  @HiveField(2)
  Itinerary? itinerary;

  @HiveField(3)
  late DateTime timestamp;

  ChatMessage();

  ChatMessage.user(String message) {
    role = 'user';
    content = message;
    timestamp = DateTime.now();
  }

  ChatMessage.ai(String message, {Itinerary? itinerary}) {
    role = 'ai';
    content = message;
    this.itinerary = itinerary;
    timestamp = DateTime.now();
  }
}
