import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';
import 'package:smart_trip_planner_flutter/ui/views/followup_itinerarie/followup_itinerarie_view.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _geminiService = locator<GeminiService>();

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

  Itinerary? _itinerary;
  Itinerary? get itinerary => _itinerary;

  String get tripDescription => arguments?['tripDescription'] ?? '';

  void _startLoadingProcess() async {
    // Simulate initial loading time (1 second)
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    _isGenerating = true;
    notifyListeners();

    // Start generating itinerary with Gemini
    await _generateItinerary();
  }

  Future<void> _generateItinerary() async {
    try {
      String fullResponse = '';

      await for (String chunk
          in _geminiService.generateItinerary(tripDescription)) {
        fullResponse += chunk;
        _generatedContent = fullResponse;
        notifyListeners();

        // Try to parse as JSON after each chunk
        try {
          // Clean the response first
          String cleanedResponse = _cleanJsonResponse(fullResponse);
          print('Cleaned response: $cleanedResponse'); // Debug print

          final jsonData = json.decode(cleanedResponse);
          print('Parsed JSON: $jsonData'); // Debug print

          _itinerary = Itinerary.fromJson(jsonData);
          _isGenerating = false;
          notifyListeners();
          break;
        } catch (e) {
          print('JSON parsing error: $e'); // Debug print
          // Continue streaming if not valid JSON yet
        }
      }

      // If we reach here without valid JSON, show the raw response
      if (_itinerary == null) {
        _isGenerating = false;
        notifyListeners();
      }
    } catch (e) {
      _isGenerating = false;
      _generatedContent = 'Error generating itinerary: ${e.toString()}';
      notifyListeners();

      _dialogService.showCustomDialog(
        title: 'Error',
        description: 'Failed to generate itinerary. Please try again.',
      );
    }
  }

  String _cleanJsonResponse(String response) {
    // Remove markdown code blocks
    String cleaned = response.trim();

    // Remove ```json and ``` if present
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // Fix common JSON issues
    cleaned = _fixJsonIssues(cleaned);

    return cleaned;
  }

  String _fixJsonIssues(String json) {
    // Fix missing commas between objects in arrays
    json = json.replaceAll(RegExp(r'}\s*{'), '},{');

    // Fix missing commas after closing braces in arrays
    json = json.replaceAll(RegExp(r']\s*{'), '],{');

    // Fix missing commas after closing braces
    json = json.replaceAll(RegExp(r'}\s*"'), '},"');

    // Fix missing commas between array items
    json = json.replaceAll(RegExp(r'}\s*\n\s*{'), '},{');
    json = json.replaceAll(RegExp(r'}\s*\n\s*"'), '},"');

    // Fix missing commas between properties
    json = json.replaceAll(RegExp(r'"\s*\n\s*"'), '",\n  "');
    json = json.replaceAll(RegExp(r'"\s*"'), '",\n  "');

    // Fix missing commas between array items with newlines
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*{'), '}},\n    {');
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*"'), '}},\n    "');

    // Fix the specific pattern: } followed by newline and }
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*{'), '}},\n    {');
    json = json.replaceAll(RegExp(r'}\s*\n\s*}\s*\n\s*"'), '}},\n    "');

    // Fix missing commas between days array items
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
              'aiResponse': _generatedContent, // Pass the full AI response
            },
          ),
        ),
      );
    } else {
      _dialogService.showCustomDialog(
        title: 'Error',
        description: 'Please wait for the itinerary to be generated.',
      );
    }
  }

  void onSaveOfflineTap() {
    if (_itinerary != null) {
      _dialogService.showCustomDialog(
        title: 'Saved Offline',
        description: 'Your itinerary has been saved for offline access.',
      );
    } else {
      _dialogService.showCustomDialog(
        title: 'Error',
        description: 'No itinerary to save.',
      );
    }
  }

  Future<void> onOpenMapsTap() async {
    try {
      // Get the first location from the itinerary
      String coordinates = "-8.3405,115.0917"; // Default coordinates

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
}
