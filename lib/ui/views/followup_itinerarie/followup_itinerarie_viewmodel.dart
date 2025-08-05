import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowupItinerarieViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _geminiService = locator<GeminiService>();

  final Map<String, dynamic>? arguments;

  FollowupItinerarieViewModel({this.arguments}) {
    // Initialize itinerary from arguments
    _itinerary = arguments?['itinerary'];
    // Initialize chat history with the original AI response
    _initializeChatHistory();
  }

  String get tripDescription => arguments?['tripDescription'] ?? '';
  String get aiResponse => arguments?['aiResponse'] ?? '';
  Itinerary? _itinerary;
  Itinerary? get itinerary => _itinerary;

  final TextEditingController followUpController = TextEditingController();

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  // For streaming display
  String _streamingText = '';
  String get streamingText => _streamingText;

  // Chat history structure: [{user: prompt, aiResponse: parsedItinerary}]
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> get chatHistory => _chatHistory;

  void _initializeChatHistory() {
    // Add the original conversation to chat history
    if (tripDescription.isNotEmpty && _itinerary != null) {
      _chatHistory.add({
        'user': tripDescription,
        'aiResponse': _itinerary,
      });
    }
  }

  void onBackTap() {
    _navigationService.back();
  }

  void onCopyUserQuery() {
    // Copy user query to clipboard
    _dialogService.showCustomDialog(
      title: 'Copied!',
      description: 'User query copied to clipboard.',
    );
  }

  void onCopyItinerary() {
    // Copy itinerary to clipboard
    _dialogService.showCustomDialog(
      title: 'Copied!',
      description: 'Itinerary copied to clipboard.',
    );
  }

  void onSaveOffline() {
    // Save itinerary offline
    _dialogService.showCustomDialog(
      title: 'Saved Offline',
      description: 'Itinerary saved for offline access.',
    );
  }

  void onRegenerate() {
    // Regenerate itinerary
    _dialogService.showCustomDialog(
      title: 'Regenerating',
      description: 'Creating a new itinerary based on your preferences...',
    );
  }

  void onOpenMapsTap() {
    // Open maps
    _dialogService.showCustomDialog(
      title: 'Opening Maps',
      description: 'This would open Google Maps with the route.',
    );
  }

  void onVoiceInputTap() {
    // Voice input functionality
    _dialogService.showCustomDialog(
      title: 'Voice Input',
      description: 'Voice input feature coming soon!',
    );
  }

  Future<void> onOpenMapsTapWithCoordinates(String coordinates) async {
    try {
      final url = 'https://www.google.com/maps?q=$coordinates';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _dialogService.showCustomDialog(
          title: 'Error',
          description: 'Could not open Google Maps.',
        );
      }
    } catch (e) {
      _dialogService.showCustomDialog(
        title: 'Error',
        description: 'Failed to open maps: ${e.toString()}',
      );
    }
  }

  Future<void> onSendMessage() async {
    final message = followUpController.text.trim();
    if (message.isEmpty) return;

    // Add user message to chat history
    _chatHistory.add({
      'user': message,
      'aiResponse': null, // Will be filled when AI responds
    });

    // Clear input field
    followUpController.clear();
    notifyListeners();

    // Show thinking state
    _isThinking = true;
    _streamingText = '';
    notifyListeners();

    try {
      // Generate follow-up response
      String fullResponse = '';
      Itinerary? newItinerary;

      await for (String chunk in _geminiService.generateFollowUp(
        message,
        tripDescription,
        _itinerary!,
      )) {
        fullResponse += chunk;
        _streamingText = fullResponse;
        notifyListeners();

        // Try to parse as JSON after each chunk
        try {
          String cleanedResponse = _cleanJsonResponse(fullResponse);
          final jsonData = json.decode(cleanedResponse);
          newItinerary = Itinerary.fromJson(jsonData);
          break;
        } catch (e) {
          // Continue streaming if not valid JSON yet
        }
      }

      // Update the last chat entry with AI response
      if (_chatHistory.isNotEmpty) {
        _chatHistory.last['aiResponse'] = newItinerary ?? fullResponse;
      }

      // Update the current itinerary if we got a valid one
      if (newItinerary != null) {
        _itinerary = newItinerary;
      }
    } catch (e) {
      // Update the last chat entry with error message
      if (_chatHistory.isNotEmpty) {
        _chatHistory.last['aiResponse'] = 'Error: ${e.toString()}';
      }
    } finally {
      _isThinking = false;
      _streamingText = '';
      notifyListeners();
    }
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();
    cleaned = _fixJsonIssues(cleaned);

    return cleaned;
  }

  String _fixJsonIssues(String json) {
    json = json.replaceAll(RegExp(r'}\s*{'), '},{');
    json = json.replaceAll(RegExp(r']\s*{'), '],{');
    json = json.replaceAll(RegExp(r'}\s*"'), '},"');
    json = json.replaceAll(RegExp(r'}\s*\n\s*{'), '},{');
    json = json.replaceAll(RegExp(r'}\s*\n\s*"'), '},"');
    json = json.replaceAll(RegExp(r'"\s*\n\s*"'), '",\n  "');
    json = json.replaceAll(RegExp(r'"\s*"'), '",\n  "');
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*{'), '}},\n    {');
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*"'), '}},\n    "');
    json =
        json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*}\s*\n\s*{'), '}}},\n    {');
    json =
        json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*}\s*\n\s*"'), '}}},\n    "');

    return json;
  }

  @override
  void dispose() {
    followUpController.dispose();
    super.dispose();
  }
}
