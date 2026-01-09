import 'dart:math';
import '../data/models/course.dart';

class FuzzyMatchingService {
  Course? findBestCourseMatch(String rawScheduleName, List<Course> courses, {double threshold = 0.4}) {
    Course? bestCourse;
    double bestScore = 0.0;

    final cleanScheduleName = _cleanScheduleName(rawScheduleName);
    final normalizedSchedule = _normalize(cleanScheduleName);
    final scheduleTokens = _tokenize(normalizedSchedule);

    if (scheduleTokens.isEmpty) return null;

    for (var course in courses) {
      final normalizedCourse = _normalize(course.name);

      if (normalizedCourse == normalizedSchedule) {
        return course;
      }

      double currentScore = 0.0;

      // İçerme kontrolü
      if (normalizedSchedule.contains(normalizedCourse) || normalizedCourse.contains(normalizedSchedule)) {
        double score = 0.9;
        int lenDiff = (normalizedSchedule.length - normalizedCourse.length).abs();

        if (lenDiff > 20) {
          score -= 0.25;
        } else if (lenDiff > 10) {
          score -= 0.1;
        }

        if (score > currentScore) currentScore = score;
      }

      // Benzerlik kontrolü
      final courseTokens = _tokenize(normalizedCourse);
      if (courseTokens.isNotEmpty) {
        double courseInSchedule = _calculateTokenInclusion(courseTokens, scheduleTokens);
        double scheduleInCourse = _calculateTokenInclusion(scheduleTokens, courseTokens);
        double rawScore = max(courseInSchedule, scheduleInCourse);
        double jaccard = _calculateJaccard(scheduleTokens, courseTokens);
        double tokenScore = (rawScore * 0.8) + (jaccard * 0.2);

        if (tokenScore > currentScore) currentScore = tokenScore;
      }

      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestCourse = course;
      }
    }

    if (bestScore > threshold) {
      print("MATCH: '$rawScheduleName' -> '${bestCourse?.name}' (Score: ${bestScore.toStringAsFixed(2)})");
    }

    return bestScore >= threshold ? bestCourse : null;
  }

  String _cleanScheduleName(String input) {
    String clean = input;


    clean = clean.replaceAll(RegExp(r'Grup\s*\d+[:\s]*', caseSensitive: false), ' ');
    clean = clean.replaceAll(RegExp(r'\b(Ders|Uygulama)\b', caseSensitive: false), ' ');
    clean = clean.replaceAll(RegExp(r'\b(Prof\.|Doç\.|Dr\.|Öğr\.|Arş\.|Grv\.)\s*\w+', caseSensitive: false), ' ');

    return clean;
  }

  double _calculateTokenInclusion(List<String> sourceTokens, List<String> targetTokens) {
    if (sourceTokens.isEmpty) return 0.0;
    double matchedCount = 0.0;

    for (var srcToken in sourceTokens) {
      double maxTokenScore = 0.0;
      for (var targetToken in targetTokens) {
        double sim = _calculateTokenSimilarity(srcToken, targetToken);
        if (sim > maxTokenScore) maxTokenScore = sim;
        if (maxTokenScore == 1.0) break;
      }
      matchedCount += maxTokenScore;
    }
    return matchedCount / sourceTokens.length;
  }

  double _calculateJaccard(List<String> tokensA, List<String> tokensB) {
    double intersection = 0.0;
    for (var a in tokensA) {
      for (var b in tokensB) {
        if (_calculateTokenSimilarity(a, b) > 0.85) {
          intersection += 1.0;
          break;
        }
      }
    }
    double union = tokensA.length + tokensB.length - intersection;
    return union == 0 ? 0.0 : intersection / union;
  }

  double _calculateTokenSimilarity(String t1, String t2) {
    if (t1 == t2) return 1.0;
    if ((t1 == 'i' || t1 == '1' || t1 == 'l') && (t2 == 'i' || t2 == '1' || t2 == 'l')) return 1.0;
    if ((t1 == 'ii' && t2 == '2') || (t1 == '2' && t2 == 'ii')) return 0.95;
    if ((t1 == 'iii' && t2 == '3') || (t1 == '3' && t2 == 'iii')) return 0.95;

    int dist = _levenshtein(t1, t2);
    int maxLength = max(t1.length, t2.length);
    return maxLength == 0 ? 1.0 : 1.0 - (dist / maxLength);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < t.length + 1; j++) { v0[j] = v1[j]; }
    }
    return v1[t.length];
  }

  String _normalize(String input) {
    String s = input.toLowerCase();
    s = s.replaceAll('\u00A0', ' ')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    s = s.replaceAll(RegExp(r'[^\w\s]'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _tokenize(String input) {
    final stopWords = {'ve', 'veya', 'ile', 'and', 'or', 'for', 'of', 'the', 'to', 'in'};
    return input.split(' ').where((w) => w.isNotEmpty && !stopWords.contains(w)).toList();
  }
}