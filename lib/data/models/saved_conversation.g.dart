// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedConversationAdapter extends TypeAdapter<SavedConversation> {
  @override
  final int typeId = 1;

  @override
  SavedConversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedConversation()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..initialPrompt = fields[2] as String
      ..messages = (fields[3] as List).cast<ChatMessage>()
      ..createdAt = fields[4] as DateTime
      ..updatedAt = fields[5] as DateTime
      ..currentItinerary = fields[6] as Itinerary?;
  }

  @override
  void write(BinaryWriter writer, SavedConversation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.initialPrompt)
      ..writeByte(3)
      ..write(obj.messages)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.currentItinerary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
