import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/announcement_source.dart';
import 'dao.dart';
import '../models/course.dart';
import '../models/schedule_item.dart';
import '../models/student_grade.dart';
import '../models/profile.dart';
import '../models/active_course.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [Course, ScheduleItem, StudentGrade, Profile, ActiveCourse, AnnouncementSource])
abstract class AppDatabase extends FloorDatabase {
  CourseDao get courseDao;
  ScheduleDao get scheduleDao;
  GradeDao get gradeDao;
  ProfileDao get profileDao;
  ActiveCourseDao get activeCourseDao;
  AnnouncementDao get announcementDao;

  static Future<AppDatabase> init() async {
    return await $FloorAppDatabase
        .databaseBuilder('app_database.db')
        .addCallback(Callback(
      onConfigure: (database) async {
        await database.rawQuery('PRAGMA journal_mode = WAL');
      },
    ))
        .build();
  }
  @override
  Future<void> close() async {
    print("DB Kapatıldı! StackTrace:\n${StackTrace.current}");
    await super.close();
  }
}