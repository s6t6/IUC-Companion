import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'di/locator.dart';
import 'services/school_event_service.dart';
import 'services/announcement_worker_service.dart';
import 'services/transcript_service.dart';
import 'services/schedule_service.dart';
import 'data/repositories/university_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/announcement_repository.dart';
import 'data/local/app_database.dart';
import 'utils/permission_helper.dart';

import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/transcript_viewmodel.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'viewmodels/simulation_viewmodel.dart';
import 'viewmodels/announcement_viewmodel.dart';

import 'views/onboarding_view.dart';
import 'views/main_screen.dart';
import 'views/announcement_list_view.dart';
import 'views/silent_mode_settings_view.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  final prefs = await SharedPreferences.getInstance();
  final bool hasProfile = prefs.containsKey('user_department_guid');


  await AnnouncementWorkerService.initialize();
  await AnnouncementWorkerService.registerPeriodicTask();
  await SchoolEventService.restoreState();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      _handleNotificationClick(response.payload);
    },
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  String? initialPayload;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = notificationAppLaunchDetails?.notificationResponse?.payload;
  }

  runApp(MyApp(
    hasProfile: hasProfile,
    prefs: prefs,
    initialPayload: initialPayload,
  ));
}

void _handleNotificationClick(String? payload) {
  if (payload == 'announcement_view') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AnnouncementListView()),
    );
  } else if (payload == 'silent_mode_view') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const SilentModeSettingsView()),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool hasProfile;
  final SharedPreferences prefs;
  final String? initialPayload;

  const MyApp({
    super.key,
    required this.hasProfile,
    required this.prefs,
    this.initialPayload,
  });

  @override
  Widget build(BuildContext context) {
    final transcriptService = TranscriptService();
    final scheduleService = ScheduleService();

    return MultiProvider(
      providers: [
        Provider<UniversityRepository>(create: (_) => locator<UniversityRepository>()),
        Provider<ScheduleRepository>(create: (_) => locator<ScheduleRepository>()),
        Provider<AppDatabase>(create: (_) => locator<AppDatabase>()),
        Provider<AnnouncementRepository>(create: (_) => locator<AnnouncementRepository>()),

        ChangeNotifierProvider(
          create: (_) => OnboardingViewModel(
            locator<UniversityRepository>(),
            locator<ScheduleRepository>(),
            transcriptService,
            scheduleService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementViewModel(locator<AnnouncementRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(locator<UniversityRepository>(), locator<ScheduleRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleViewModel(
            locator<ScheduleRepository>(),
            locator<UniversityRepository>(),
            scheduleService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SimulationViewModel(locator<UniversityRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => TranscriptViewModel(locator<UniversityRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'IUC Companion',
            debugShowCheckedModeBanner: false,
            theme: themeVM.currentTheme,
            home: hasProfile
                ? MainScreenWrapperWithPayload(initialPayload: initialPayload)
                : const OnboardingView(),
          );
        },
      ),
    );
  }
}

class MainScreenWrapperWithPayload extends StatefulWidget {
  final String? initialPayload;
  const MainScreenWrapperWithPayload({super.key, this.initialPayload});

  @override
  State<MainScreenWrapperWithPayload> createState() => _MainScreenWrapperWithPayloadState();
}

class _MainScreenWrapperWithPayloadState extends State<MainScreenWrapperWithPayload> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHelper.ensureNotificationPermission(context);
      if (widget.initialPayload != null) {
        _handleNotificationClick(widget.initialPayload);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}