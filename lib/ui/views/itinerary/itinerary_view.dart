import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'dart:convert';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'itinerary_viewmodel.dart';

class ItineraryView extends StackedView<ItineraryViewModel> {
  final Map<String, dynamic>? arguments;

  const ItineraryView({Key? key, this.arguments}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ItineraryViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light off-white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: viewModel.onBackTap,
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
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

              const SizedBox(height: 20),

              // Title Section
              Center(
                child: Text(
                  viewModel.isLoading
                      ? 'Creating Itinerary...'
                      : 'Itinerary Created �',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Main Content Area
              Expanded(
                child: viewModel.isLoading || viewModel.isGenerating
                    ? _buildLoadingCard(viewModel)
                    : _buildItineraryCard(viewModel),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(viewModel, context),

              const SizedBox(height: 20), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ItineraryViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            viewModel.isLoading
                ? 'Itinerary Created �'
                : 'Generating itinerary...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(ItineraryViewModel viewModel) {
    if (viewModel.itinerary == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3), width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to parse itinerary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  viewModel.generatedContent,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final itinerary = viewModel.itinerary!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itinerary.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${itinerary.startDate} to ${itinerary.endDate}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (itinerary.days.isNotEmpty) ...[
            Text(
              '${itinerary.days.first.date}: ${itinerary.days.first.summary}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...itinerary.days.first.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.time} - ${item.activity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                height: 1.4,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => viewModel
                                  .onOpenMapsTapWithCoordinates(item.location),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Red pushpin icon
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    // Blue underlined text
                                    Text(
                                      'Open in maps',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // External link icon
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.blue[600],
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      ItineraryViewModel viewModel, BuildContext context) {
    final bool isDisabled = viewModel.isLoading ||
        viewModel.isGenerating ||
        viewModel.itinerary == null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed:
                isDisabled ? null : () => viewModel.onFollowUpTap(context),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: const Text(
              'Follow up to refine',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled
                  ? const Color(0xFFBDBDBD)
                  : const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: isDisabled ? 0 : 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isDisabled ? null : viewModel.onSaveOfflineTap,
            icon: Icon(
              Icons.download,
              color: isDisabled ? Colors.grey : Colors.grey[700],
            ),
            label: Text(
              'Save Offline',
              style: TextStyle(
                color: isDisabled ? Colors.grey : Colors.grey[700],
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDisabled ? Colors.grey[300]! : Colors.grey[400]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  ItineraryViewModel viewModelBuilder(BuildContext context) =>
      ItineraryViewModel(arguments: arguments);
}
