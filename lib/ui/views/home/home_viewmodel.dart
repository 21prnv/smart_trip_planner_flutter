import 'package:flutter/material.dart';
import 'package:smart_trip_planner_flutter/app/app.bottomsheets.dart';
import 'package:smart_trip_planner_flutter/app/app.dialogs.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';
import 'package:smart_trip_planner_flutter/ui/common/app_strings.dart';
import 'package:smart_trip_planner_flutter/ui/views/itinerary/itinerary_view.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _navigationService = locator<NavigationService>();

  // User name for greeting
  String get userName => 'Shubham';

  // Text controller for trip description input
  final TextEditingController tripDescriptionController =
      TextEditingController();

  // Sample saved itineraries
  List<String> get savedItineraries => [
        'Japan Trip, 20 days vacation, explore ky...',
        'India Trip, 7 days work trip, suggest affor...',
        'Europe trip, include Paris, Berlin, Dortmun...',
        'Two days weekend getaway to somewhe...',
      ];

  HomeViewModel() {
    // Set initial text as shown in the design
    tripDescriptionController.text =
        '7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!';
  }

  void onVoiceInputTap() {
    // Handle voice input functionality
    _dialogService.showCustomDialog(
      variant: DialogType.infoAlert,
      title: 'Voice Input',
      description: 'Voice input feature coming soon!',
    );
  }

  void onCreateItineraryTap() {
    // Navigate to itinerary view with trip description
    if (tripDescriptionController.text.trim().isNotEmpty) {
      _navigationService.navigateToView(ItineraryView(
        arguments: {'tripDescription': tripDescriptionController.text},
      ));
    } else {
      _dialogService.showCustomDialog(
        variant: DialogType.infoAlert,
        title: 'Input Required',
        description: 'Please describe your trip vision first.',
      );
    }
  }

  @override
  void dispose() {
    tripDescriptionController.dispose();
    super.dispose();
  }
}
