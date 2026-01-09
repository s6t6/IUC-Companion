import 'dart:async';

import '../../services/api_service.dart';
import '../local/app_database.dart';
import '../models/active_course.dart';
import '../models/faculty.dart';
import '../models/department.dart';
import '../models/course.dart';
import '../models/course_detail.dart';
import '../models/student_grade.dart';
import '../models/profile.dart';

class UniversityRepository {
  final ApiService _apiService;
  final AppDatabase _database;

  UniversityRepository(this._apiService, this._database);

  Future<List<Faculty>> fetchFaculties() async {
    return await _apiService.getFaculties();
  }

  Future<CourseDetail> fetchCourseDetail(String courseCode) async {
    return await _apiService.getCourseDetail(courseCode);
  }

  Future<List<Department>> fetchDepartments(int facultyId) async {
    return await _apiService.getDepartments(facultyId: facultyId);
  }

  Future<List<Course>> fetchCoursesByDepartment(String departmentGuid) async {
    try {
      final remoteData = await _apiService
          .getCourses(departmentGuid);

      final coursesToSave = remoteData.map((c) {
        return Course(
          code: c.code,
          departmentId: c.departmentId,
          departmentGuid: departmentGuid,
          name: c.name,
          credit: c.credit,
          ects: c.ects,
          isMandatory: c.isMandatory,
          theory: c.theory,
          practice: c.practice,
          lab: c.lab,
          semester: c.semester,
          linkId: c.linkId,
          unitId: c.unitId,
          year: c.year,
          isRemoved: c.isRemoved,
        );
      }).toList();

      await _database.courseDao.clearCoursesByDepartment(departmentGuid);
      await _database.courseDao.insertAllCourses(coursesToSave);

      return coursesToSave;

    } catch (e) {
      final localData = await _database.courseDao.getCoursesByDepartment(departmentGuid);

      if (localData.isNotEmpty) {
        return localData;
      }
      rethrow;
    }
  }


  Future<List<StudentGrade>> getGradesForProfile(int profileId) async {
    return await _database.gradeDao.getGradesForProfile(profileId);
  }

  Future<void> saveGrade(StudentGrade grade) async {
    await _database.gradeDao.insertGrade(grade);
  }

  Future<void> saveGrades(List<StudentGrade> grades) async {
    await _database.gradeDao.insertGrades(grades);
  }

  Future<void> removeGrade(int profileId, String courseCode) async {
    await _database.gradeDao.deleteGrade(profileId, courseCode);
  }


  Future<List<Profile>> getProfiles() async {
    return await _database.profileDao.getAllProfiles();
  }

  Future<int> createProfile(Profile profile) async {
    return await _database.profileDao.insertProfile(profile);
  }

  Future<void> deleteProfile(int id) async {
    await _database.profileDao.deleteProfile(id);
  }

  Future<List<ActiveCourse>> getActiveCourses(int profileId) async {
    return await _database.activeCourseDao.getActiveCourses(profileId);
  }
}