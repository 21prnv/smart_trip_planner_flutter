import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:smart_trip_planner_flutter/ui/common/app_colors.dart';
import 'package:smart_trip_planner_flutter/ui/common/ui_helpers.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';

import 'home_viewmodel.dart';
import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white/cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hey Shubham',
                        style: TextStyle(
                          fontSize: 22, // Large font size for greeting
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32), // Dark green color
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '👋',
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32), // Dark green background
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Main question - centered and very large
              const Center(
                child: Text(
                  "What's your vision for this trip?",
                  style: TextStyle(
                    fontSize: 28, // Very large font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Trip input area with light green border
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50)
                        .withOpacity(0.3), // Light green border
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: viewModel.tripDescriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your dream trip...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16, // Standard paragraph font size
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: viewModel.onVoiceInputTap,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.mic,
                              color: Color(0xFF2E7D32), // Dark green microphone
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create itinerary button - updated to match the design exactly
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(15), // More rounded for pill shape
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(
                          0xFF2E8B57), // Dark teal/deep green (lighter at top)
                      Color(0xFF1B5E20), // Darker teal/green (darker at bottom)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: viewModel.onCreateItineraryTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create My Itinerary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Saved itineraries section - updated to match the design exactly
              const Center(
                child: Text(
                  'Offline Saved Itineraries',
                  style: TextStyle(
                    fontSize: 22, // Large, prominent font size
                    fontWeight: FontWeight.w600, // Medium to semi-bold
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Saved itineraries list - updated design
              Expanded(
                child: viewModel.isBusy
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.savedConversations.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: viewModel.savedConversations.length,
                            itemBuilder: (context, index) {
                              final conversation =
                                  viewModel.savedConversations[index];
                              return _buildSavedItineraryCard(
                                  conversation, viewModel);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved itineraries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first itinerary to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedItineraryCard(
      SavedConversation conversation, HomeViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.onViewConversation(conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16), // Significantly rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Teal-green circular dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2E8B57), // Teal-green color
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Text(
                conversation.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal, // Regular font weight
                  color: Colors.black,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}
