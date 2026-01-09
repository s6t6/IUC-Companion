import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../data/models/schedule_item.dart';
import '../data/models/course.dart';
import 'fuzzy_matching_service.dart';

class ScheduleService {
  final FuzzyMatchingService _matcher = FuzzyMatchingService();

  final RegExp _timeRegex = RegExp(r'(\d{1,2}[:.]\d{2}).{0,4}?(\d{1,2}[:.]\d{2})');
  final RegExp _semesterRegex = RegExp(r'(\d+)\.\s*YARIYIL', caseSensitive: false);
  final RegExp _instructorTitleRegex = RegExp(
    r'(Prof\.|Doç\.|Dr\.|Öğr\.|Arş\.|Yrd\.|Grv\.)',
    caseSensitive: false,
  );

  // Parantezli tipleri filtrele (Örn: (Laboratuvar) gider, ama Laboratuvarı kalır)
  final RegExp _courseTypeRegex = RegExp(r'^\s*\((Uygulama|Laboratuvar|Teori|Pratik|Lab)\)\s*$', caseSensitive: false);

  // Footer noise filtresi
  final RegExp _footerNoiseRegex = RegExp(
      r'(Fakülte Ortak Dersleri|Yarıyıl Ortak Dersleri|Bölüm Başkanı|D Grubu|E Grubu|H Grubu)',
      caseSensitive: false
  );

  final List<String> _dayNames = ["pazartesi", "salı", "çarşamba", "perşembe", "cuma"];

  List<ScheduleItem> linkScheduleToCourses(List<ScheduleItem> items, List<Course> knownCourses) {
    if (knownCourses.isEmpty) return items;

    return items.map((item) {
      final bestMatch = _matcher.findBestCourseMatch(item.courseName, knownCourses, threshold: 0.65);

      return ScheduleItem(
        id: item.id,
        profileId: item.profileId,
        courseCode: bestMatch?.code,
        day: item.day,
        time: item.time,
        courseName: item.courseName,
        instructor: item.instructor,
        location: item.location,
        semester: item.semester,
      );
    }).toList();
  }

