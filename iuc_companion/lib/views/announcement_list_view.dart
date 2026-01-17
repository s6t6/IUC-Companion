import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../data/models/announcement_item.dart';
import 'announcement_settings_view.dart';

class AnnouncementListView extends StatelessWidget {
  const AnnouncementListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AnnouncementViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Duyurular"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Kaynakları Yönet",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementSettingsView())
              );
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.fetchAllAnnouncements,
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vm.sources.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.sources.length,
          itemBuilder: (context, index) {
            final source = vm.sources[index];
            final items = vm.getRecentAnnouncements(source.name);
            return _buildSourceCard(context, source.name, items, vm);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 80, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "Henüz hiç duyuru kaynağı yok.",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementSettingsView())
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Kaynak Ekle"),
          )
        ],
      ),
    );
  }

  Widget _buildSourceCard(
      BuildContext context,
      String sourceName,
      List<AnnouncementItem> items,
      AnnouncementViewModel vm
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    sourceName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sourceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.rss_feed, size: 18, color: colorScheme.primary.withValues(alpha: 0.6)),
              ],
            ),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Güncel duyuru yok.",
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            ),

          // List Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.dividerColor.withValues(alpha: 0.2)
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              return InkWell(
                onTap: () => _launchUrl(item.url),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: theme.hintColor),
                                const SizedBox(width: 4),
                                Text(
                                  vm.getFormattedDate(item.date),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right, size: 20, color: theme.disabledColor.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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