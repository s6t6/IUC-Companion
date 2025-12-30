import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ScheduleBuilderViewModel extends ChangeNotifier {
  String? programFileName;
  String? syllabusFileName;
  bool isGenerating = false;
  bool isSuccess = false;

  Future<void> pickProgramFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      programFileName = result.files.first.name;
      notifyListeners();
    }
  }

  Future<void> pickSyllabusFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      syllabusFileName = result.files.first.name;
      notifyListeners();
    }
  }

  Future<void> generateSchedule() async {
    if (programFileName == null || syllabusFileName == null) return;

    isGenerating = true;
    isSuccess = false;
    notifyListeners();

    // Burada yapay zeka veya algoritma devreye girer
    // Yüklenen dosyaları okuyup en uygun programı çıkarır.
    await Future.delayed(const Duration(seconds: 3));

    isGenerating = false;
    isSuccess = true;
    notifyListeners();
  }
}