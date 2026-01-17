import '../local/app_database.dart';
import '../models/announcement_source.dart';
import '../models/announcement_item.dart';
import '../../services/api_service.dart';

class AnnouncementRepository {
  final AppDatabase _database;
  final ApiService _apiService;

  AnnouncementRepository(this._database, this._apiService);

  Future<List<AnnouncementSource>> getSources() {
    return _database.announcementDao.getAllSources();
  }

  Future<void> addSource(AnnouncementSource source) {
    return _database.announcementDao.insertSource(source);
  }

  Future<void> removeSource(AnnouncementSource source) {
    return _database.announcementDao.deleteSource(source);
  }

  Future<List<AnnouncementItem>> fetchAnnouncementsFromSource(AnnouncementSource source) async {
    final rawData = await _apiService.getAnnouncements(source.siteKey, source.categoryId);

    return rawData.map((json) {
      String link = json['Link'] ?? "";
      if (link.isEmpty && json['Route'] != null) {
        link = "https://iuc.edu.tr/tr/duyuru/${json['Route']}";
      }

      return AnnouncementItem(
        title: json['Header'] ?? "Başlıksız Duyuru",
        date: json['Date'] ?? "",
        url: link,
        sourceName: source.name,
      );
    }).toList();
  }

  // Arkaplan servisi için: Yeni duyuru var mı kontrolü
  Future<AnnouncementItem?> checkForNewAnnouncement(AnnouncementSource source) async {
    final rawData = await _apiService.getAnnouncements(source.siteKey, source.categoryId);

    if (rawData.isNotEmpty) {
      final latest = rawData.first;
      final latestId = latest['EID'] ?? latest['Header'];

      // Eğer veritabanındaki son ID ile API'den gelen son ID farklıysa yeni duyuru var demektir
      if (source.lastAnnouncementId != latestId) {

        await _database.updateSourceStatusSafe(
            source.id!,
            latestId,
            DateTime.now().toIso8601String()
        );

        return AnnouncementItem(
            title: latest['Header'],
            date: latest['Date'],
            url: latest['Link'] ?? "",
            sourceName: source.name
        );
      }
    }

    // Sadece kontrol zamanını güncelle
    await _database.updateSourceStatusSafe(
        source.id!,
        source.lastAnnouncementId ?? "",
        DateTime.now().toIso8601String()
    );

    return null;
  }
}