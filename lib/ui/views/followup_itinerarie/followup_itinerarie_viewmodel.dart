import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
import 'package:smart_trip_planner_flutter/services/storage_service.dart';
import 'package:smart_trip_planner_flutter/services/itinerary_processor.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowupItinerarieViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _geminiService = locator<GeminiService>();
  final _storageService = locator<StorageService>();

  final Map<String, dynamic>? arguments;

  FollowupItinerarieViewModel({this.arguments}) {
    _itinerary = arguments?['itinerary'];
    _isReadOnly = arguments?['isReadOnly'] ?? false;
    _initializeChatHistory();
  }

  String get tripDescription => arguments?['tripDescription'] ?? '';
  String get aiResponse => arguments?['aiResponse'] ?? '';
  Itinerary? _itinerary;
  Itinerary? get itinerary => _itinerary;

  final TextEditingController followUpController = TextEditingController();

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  String _streamingText = '';
  String get streamingText => _streamingText;

  bool _isReadOnly = false;
  bool get isReadOnly => _isReadOnly;

  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> get chatHistory => _chatHistory;

  String? _conversationId;

  void _initializeChatHistory() {
    if (_isReadOnly) {
      final existingChatHistory =
          arguments?['chatHistory'] as List<Map<String, dynamic>>?;
      if (existingChatHistory != null) {
        _chatHistory = existingChatHistory;
      }
      _conversationId = arguments?['conversationId'];
    } else {
      if (tripDescription.isNotEmpty && _itinerary != null) {
        _chatHistory.add({
          'user': tripDescription,
          'aiResponse': _itinerary,
        });

        _conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      }
    }
  }

  void onBackTap() {
    _navigationService.back();
  }

  void onCopyUserQuery() {
    Clipboard.setData(ClipboardData(text: tripDescription));
  }

  void onCopyItinerary() {
    if (_itinerary != null) {
      final itineraryText = _formatItineraryForCopy(_itinerary!);
      Clipboard.setData(ClipboardData(text: itineraryText));
      Fluttertoast.showToast(
        msg: "Itinerary copied to clipboard",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
  }

  void onSaveOffline() {
    if (_itinerary != null) {
      _saveConversationToHive();
      Fluttertoast.showToast(
        msg: "Itinerary saved offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    }
  }

  void onRegenerate() {
    Fluttertoast.showToast(
      msg: "Creating a new itinerary based on your preferences...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  void onOpenMapsTap() {
    Fluttertoast.showToast(
      msg: "This would open Google Maps with the route.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  void onVoiceInputTap() {
    Fluttertoast.showToast(
      msg: "Voice input feature coming soon!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  Future<void> onOpenMapsTapWithCoordinates(String coordinates) async {
    try {
      final url = 'https://www.google.com/maps?q=$coordinates';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: "Could not open Google Maps.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to open maps: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> onSendMessage() async {
    if (_isReadOnly) {
      Fluttertoast.showToast(
        msg: "This conversation is in read-only mode.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final message = followUpController.text.trim();
    if (message.isEmpty) return;

    _chatHistory.add({
      'user': message,
      'aiResponse': null,
    });

    followUpController.clear();
    notifyListeners();

    _isThinking = true;
    _streamingText = '';
    notifyListeners();

    try {
      if (!_geminiService.isReady) {
        throw Exception(
            'AI service is not ready. Please check your internet connection and try again.');
      }

      final List<Map<String, String>> formattedChatHistory = _chatHistory
          .where((entry) => entry['aiResponse'] != null)
          .map((entry) => {
                'role': 'user',
                'content': entry['user'] as String,
              })
          .toList();

      formattedChatHistory.add({
        'role': 'user',
        'content': message,
      });

      String fullResponse = '';
      Itinerary? newItinerary;

      await for (String chunk
          in _geminiService.generateItineraryWithFunctionCalling(
        message,
        _itinerary,
        formattedChatHistory,
      )) {
        fullResponse += chunk;
        _streamingText = fullResponse;
        notifyListeners();

        try {
          String cleanedResponse = _cleanJsonResponse(fullResponse);
          final jsonData = json.decode(cleanedResponse);
          newItinerary = Itinerary.fromJson(jsonData);
          break;
        } catch (e) {}
      }

      if (_chatHistory.isNotEmpty) {
        _chatHistory.last['aiResponse'] = newItinerary ?? fullResponse;
      }

      if (newItinerary != null) {
        _itinerary = newItinerary;
      }

      await _saveConversationToHive();
    } catch (e) {
      if (_chatHistory.isNotEmpty) {
        _chatHistory.last['aiResponse'] = 'Error: ${e.toString()}';
      }

      Fluttertoast.showToast(
        msg: "Failed to generate response. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      _isThinking = false;
      _streamingText = '';
      notifyListeners();
    }
  }

  Future<void> _saveConversationToHive() async {
    if (_chatHistory.isNotEmpty && _conversationId != null) {
      try {
        final title = _itinerary?.title ?? 'Trip Planning Conversation';

        await _storageService.saveConversation(
          id: _conversationId!,
          title: title,
          initialPrompt: tripDescription,
          chatHistory: _chatHistory,
          currentItinerary: _itinerary,
        );
        Fluttertoast.showToast(
          msg: "Itinerary saved offline",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {}
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

  String _formatItineraryForCopy(Itinerary itinerary) {
    final buffer = StringBuffer();
    buffer.writeln('${itinerary.title}');
    buffer.writeln('${itinerary.startDate} to ${itinerary.endDate}');
    buffer.writeln();

    if (itinerary.days.isNotEmpty) {
      final day = itinerary.days.first;
      buffer.writeln('${day.date}: ${day.summary}');
      buffer.writeln();

      for (final item in day.items) {
        buffer.writeln('${item.time} - ${item.activity}');
        buffer.writeln('Location: ${item.location}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  @override
  void dispose() {
    followUpController.dispose();
    super.dispose();
  }
}
