import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';

class GeminiService {
  GenerativeModel? _functionCallModel;

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
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // Step 1: Function that validates and processes itinerary JSON
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

  // Step 2: Function declaration for the model
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

  // Step 3: Main function that receives prompt, previous itinerary, and chat history
  Stream<String> generateItineraryWithFunctionCalling(
    String userPrompt,
    Itinerary? previousItinerary,
    List<Map<String, String>> chatHistory,
  ) async* {
    try {
      // Wait for initialization
      while (_functionCallModel == null) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      final chat = _functionCallModel!.startChat();

      // Build context from chat history
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

      // Step 4: Send message and handle function calls
      final response = await chat.sendMessage(Content.text(prompt));

      // Check if response contains function call
      final responseText = response.text ?? '';
      final responseJson =
          response.candidates?.first.content.parts.first.toJson();

      print('Response JSON: $responseJson');

      // Try to extract function call from response
      if (responseJson != null &&
          responseJson.toString().contains('functionCall')) {
        try {
          // Parse the function call response
          final responseMap = responseJson as Map<String, dynamic>;
          final functionCallData =
              responseMap['functionCall'] as Map<String, dynamic>?;

          if (functionCallData != null &&
              functionCallData['name'] == 'validate_itinerary_json') {
            final args = functionCallData['args'] as Map<String, dynamic>;
            final itineraryData = args['itinerary'] as Map<String, dynamic>;

            // Call the validation function
            final functionResult = _validateItineraryJson(itineraryData);

            // Don't send function response back to model (causing server error)
            // Just yield the validated itinerary JSON directly
            if (functionResult['success'] == true) {
              yield json.encode(functionResult['itinerary']);
            } else {
              yield 'Error: ${functionResult['error']}';
            }
          }
        } catch (e) {
          print('Function call parsing error: $e');
          // Fallback to direct response
          if (responseText.isNotEmpty) {
            yield responseText;
          }
        }
      } else {
        // Direct response without function calling
        if (responseText.isNotEmpty) {
          yield responseText;
        }
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  // Legacy method for backward compatibility
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
