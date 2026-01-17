import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../viewmodels/announcement_viewmodel.dart';
import '../../announcement_list_view.dart';

class RecentAnnouncementsList extends StatelessWidget {
  const RecentAnnouncementsList({super.key});

  @override
  Widget build(BuildContext context) {
    final announcementViewModel = Provider.of<AnnouncementViewModel>(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Son Duyurular", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementListView()));
              },
              child: const Text("Tümünü Gör"),
            )
          ],
        ),
        _buildList(context, announcementViewModel),
      ],
    );
  }

  Widget _buildList(BuildContext context, AnnouncementViewModel vm) {
    if (vm.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recentItems = vm.combinedLatestAnnouncements;

    if (recentItems.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 12),
              Text("Şimdilik yeni duyuru yok."),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentItems.map((record) {
        final item = record.item;
        final sourceName = record.sourceName;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _launchUrl(item.url),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sourceName.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              letterSpacing: 0.5
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vm.getFormattedDate(item.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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