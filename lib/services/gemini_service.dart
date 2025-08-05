import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/firebase_options.dart';

class GeminiService {
  GenerativeModel? _functionCallModel;
  bool _isInitialized = false;

  GeminiService() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      _functionCallModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        tools: [
          Tool.functionDeclarations([_getValidateItineraryFunction()]),
        ],
      );
      _isInitialized = true;
    } catch (e) {
      print('Firebase initialization error: $e');
      _isInitialized = false;
    }
  }

  bool get isReady => _isInitialized && _functionCallModel != null;

  Map<String, dynamic> _validateItineraryJson(
      Map<String, dynamic> itineraryData) {
    try {
      final itinerary = Itinerary.fromJson(itineraryData);

      if (itinerary.days.isEmpty) {
        return {'error': 'Itinerary must have at least one day'};
      }

      for (var day in itinerary.days) {
        if (day.items.isEmpty) {
          return {'error': 'Each day must have at least one activity'};
        }
        for (var item in day.items) {
          if (item.location.isEmpty || !item.location.contains(',')) {
            return {'error': 'Each activity must have valid coordinates'};
          }
        }
      }

      return {
        'success': true,
        'message': 'Itinerary is valid and complete',
        'itinerary': itineraryData,
      };
    } catch (e) {
      return {
        'error': 'Invalid JSON structure: ${e.toString()}',
        'itinerary': itineraryData,
      };
    }
  }

  FunctionDeclaration _getValidateItineraryFunction() {
    return FunctionDeclaration(
      'validate_itinerary_json',
      'Validates and returns a structured trip itinerary in JSON format with proper syntax and validation.',
      parameters: {
        'itinerary': Schema.object(
          description: 'The complete itinerary object to validate and format.',
          properties: {
            'title':
                Schema.string(description: 'The title of the trip itinerary.'),
            'startDate': Schema.string(
                description:
                    'The start date of the trip in YYYY-MM-DD format.'),
            'endDate': Schema.string(
                description: 'The end date of the trip in YYYY-MM-DD format.'),
            'days': Schema.array(
              description: 'Array of daily itineraries.',
              items: Schema.object(
                description: 'A single day itinerary.',
                properties: {
                  'date': Schema.string(
                      description:
                          'The date for this day in YYYY-MM-DD format.'),
                  'summary': Schema.string(
                      description:
                          'A brief summary of activities for this day.'),
                  'items': Schema.array(
                    description: 'Array of activities for this day.',
                    items: Schema.object(
                      description: 'A single activity or event.',
                      properties: {
                        'time': Schema.string(
                            description:
                                'The time for this activity in HH:MM format.'),
                        'activity': Schema.string(
                            description:
                                'Description of the activity or event.'),
                        'location': Schema.string(
                            description:
                                'GPS coordinates in latitude,longitude format.'),
                      },
                    ),
                  ),
                },
              ),
            ),
          },
        ),
      },
    );
  }

  Stream<String> generateItineraryWithFunctionCalling(
    String userPrompt,
    Itinerary? previousItinerary,
    List<Map<String, String>> chatHistory,
  ) async* {
    try {
      int attempts = 0;
      while (!isReady && attempts < 50) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }

      if (!isReady) {
        yield 'Error: AI service failed to initialize. Please check your internet connection and try again.';
        return;
      }

      final chat = _functionCallModel!.startChat();

      String context = '';
      if (previousItinerary != null) {
        context +=
            'Previous Itinerary: ${json.encode(previousItinerary.toJson())}\n\n';
      }

      if (chatHistory.isNotEmpty) {
        context += 'Chat History:\n';
        for (var message in chatHistory) {
          context += '${message['role']}: ${message['content']}\n';
        }
        context += '\n';
      }

      final prompt = '''
You are a travel planning AI agent. Create a detailed itinerary based on the user's request.

$context
User Request: $userPrompt

CRITICAL: You MUST use the validate_itinerary_json function to return your response. Do not provide explanations or text responses.

Create a travel itinerary with the following structure and use the function:
- Title for the trip
- Start and end dates
- Daily activities with times, descriptions, and GPS coordinates
- Focus on the user's preferences and requirements

IMPORTANT: Use the validate_itinerary_json function to format your response. Do not provide any text explanations.
''';

      final response = await chat.sendMessage(Content.text(prompt));

      final responseText = response.text ?? '';
      final responseJson =
          response.candidates?.first.content.parts.first.toJson();

      if (responseJson != null &&
          responseJson.toString().contains('functionCall')) {
        try {
          final responseMap = responseJson as Map<String, dynamic>;
          final functionCallData =
              responseMap['functionCall'] as Map<String, dynamic>?;

          if (functionCallData != null &&
              functionCallData['name'] == 'validate_itinerary_json') {
            final args = functionCallData['args'] as Map<String, dynamic>;
            final itineraryData = args['itinerary'] as Map<String, dynamic>;

            final functionResult = _validateItineraryJson(itineraryData);

            if (functionResult['success'] == true) {
              yield json.encode(functionResult['itinerary']);
            } else {
              yield 'Error: ${functionResult['error']}';
            }
          }
        } catch (e) {
          if (responseText.isNotEmpty) {
            yield responseText;
          }
        }
      } else {
        if (responseText.isNotEmpty) {
          yield responseText;
        } else {
          yield 'Error: Empty response from AI service';
        }
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  Stream<String> generateItinerary(String tripDescription) async* {
    yield* generateItineraryWithFunctionCalling(tripDescription, null, []);
  }

  // Method for follow-up questions
  Stream<String> generateFollowUp(
    String followUpQuestion,
    String originalPrompt,
    Itinerary currentItinerary,
  ) async* {
    yield* generateItineraryWithFunctionCalling(
      followUpQuestion,
      currentItinerary,
      [
        {'role': 'user', 'content': originalPrompt},
        {
          'role': 'assistant',
          'content': json.encode(currentItinerary.toJson())
        },
      ],
    );
  }

  // Method for refining existing itinerary
  Stream<String> refineItinerary(
    String followUpQuestion,
    Itinerary currentItinerary,
    String originalPrompt,
    List<Map<String, String>> chatHistory,
  ) async* {
    yield* generateItineraryWithFunctionCalling(
      followUpQuestion,
      currentItinerary,
      chatHistory,
    );
  }
}
