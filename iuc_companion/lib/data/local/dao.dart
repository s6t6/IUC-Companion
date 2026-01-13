import 'package:floor/floor.dart';
import '../models/active_course.dart';
import '../models/announcement_source.dart';
import '../models/course.dart';
import '../models/schedule_item.dart';
import '../models/student_grade.dart';
import '../models/profile.dart';

@dao
abstract class CourseDao {
  @Query('SELECT * FROM Course WHERE departmentGuid = :deptGuid')
  Future<List<Course>> getCoursesByDepartment(String deptGuid);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAllCourses(List<Course> courses);

  @Query('DELETE FROM Course WHERE departmentGuid = :deptGuid')
  Future<void> clearCoursesByDepartment(String deptGuid);
}

@dao
abstract class ScheduleDao {
  @Query('SELECT * FROM ScheduleItem WHERE profileId = :profileId')
  Future<List<ScheduleItem>> getScheduleForProfile(int profileId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchedule(List<ScheduleItem> items);

  @Query('DELETE FROM ScheduleItem WHERE profileId = :profileId')
  Future<void> clearScheduleForProfile(int profileId);

  @delete
  Future<void> deleteScheduleItem(ScheduleItem item);

  @Query('DELETE FROM ScheduleItem WHERE profileId = :profileId AND courseCode = :courseCode')
  Future<void> deleteScheduleItemsByCourse(int profileId, String courseCode);
}

@dao
abstract class GradeDao {
  @Query('SELECT * FROM StudentGrade WHERE profileId = :profileId')
  Future<List<StudentGrade>> getGradesForProfile(int profileId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertGrade(StudentGrade grade);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertGrades(List<StudentGrade> grades);

  @Query('DELETE FROM StudentGrade WHERE profileId = :profileId AND courseCode = :code')
  Future<void> deleteGrade(int profileId, String code);

  @Query('DELETE FROM StudentGrade WHERE profileId = :profileId')
  Future<void> clearGradesForProfile(int profileId);
}

@dao
abstract class ProfileDao {
  @Query('SELECT * FROM Profile')
  Future<List<Profile>> getAllProfiles();

  @Insert()
  Future<int> insertProfile(Profile profile);

  @Query('DELETE FROM Profile WHERE id = :id')
  Future<void> deleteProfile(int id);
}

@dao
abstract class ActiveCourseDao {
  @Query('SELECT * FROM ActiveCourse WHERE profileId = :profileId')
  Future<List<ActiveCourse>> getActiveCourses(int profileId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertActiveCourse(ActiveCourse activeCourse);

  @Query('DELETE FROM ActiveCourse WHERE profileId = :profileId AND courseCode = :courseCode')
  Future<void> deleteActiveCourse(int profileId, String courseCode);
}

@dao
abstract class AnnouncementDao {
  @Query('SELECT * FROM AnnouncementSource')
  Future<List<AnnouncementSource>> getAllSources();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSource(AnnouncementSource source);

  @delete
  Future<void> deleteSource(AnnouncementSource source);

  @Query('UPDATE AnnouncementSource SET lastAnnouncementId = :lastId, lastCheckDate = :checkDate WHERE id = :id')
  Future<void> updateSourceStatus(int id, String lastId, String checkDate);
}