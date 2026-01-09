import 'dart:core';

class SemesterHelper {
  static List<String> sortSemesters(Iterable<String> semesters) {
    final sortedList = semesters.toList();
    sortedList.sort(_compareSemesters);
    return sortedList;
  }

  static int _compareSemesters(String a, String b) {
    final int? numA = _extractNumber(a);
    final int? numB = _extractNumber(b);

    if (numA != null && numB != null && numA != numB) {
      return numA.compareTo(numB);
    }

    final bool isAGuz = a.toLowerCase().contains("güz");
    final bool isBGuz = b.toLowerCase().contains("güz");
    final bool isABahar = a.toLowerCase().contains("bahar");
    final bool isBBahar = b.toLowerCase().contains("bahar");

    if (isAGuz && isBBahar) return -1;
    if (isABahar && isBGuz) return 1;

    return a.compareTo(b);
  }

  static int? _extractNumber(String text) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(text);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}