  Future<List<ScheduleItem>> extractSchedule(File pdfFile) async {
    List<ScheduleItem> allItems = [];

    try {
      final List<int> bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < document.pages.count; i++) {
        try {
          final result = _processPage(document, i, document.pages[i].size);
          allItems.addAll(result.items);
        } catch (e) {
          print("Page $i Error: $e");
        }
      }

      document.dispose();

      if (allItems.isNotEmpty) {
        allItems.sort((a, b) {
          int dayCompare = _dayIndex(a.day).compareTo(_dayIndex(b.day));
          if (dayCompare != 0) return dayCompare;
          return a.time.compareTo(b.time);
        });

        for (int i = 1; i < allItems.length; i++) {
          final current = allItems[i];
          final prev = allItems[i - 1];

          if (current.courseName == "Ders" && current.day == prev.day) {
            allItems[i] = ScheduleItem(
              id: current.id,
              profileId: current.profileId,
              courseCode: current.courseCode,
              day: current.day,
              time: current.time,
              courseName: prev.courseName,
              instructor: current.instructor.isNotEmpty ? current.instructor : prev.instructor,
              location: current.location.isNotEmpty ? current.location : prev.location,
              semester: current.semester,
            );
          }
        }
      }

      return allItems;
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception:", "").trim());
    }
  }

  int _dayIndex(String day) {
    switch (day.toLowerCase()) {
      case 'pazartesi': return 0;
      case 'salı': return 1;
      case 'çarşamba': return 2;
      case 'perşembe': return 3;
      case 'cuma': return 4;
      default: return 5;
    }
  }

  _PageResult _processPage(PdfDocument document, int pageIndex, Size pageSize) {
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final List<TextLine> lines = extractor.extractTextLines(startPageIndex: pageIndex, endPageIndex: pageIndex);

    if (lines.isEmpty) return _PageResult(0, []);

    String currentSemester = "Güz";
    for (var line in lines) {
      if (_semesterRegex.hasMatch(line.text)) {
        currentSemester = line.text.trim();
        break;
      }
    }

    List<TextLine> contentLines = lines.where((l) {
      bool isTime = l.bounds.left < 100 && _timeRegex.hasMatch(l.text);
      bool isHeader = _dayNames.any((d) => l.text.toLowerCase().contains(d));
      return !isTime && !isHeader && l.text.length > 2;
    }).toList();

    // --- 1. SÜTUN TESPİTİ ---
    contentLines.sort((a, b) => a.bounds.center.dx.compareTo(b.bounds.center.dx));
    List<List<TextLine>> clusters = [];
    if (contentLines.isNotEmpty) {
      clusters.add([contentLines.first]);
      for (int i = 1; i < contentLines.length; i++) {
        double currentX = contentLines[i].bounds.center.dx;
        double prevX = clusters.last.last.bounds.center.dx;
        if ((currentX - prevX).abs() < 60) {
          clusters.last.add(contentLines[i]);
        } else {
          clusters.add([contentLines[i]]);
        }
      }
    }

    List<double> clusterCenters = [];
    for (var cluster in clusters) {
      double sum = cluster.fold(0, (sum, item) => sum + item.bounds.center.dx);
      clusterCenters.add(sum / cluster.length);
    }

    List<_ColumnInterval> colIntervals = [];
    List<double> idealCenters = [
      pageSize.width * 0.20,
      pageSize.width * 0.36,
      pageSize.width * 0.52,
      pageSize.width * 0.68,
      pageSize.width * 0.84
    ];

    for (int i = 0; i < 5; i++) {
      String dayName = _dayNames[i];
      String displayDay = dayName[0].toUpperCase() + dayName.substring(1);

      double? bestCenter;
      double minDiff = 1000;

      for (var center in clusterCenters) {
        double diff = (center - idealCenters[i]).abs();
        if (diff < minDiff && diff < 80) {
          minDiff = diff;
          bestCenter = center;
        }
      }

      double startX, endX;
      if (bestCenter != null) {
        startX = bestCenter - 75;
        endX = bestCenter + 75;
      } else {
        startX = idealCenters[i] - 75;
        endX = idealCenters[i] + 75;
      }

      if (i > 0) {
        double prevEnd = colIntervals.last.endX;
        if (startX < prevEnd) startX = prevEnd + 1;
      }
      colIntervals.add(_ColumnInterval(day: displayDay, startX: startX, endX: endX));
    }

    // --- 2. SATIR TESPİTİ ---
    List<_TimeSlot> timeSlots = [];
    for (var line in lines) {
      final match = _timeRegex.firstMatch(line.text.trim());
      if (match != null && line.bounds.left < 150) {
        timeSlots.add(_TimeSlot(text: match.group(0)!, bounds: line.bounds));
      }
    }
    timeSlots.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

    List<_TimeSlot> uniqueTimes = [];
    if (timeSlots.isNotEmpty) {
      uniqueTimes.add(timeSlots.first);
      for (int i = 1; i < timeSlots.length; i++) {
        if ((timeSlots[i].bounds.top - uniqueTimes.last.bounds.top).abs() > 15) {
          uniqueTimes.add(timeSlots[i]);
        }
      }
    }

    List<_RowInterval> rowIntervals = [];
    for (int i = 0; i < uniqueTimes.length; i++) {
      double startY;
      if (i == 0) {
        startY = uniqueTimes[i].bounds.top - 25;
      } else {
        double prevBottom = uniqueTimes[i - 1].bounds.bottom;
        double currTop = uniqueTimes[i].bounds.top;
        startY = (prevBottom + currTop) / 2;
      }

      double endY;
      if (i == uniqueTimes.length - 1) {
        endY = pageSize.height - 30; // Footer'ı dahil etmemek için sınır
      } else {
        double currBottom = uniqueTimes[i].bounds.bottom;
        double nextTop = uniqueTimes[i + 1].bounds.top;
        endY = (currBottom + nextTop) / 2;
      }

      rowIntervals.add(_RowInterval(time: uniqueTimes[i].text, startY: startY, endY: endY));
    }

    // --- 3. HÜCRE EŞLEŞTİRME ---
    Map<String, List<TextLine>> cellMap = {};

    for (var line in lines) {
      String text = line.text.trim();
      if (text.length < 3) continue;
      if (_semesterRegex.hasMatch(text)) continue;
      if (_timeRegex.hasMatch(text) && line.bounds.left < 150) continue;
      if (_dayNames.any((d) => text.toLowerCase().contains(d))) continue;

      double cx = line.bounds.center.dx;
      double cy = line.bounds.center.dy;

      String? matchedDay;
      for (var col in colIntervals) {
        if (cx >= col.startX && cx < col.endX) {
          matchedDay = col.day;
          break;
        }
      }

      String? matchedTime;
      for (var row in rowIntervals) {
        if (cy >= row.startY && cy < row.endY) {
          matchedTime = row.time;
          break;
        }
      }

      if (matchedDay != null && matchedTime != null) {
        String key = "$matchedDay|$matchedTime|$currentSemester";
        cellMap.putIfAbsent(key, () => []).add(line);
      }
    }

    List<ScheduleItem> items = [];
    cellMap.forEach((key, lineList) {
      lineList.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
      String fullText = lineList.map((e) => e.text.trim()).join('\n');
      var parts = key.split('|');

      var content = _parseCellContent(fullText);

      if (content['name'] != null && content['name'] != "Ders") {
        items.add(ScheduleItem(
          profileId: 0,
          day: parts[0],
          time: parts[1],
          semester: parts[2],
          courseName: content['name']!,
          instructor: content['instructor'] ?? '',
          location: content['location'] ?? '',
        ));
      } else if (content['name'] == "Ders" && (content['instructor']!.isNotEmpty || content['location']!.isNotEmpty)) {
        items.add(ScheduleItem(
          profileId: 0,
          day: parts[0],
          time: parts[1],
          semester: parts[2],
          courseName: "Ders",
          instructor: content['instructor'] ?? '',
          location: content['location'] ?? '',
        ));
      }
    });

    return _PageResult(lines.length, items);
  }

  Map<String, String> _parseCellContent(String text) {
    List<String> lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String instructor = "";
    String location = "";
    List<String> nameParts = [];

    final List<String> locationKeywords = ['bina', 'amfi', 'blok', 'salon', 'oda', 'rektörlük', 'işletme', 'uzaktan', 'online'];
    final RegExp roomCodeRegex = RegExp(r'\b[d]\d{3}\b', caseSensitive: false);
    final RegExp labRegex = RegExp(r'\bLab(\.|s)?\b', caseSensitive: false);

    for (var line in lines) {
      if (_footerNoiseRegex.hasMatch(line)) continue;
      if (_courseTypeRegex.hasMatch(line)) continue;
      if (line.startsWith("Grup")) continue;

      String lowerLine = line.toLowerCase();

      if (_instructorTitleRegex.hasMatch(line)) {
        if (instructor.isEmpty) {
          instructor = line;
        } else {
          instructor += " / $line";
        }
        continue;
      }

      bool isLocation = locationKeywords.any((kw) => lowerLine.contains(kw)) ||
          roomCodeRegex.hasMatch(line) ||
          labRegex.hasMatch(line);

      if (isLocation) {
        if (location.isEmpty) {
          location = line;
        } else {
          location += " $line";
        }
        continue;
      }

      nameParts.add(line);
    }

    String courseName = nameParts.join(" ").trim();
    if (courseName.isEmpty) courseName = "Ders";

    return {
      'name': courseName,
      'instructor': instructor,
      'location': location
    };
  }
}

class _PageResult { final int lineCount; final List<ScheduleItem> items; _PageResult(this.lineCount, this.items); }
class _ColumnInterval { final String day; final double startX; final double endX; _ColumnInterval({required this.day, required this.startX, required this.endX}); }
class _TimeSlot { final String text; final Rect bounds; _TimeSlot({required this.text, required this.bounds}); }
class _RowInterval { final String time; final double startY; final double endY; _RowInterval({required this.time, required this.startY, required this.endY}); }