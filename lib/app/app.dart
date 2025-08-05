import 'package:smart_trip_planner_flutter/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:smart_trip_planner_flutter/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:smart_trip_planner_flutter/ui/views/home/home_view.dart';
import 'package:smart_trip_planner_flutter/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_trip_planner_flutter/ui/views/followup_itinerarie/followup_itinerarie_view.dart';
import 'package:smart_trip_planner_flutter/services/gemini_service.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: FollowupItinerarieView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: GeminiService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
