import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stacked/stacked.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';
import 'package:smart_trip_planner_flutter/services/storage_service.dart';
import 'package:smart_trip_planner_flutter/services/network_service.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/ui/views/itinerary/itinerary_view.dart';
import 'package:smart_trip_planner_flutter/ui/views/followup_itinerarie/followup_itinerarie_view.dart';

class HomeViewModel extends BaseViewModel {
  final _storageService = locator<StorageService>();
  final _navigationService = locator<NavigationService>();
  final _networkService = NetworkService();

  final TextEditingController tripDescriptionController =
      TextEditingController();

  List<SavedConversation> _savedConversations = [];
  List<SavedConversation> get savedConversations => _savedConversations;

  bool _hasNetworkConnection = true;
  bool get hasNetworkConnection => _hasNetworkConnection;

  HomeViewModel() {
    _loadSavedConversations();
    _checkNetworkConnection();
  }

  Future<void> _checkNetworkConnection() async {
    _hasNetworkConnection = await _networkService.hasInternetConnection();
    notifyListeners();
  }

  Future<void> _loadSavedConversations() async {
    setBusy(true);
    try {
      _savedConversations = await _storageService.getRecentConversations();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load saved conversations: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> refreshConversations() async {
    await _loadSavedConversations();
  }

  void onDeleteConversation(String conversationId) async {
    try {
      await _storageService.deleteConversation(conversationId);
      await _loadSavedConversations();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete conversation: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void onViewConversation(SavedConversation conversation) {
    final chatHistory = <Map<String, dynamic>>[];

    final sortedMessages = List<ChatMessage>.from(conversation.messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < sortedMessages.length; i++) {
      final message = sortedMessages[i];

      if (message.role == 'user') {
        ChatMessage? aiResponse;
        for (int j = i + 1; j < sortedMessages.length; j++) {
          if (sortedMessages[j].role == 'ai') {
            aiResponse = sortedMessages[j];
            break;
          }
        }

        chatHistory.add({
          'user': message.content,
          'aiResponse': aiResponse?.itinerary ?? aiResponse?.content,
        });
      }
    }

    _navigationService.navigateToView(FollowupItinerarieView(
      arguments: {
        'tripDescription': conversation.initialPrompt,
        'itinerary': conversation.currentItinerary,
        'aiResponse': conversation.messages
                .where((m) => m.role == 'ai' && m.itinerary != null)
                .firstOrNull
                ?.itinerary
                ?.toJson()
                .toString() ??
            '',
        'chatHistory': chatHistory,
        'isReadOnly': true,
        'conversationId': conversation.id,
      },
    ));
  }

  void onVoiceInputTap() {}

  void onCreateItineraryTap() async {
    final tripDescription = tripDescriptionController.text.trim();
    if (tripDescription.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter a trip description.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (!await _networkService.hasInternetConnection()) {
      Fluttertoast.showToast(
        msg:
            "No internet connection. Please check your network settings and try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    _navigationService.navigateToView(ItineraryView(
      arguments: {'tripDescription': tripDescription},
    ));
  }

  @override
  void dispose() {
    tripDescriptionController.dispose();
    super.dispose();
  }
}
