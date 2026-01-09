// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  CourseDao? _courseDaoInstance;

  ScheduleDao? _scheduleDaoInstance;

  GradeDao? _gradeDaoInstance;

  ProfileDao? _profileDaoInstance;

  ActiveCourseDao? _activeCourseDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Course` (`code` TEXT NOT NULL, `departmentId` INTEGER NOT NULL, `departmentGuid` TEXT, `name` TEXT NOT NULL, `credit` REAL NOT NULL, `ects` REAL NOT NULL, `isMandatory` INTEGER NOT NULL, `theory` INTEGER NOT NULL, `practice` INTEGER NOT NULL, `lab` INTEGER NOT NULL, `semester` TEXT NOT NULL, `linkId` TEXT NOT NULL, `unitId` TEXT NOT NULL, `year` INTEGER, `isRemoved` INTEGER NOT NULL, PRIMARY KEY (`code`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduleItem` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `profileId` INTEGER NOT NULL, `courseCode` TEXT, `day` TEXT NOT NULL, `time` TEXT NOT NULL, `courseName` TEXT NOT NULL, `instructor` TEXT NOT NULL, `location` TEXT NOT NULL, `semester` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `StudentGrade` (`profileId` INTEGER NOT NULL, `courseCode` TEXT NOT NULL, `letterGrade` TEXT NOT NULL, PRIMARY KEY (`profileId`, `courseCode`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Profile` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `profileName` TEXT NOT NULL, `departmentGuid` TEXT NOT NULL, `departmentName` TEXT NOT NULL, `facultyId` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ActiveCourse` (`profileId` INTEGER NOT NULL, `courseCode` TEXT NOT NULL, `colorValue` INTEGER NOT NULL, PRIMARY KEY (`profileId`, `courseCode`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  CourseDao get courseDao {
    return _courseDaoInstance ??= _$CourseDao(database, changeListener);
  }

  @override
  ScheduleDao get scheduleDao {
    return _scheduleDaoInstance ??= _$ScheduleDao(database, changeListener);
  }

  @override
  GradeDao get gradeDao {
    return _gradeDaoInstance ??= _$GradeDao(database, changeListener);
  }

  @override
  ProfileDao get profileDao {
    return _profileDaoInstance ??= _$ProfileDao(database, changeListener);
  }

  @override
  ActiveCourseDao get activeCourseDao {
    return _activeCourseDaoInstance ??=
        _$ActiveCourseDao(database, changeListener);
  }
}

class _$CourseDao extends CourseDao {
  _$CourseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _courseInsertionAdapter = InsertionAdapter(
            database,
            'Course',
            (Course item) => <String, Object?>{
                  'code': item.code,
                  'departmentId': item.departmentId,
                  'departmentGuid': item.departmentGuid,
                  'name': item.name,
                  'credit': item.credit,
                  'ects': item.ects,
                  'isMandatory': item.isMandatory ? 1 : 0,
                  'theory': item.theory,
                  'practice': item.practice,
                  'lab': item.lab,
                  'semester': item.semester,
                  'linkId': item.linkId,
                  'unitId': item.unitId,
                  'year': item.year,
                  'isRemoved': item.isRemoved ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Course> _courseInsertionAdapter;

  @override
  Future<List<Course>> getCoursesByDepartment(String deptGuid) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Course WHERE departmentGuid = ?1',
        mapper: (Map<String, Object?> row) => Course(
            code: row['code'] as String,
            departmentId: row['departmentId'] as int,
            departmentGuid: row['departmentGuid'] as String?,
            name: row['name'] as String,
            credit: row['credit'] as double,
            ects: row['ects'] as double,
            isMandatory: (row['isMandatory'] as int) != 0,
            theory: row['theory'] as int,
            practice: row['practice'] as int,
            lab: row['lab'] as int,
            semester: row['semester'] as String,
            linkId: row['linkId'] as String,
            unitId: row['unitId'] as String,
            year: row['year'] as int?,
            isRemoved: (row['isRemoved'] as int) != 0),
        arguments: [deptGuid]);
  }

  @override
  Future<void> clearCoursesByDepartment(String deptGuid) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Course WHERE departmentGuid = ?1',
        arguments: [deptGuid]);
  }

  @override
  Future<void> insertAllCourses(List<Course> courses) async {
    await _courseInsertionAdapter.insertList(
        courses, OnConflictStrategy.replace);
  }
}

class _$ScheduleDao extends ScheduleDao {
  _$ScheduleDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _scheduleItemInsertionAdapter = InsertionAdapter(
            database,
            'ScheduleItem',
            (ScheduleItem item) => <String, Object?>{
                  'id': item.id,
                  'profileId': item.profileId,
                  'courseCode': item.courseCode,
                  'day': item.day,
                  'time': item.time,
                  'courseName': item.courseName,
                  'instructor': item.instructor,
                  'location': item.location,
                  'semester': item.semester
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduleItem> _scheduleItemInsertionAdapter;

  @override
  Future<List<ScheduleItem>> getScheduleForProfile(int profileId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduleItem WHERE profileId = ?1',
        mapper: (Map<String, Object?> row) => ScheduleItem(
            id: row['id'] as int?,
            profileId: row['profileId'] as int,
            courseCode: row['courseCode'] as String?,
            day: row['day'] as String,
            time: row['time'] as String,
            courseName: row['courseName'] as String,
            instructor: row['instructor'] as String,
            location: row['location'] as String,
            semester: row['semester'] as String),
        arguments: [profileId]);
  }

  @override
  Future<void> clearScheduleForProfile(int profileId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ScheduleItem WHERE profileId = ?1',
        arguments: [profileId]);
  }

  @override
  Future<void> insertSchedule(List<ScheduleItem> items) async {
    await _scheduleItemInsertionAdapter.insertList(
        items, OnConflictStrategy.replace);
  }
}

class _$GradeDao extends GradeDao {
  _$GradeDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _studentGradeInsertionAdapter = InsertionAdapter(
            database,
            'StudentGrade',
            (StudentGrade item) => <String, Object?>{
                  'profileId': item.profileId,
                  'courseCode': item.courseCode,
                  'letterGrade': item.letterGrade
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<StudentGrade> _studentGradeInsertionAdapter;

  @override
  Future<List<StudentGrade>> getGradesForProfile(int profileId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM StudentGrade WHERE profileId = ?1',
        mapper: (Map<String, Object?> row) => StudentGrade(
            profileId: row['profileId'] as int,
            courseCode: row['courseCode'] as String,
            letterGrade: row['letterGrade'] as String),
        arguments: [profileId]);
  }

  @override
  Future<void> deleteGrade(
    int profileId,
    String code,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM StudentGrade WHERE profileId = ?1 AND courseCode = ?2',
        arguments: [profileId, code]);
  }

  @override
  Future<void> clearGradesForProfile(int profileId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM StudentGrade WHERE profileId = ?1',
        arguments: [profileId]);
  }

  @override
  Future<void> insertGrade(StudentGrade grade) async {
    await _studentGradeInsertionAdapter.insert(
        grade, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertGrades(List<StudentGrade> grades) async {
    await _studentGradeInsertionAdapter.insertList(
        grades, OnConflictStrategy.replace);
  }
}

class _$ProfileDao extends ProfileDao {
  _$ProfileDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _profileInsertionAdapter = InsertionAdapter(
            database,
            'Profile',
            (Profile item) => <String, Object?>{
                  'id': item.id,
                  'profileName': item.profileName,
                  'departmentGuid': item.departmentGuid,
                  'departmentName': item.departmentName,
                  'facultyId': item.facultyId
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Profile> _profileInsertionAdapter;

  @override
  Future<List<Profile>> getAllProfiles() async {
    return _queryAdapter.queryList('SELECT * FROM Profile',
        mapper: (Map<String, Object?> row) => Profile(
            id: row['id'] as int?,
            profileName: row['profileName'] as String,
            departmentGuid: row['departmentGuid'] as String,
            departmentName: row['departmentName'] as String,
            facultyId: row['facultyId'] as int));
  }

  @override
  Future<void> deleteProfile(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Profile WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<int> insertProfile(Profile profile) {
    return _profileInsertionAdapter.insertAndReturnId(
        profile, OnConflictStrategy.abort);
  }
}

class _$ActiveCourseDao extends ActiveCourseDao {
  _$ActiveCourseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _activeCourseInsertionAdapter = InsertionAdapter(
            database,
            'ActiveCourse',
            (ActiveCourse item) => <String, Object?>{
                  'profileId': item.profileId,
                  'courseCode': item.courseCode,
                  'colorValue': item.colorValue
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ActiveCourse> _activeCourseInsertionAdapter;

  @override
  Future<List<ActiveCourse>> getActiveCourses(int profileId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ActiveCourse WHERE profileId = ?1',
        mapper: (Map<String, Object?> row) => ActiveCourse(
            profileId: row['profileId'] as int,
            courseCode: row['courseCode'] as String,
            colorValue: row['colorValue'] as int),
        arguments: [profileId]);
  }

  @override
  Future<void> deleteActiveCourse(
    int profileId,
    String courseCode,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM ActiveCourse WHERE profileId = ?1 AND courseCode = ?2',
        arguments: [profileId, courseCode]);
  }

  @override
  Future<void> insertActiveCourse(ActiveCourse activeCourse) async {
    await _activeCourseInsertionAdapter.insert(
        activeCourse, OnConflictStrategy.replace);
  }
}
