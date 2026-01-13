import '../local/app_database.dart';
import '../models/schedule_item.dart';

class ScheduleRepository {
  final AppDatabase _database;

  ScheduleRepository(this._database);

  Future<void> saveSchedule(int profileId, List<ScheduleItem> schedule) async {
    await _database.scheduleDao.clearScheduleForProfile(profileId);
    await _database.scheduleDao.insertSchedule(schedule);
  }

  Future<List<ScheduleItem>> getSchedule(int profileId) async {
    return await _database.scheduleDao.getScheduleForProfile(profileId);
  }

  Future<void> clearSchedule(int profileId) async {
    await _database.scheduleDao.clearScheduleForProfile(profileId);
  }

  Future<void> saveScheduleItems(List<ScheduleItem> items) async {
    await _database.scheduleDao.insertSchedule(items);
  }

  Future<void> deleteScheduleItem(ScheduleItem item) {
    return _database.scheduleDao.deleteScheduleItem(item);
  }

  Future<void> deleteCourse(int profileId, String courseCode) {
    return _database.scheduleDao.deleteScheduleItemsByCourse(profileId, courseCode);
  }
}