import 'package:floor/floor.dart';

@entity
class Profile {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String profileName;
  final String departmentGuid;
  final String departmentName;
  final int facultyId;

  Profile({
    this.id,
    required this.profileName,
    required this.departmentGuid,
    required this.departmentName,
    required this.facultyId,
  });
}