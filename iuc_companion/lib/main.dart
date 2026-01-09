import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/transcript_viewmodel.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/schedule_viewmodel.dart';
import 'viewmodels/simulation_viewmodel.dart';

import 'services/api_service.dart';
import 'services/transcript_service.dart';
import 'services/schedule_service.dart';
import 'data/repositories/university_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/local/app_database.dart';
import 'views/onboarding_view.dart';
import 'views/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool hasProfile = prefs.containsKey('user_department_guid');

  final database = await $FloorAppDatabase
      .databaseBuilder('app_database.db')
      .build();

  runApp(MyApp(
    hasProfile: hasProfile,
    prefs: prefs,
    database: database,
  ));
}

class MyApp extends StatelessWidget {
  final bool hasProfile;
  final SharedPreferences prefs;
  final AppDatabase database;

  const MyApp({
    super.key,
    required this.hasProfile,
    required this.prefs,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    // Servisler
    final apiService = ApiService();
    final transcriptService = TranscriptService();
    final scheduleService = ScheduleService();

    // Repo
    final universityRepository = UniversityRepository(apiService, database);
    final scheduleRepository = ScheduleRepository(database);

    // DI
    return MultiProvider(
      providers: [
        Provider<UniversityRepository>.value(value: universityRepository),
        Provider<ScheduleRepository>.value(value: scheduleRepository),
        Provider<AppDatabase>.value(value: database),

        ChangeNotifierProvider(
          create: (_) => OnboardingViewModel(
            universityRepository,
            scheduleRepository,
            transcriptService,
            scheduleService,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => HomeViewModel(universityRepository, scheduleRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleViewModel(
            scheduleRepository,
            universityRepository,
            scheduleService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SimulationViewModel(universityRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TranscriptViewModel(universityRepository),
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, child) {
          return MaterialApp(
            title: 'IUC Companion',
            debugShowCheckedModeBanner: false,
            theme: themeVM.currentTheme,
            home: hasProfile ? const MainScreen() : const OnboardingView(),
          );
        },
      ),
    );
  }
}