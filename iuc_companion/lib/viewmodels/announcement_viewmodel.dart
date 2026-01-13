import 'package:flutter/material.dart';
import '../data/repositories/announcement_repository.dart';
import '../data/models/announcement_source.dart';
import '../data/models/announcement_item.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementRepository _repository;

  List<AnnouncementSource> _sources = [];
  Map<String, List<AnnouncementItem>> _announcementsBySource = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<AnnouncementSource> get sources => _sources;
  Map<String, List<AnnouncementItem>> get announcementsBySource => _announcementsBySource;
  bool get isLoading => _isLoading;

  AnnouncementViewModel(this._repository) {
    _init();
  }

  Future<void> _init() async {
    await loadSources();
    // Eğer hiç kaynak yoksa varsayılanı ekle
    if (_sources.isEmpty) {
      await addSource("Rektörlük", "8FF2191E5F0343B5AA2F9BF774F93F5A", 1);
    }
    fetchAllAnnouncements();
  }

  Future<void> loadSources() async {
    _sources = await _repository.getSources();
    notifyListeners();
  }

  Future<void> addSource(String name, String siteKey, int categoryId) async {
    final newSource = AnnouncementSource(
      name: name,
      siteKey: siteKey.trim(),
      categoryId: categoryId,
    );
    await _repository.addSource(newSource);
    await loadSources();
    fetchAllAnnouncements();
  }

  Future<void> removeSource(AnnouncementSource source) async {
    await _repository.removeSource(source);
    _announcementsBySource.remove(source.name);
    await loadSources();
  }

  Future<void> fetchAllAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    _announcementsBySource = {};

    for (var source in _sources) {
      try {
        final items = await _repository.fetchAnnouncementsFromSource(source);
        _announcementsBySource[source.name] = items;
      } catch (e) {
        print("Hata (${source.name}): $e");
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}