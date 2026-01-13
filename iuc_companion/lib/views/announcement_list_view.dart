import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/announcement_viewmodel.dart';
import 'announcement_settings_view.dart';

class AnnouncementListView extends StatelessWidget {
  const AnnouncementListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AnnouncementViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Duyurular"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementSettingsView()));
            },
          )
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: vm.sources.map((source) {
          final items = vm.announcementsBySource[source.name] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kaynak Başlığı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.primaryContainer,
                  child: Text(
                    source.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer
                    ),
                  ),
                ),

                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Duyuru bulunamadı."),
                  ),

                // Duyuru Listesi (İlk 5 tanesi)
                ...items.take(5).map((item) => ListTile(
                  title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.date.split('T')[0]),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _launchUrl(item.url),
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Link açılamadı: $url';
    }
  }
}