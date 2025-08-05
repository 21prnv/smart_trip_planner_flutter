import 'dart:isolate';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';

class ItineraryProcessor {
  static Future<Itinerary> processInIsolate({
    required String userPrompt,
    required Itinerary? previousItinerary,
    required List<Map<String, String>> chatHistory,
  }) async {
    return await compute(_processItineraryInIsolate, {
      'prompt': userPrompt,
      'previousItinerary': previousItinerary?.toJson(),
      'chatHistory': chatHistory,
    });
  }

  static Future<Itinerary> _processItineraryInIsolate(
      Map<String, dynamic> data) async {
    final geminiService = GeminiService();
    final prompt = data['prompt'] as String;
    final previousItineraryJson =
        data['previousItinerary'] as Map<String, dynamic>?;
    final chatHistory = data['chatHistory'] as List<Map<String, String>>;

    Itinerary? previousItinerary;
    if (previousItineraryJson != null) {
      previousItinerary = Itinerary.fromJson(previousItineraryJson);
    }

    String fullResponse = '';
    int chunkCount = 0;

    try {
      await for (String chunk
          in geminiService.generateItineraryWithFunctionCalling(
              prompt, previousItinerary, chatHistory)) {
        chunkCount++;
        fullResponse += chunk;

        try {
          final cleanedResponse = _cleanJsonResponse(fullResponse);
          final jsonData = json.decode(cleanedResponse);
          return Itinerary.fromJson(jsonData);
        } catch (e) {}
      }

      throw Exception('Failed to generate valid itinerary');
    } catch (e) {
      throw e;
    }
  }

  static String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
