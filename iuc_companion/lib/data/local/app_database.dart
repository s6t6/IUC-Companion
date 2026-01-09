import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'dao.dart';
import '../models/course.dart';
import '../models/schedule_item.dart';
import '../models/student_grade.dart';
import '../models/profile.dart';
import '../models/active_course.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [Course, ScheduleItem, StudentGrade, Profile, ActiveCourse])
abstract class AppDatabase extends FloorDatabase {
  CourseDao get courseDao;
  ScheduleDao get scheduleDao;
  GradeDao get gradeDao;
  ProfileDao get profileDao;
  ActiveCourseDao get activeCourseDao;
}