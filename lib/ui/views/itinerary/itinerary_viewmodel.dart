import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';
import 'package:smart_trip_planner_flutter/ui/views/followup_itinerarie/followup_itinerarie_view.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_trip_planner_flutter/services/storage_service.dart';
import 'package:smart_trip_planner_flutter/services/itinerary_processor.dart';

class ItineraryViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _geminiService = locator<GeminiService>();
  final _storageService = locator<StorageService>();

  final Map<String, dynamic>? arguments;

  ItineraryViewModel({this.arguments}) {
    _startLoadingProcess();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String _generatedContent = '';
  String get generatedContent => _generatedContent;

  // For streaming display
  String _streamingText = '';
  String get streamingText => _streamingText;

  Itinerary? _itinerary;
  Itinerary? get itinerary => _itinerary;

  String get tripDescription => arguments?['tripDescription'] ?? '';

  void _startLoadingProcess() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    _isGenerating = true;
    notifyListeners();

    await _generateItineraryWithIsolate();
  }

  Future<void> _generateItineraryWithIsolate() async {
    try {
      if (!_geminiService.isReady) {
        _isGenerating = false;
        _generatedContent =
            'Error: AI service is not ready. Please check your internet connection and try again.';
        _streamingText = _generatedContent;
        notifyListeners();

        Fluttertoast.showToast(
          msg: "AI service not available. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      String fullResponse = '';
      _streamingText = '';

      await for (String chunk
          in _geminiService.generateItineraryWithFunctionCalling(
        tripDescription,
        null,
        [],
      )) {
        fullResponse += chunk;
        _generatedContent = fullResponse;

        _streamingText = fullResponse;
        notifyListeners();

        try {
          String cleanedResponse = _cleanJsonResponse(fullResponse);

          final jsonData = json.decode(cleanedResponse);

          _itinerary = Itinerary.fromJson(jsonData);
          _isGenerating = false;
          notifyListeners();
          return;
        } catch (e) {}
      }

      if (_itinerary == null) {
        _isGenerating = false;
        notifyListeners();
      }
    } catch (e) {
      _isGenerating = false;
      _generatedContent = 'Error generating itinerary: ${e.toString()}';
      _streamingText = _generatedContent;
      notifyListeners();

      Fluttertoast.showToast(
        msg: "Failed to generate itinerary. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _generateItinerary() async {
    try {
      String fullResponse = '';
      _streamingText = '';

      await for (String chunk
          in _geminiService.generateItinerary(tripDescription)) {
        fullResponse += chunk;
        _generatedContent = fullResponse;

        _streamingText = fullResponse;
        notifyListeners();

        try {
          String cleanedResponse = _cleanJsonResponse(fullResponse);

          final jsonData = json.decode(cleanedResponse);

          _itinerary = Itinerary.fromJson(jsonData);
          _isGenerating = false;
          notifyListeners();
          break;
        } catch (e) {}
      }

      if (_itinerary == null) {
        _isGenerating = false;
        notifyListeners();
      }
    } catch (e) {
      _isGenerating = false;
      _generatedContent = 'Error generating itinerary: ${e.toString()}';
      _streamingText = _generatedContent;
      notifyListeners();

      Fluttertoast.showToast(
        msg: "Failed to generate itinerary. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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

    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*{'), '}},\n    {');
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*"'), '}},\n    "');

    json =
        json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*}\s*\n\s*{'), '}}},\n    {');
    json =
        json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*}\s*\n\s*"'), '}}},\n    "');

    return json;
  }

  void onBackTap() {
    _navigationService.back();
  }

  void onFollowUpTap(BuildContext context) {
    if (_itinerary != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowupItinerarieView(
            arguments: {
              'tripDescription': tripDescription,
              'itinerary': _itinerary,
              'aiResponse': _generatedContent,
            },
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "Please wait for the itinerary to be generated.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void onSaveOfflineTap() async {
    if (_itinerary != null) {
      try {
        final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
        final title = _itinerary!.title;

        final chatHistory = [
          {
            'user': tripDescription,
            'aiResponse': _itinerary,
          }
        ];

        await _storageService.saveConversation(
          id: conversationId,
          title: title,
          initialPrompt: tripDescription,
          chatHistory: chatHistory,
          currentItinerary: _itinerary,
        );
      } catch (e) {}
    } else {
      Fluttertoast.showToast(
        msg: "No itinerary to save.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> onOpenMapsTap() async {
    try {
      String coordinates = "-8.3405,115.0917";

      if (_itinerary != null &&
          _itinerary!.days.isNotEmpty &&
          _itinerary!.days.first.items.isNotEmpty) {
        coordinates = _itinerary!.days.first.items.first.location;
      }

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
}
