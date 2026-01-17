import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../viewmodels/test_schedule_linking_viewmodel.dart';
import '../data/models/schedule_item.dart';

class TestScheduleLinkingView extends StatelessWidget {
  const TestScheduleLinkingView({super.key});

  @override
  Widget build(BuildContext context) {
    final uniRepo = Provider.of<UniversityRepository>(context, listen: false);
    final schedRepo = Provider.of<ScheduleRepository>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (_) => TestScheduleLinkingViewModel(uniRepo, schedRepo),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Test: Eşleştirme Kontrolü"),
        ),
        body: Consumer<TestScheduleLinkingViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              return Center(
                  child: Text(vm.errorMessage!,
                      style: TextStyle(color: colorScheme.error)));
            }

            if (vm.matchedCourses.isEmpty && vm.unmatchedItems.isEmpty) {
              return Center(
                  child: Text("Program boş.", style: theme.textTheme.bodyLarge));
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...vm.matchedCourses.entries.map((entry) {
                  final course = entry.key;
                  final items = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.link, color: Colors.green),
                      title: Text(course.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "${course.code} • ${items.length} ders saati",
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                      children: items
                          .map((item) => _buildScheduleItemTile(context, item))
                          .toList(),
                    ),
                  );
                }).toList(),

                if (vm.unmatchedItems.isNotEmpty)
                  Card(
                    color: colorScheme.errorContainer,
                    margin: const EdgeInsets.only(top: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: Icon(Icons.link_off, color: colorScheme.error),
                      title: Text("Eşleşmeyenler (No Match)",
                          style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text("${vm.unmatchedItems.length} öge",
                          style: TextStyle(
                              color: colorScheme.onErrorContainer)),
                      initiallyExpanded: true,
                      children: vm.unmatchedItems
                          .map((item) => _buildScheduleItemTile(context, item,
                          isError: true))
                          .toList(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleItemTile(BuildContext context, ScheduleItem item,
      {bool isError = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textColor = isError ? colorScheme.onErrorContainer : colorScheme.onSurface;
    final iconColor = isError ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text("PDF: ${item.courseName}",
          style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: textColor,
              fontWeight: FontWeight.w500)),
      subtitle: Text("${item.day} ${item.time} | ${item.instructor}",
          style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.8))),
      leading: Icon(Icons.access_time, size: 16, color: iconColor),
    );
  }
}