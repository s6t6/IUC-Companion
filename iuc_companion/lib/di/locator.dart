import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../services/api_service.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/announcement_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupDependencies() async {
  // SharedPreferences
  if (!locator.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    locator.registerSingleton<SharedPreferences>(prefs);
  }

  // Database
  if (!locator.isRegistered<AppDatabase>()) {
    final database = await AppDatabase.init();
    locator.registerSingleton<AppDatabase>(database);
  }

  // API Service
  if (!locator.isRegistered<ApiService>()) {
    locator.registerLazySingleton<ApiService>(() => ApiService());
  }

  // Repositories
  if (!locator.isRegistered<UniversityRepository>()) {
    locator.registerLazySingleton<UniversityRepository>(() =>
        UniversityRepository(locator<ApiService>(), locator<AppDatabase>())
    );
  }

  if (!locator.isRegistered<ScheduleRepository>()) {
    locator.registerLazySingleton<ScheduleRepository>(() =>
        ScheduleRepository(locator<AppDatabase>())
    );
  }

  if (!locator.isRegistered<AnnouncementRepository>()) {
    locator.registerLazySingleton<AnnouncementRepository>(() =>
        AnnouncementRepository(locator<AppDatabase>(), locator<ApiService>())
    );
  }
}