import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_trip_planner_flutter/data/models/chat_message.dart';
import 'package:smart_trip_planner_flutter/data/models/saved_conversation.dart';
import 'package:smart_trip_planner_flutter/data/models/itinerary_model.dart';
import 'package:smart_trip_planner_flutter/firebase_options.dart';
import 'package:smart_trip_planner_flutter/app/app.bottomsheets.dart';
import 'package:smart_trip_planner_flutter/app/app.dialogs.dart';
import 'package:smart_trip_planner_flutter/app/app.locator.dart';
import 'package:smart_trip_planner_flutter/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms (including Windows)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(SavedConversationAdapter());
  Hive.registerAdapter(ItineraryAdapter());
  Hive.registerAdapter(DayAdapter());
  Hive.registerAdapter(ActivityItemAdapter());

  // Setup locator
  await setupLocator();

  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [StackedService.routeObserver],
    );
  }
}
