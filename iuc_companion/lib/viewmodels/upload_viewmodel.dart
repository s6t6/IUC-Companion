import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_model.dart';
import '../services/api_service.dart';

class UploadViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<FileModel> _uploadedFiles = [];
  bool _isLoading = false;

  List<FileModel> get uploadedFiles => _uploadedFiles;
  bool get isLoading => _isLoading;

  // Sayfa açılınca veritabanından eski dosyaları çek
  Future<void> fetchFiles(String userId) async {
    _isLoading = true;
    notifyListeners();
    _uploadedFiles = await _apiService.getUserFiles(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadFile(String userId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      _isLoading = true;
      notifyListeners();

      // Backend'e yükleme simülasyonu
      await Future.delayed(const Duration(seconds: 2));
      
      // Listeye ekle (Normalde backend'den gelen response ile eklenir)
      _uploadedFiles.insert(0, FileModel(
        id: DateTime.now().toString(),
        name: result.files.first.name,
        type: "UNKNOWN",
        uploadDate: DateTime.now(),
        url: "local_path",
      ));

      _isLoading = false;
      notifyListeners();
    }
  }
}