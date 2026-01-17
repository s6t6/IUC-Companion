import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../views/widgets/profile_selection_dialog.dart';
import 'widgets/dashboard/next_class_card.dart';
import 'widgets/dashboard/academic_summary_card.dart';
import 'widgets/dashboard/today_timeline.dart';
import 'widgets/dashboard/quick_access_grid.dart';
import 'widgets/dashboard/recent_announcements_list.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String displayTitle = "Öğrenci";
    if (homeViewModel.activeProfileId != null && homeViewModel.savedProfiles.isNotEmpty) {
      try {
        final p = homeViewModel.savedProfiles.firstWhere((element) => element.id == homeViewModel.activeProfileId);
        displayTitle = p.profileName;
      } catch (_) {
        displayTitle = homeViewModel.departmentName;
      }
    } else if (homeViewModel.departmentName.isNotEmpty) {
      displayTitle = homeViewModel.departmentName;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Merhaba,", style: theme.textTheme.bodyMedium),
            Text(
              displayTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, size: 28, color: colorScheme.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProfileSelectionDialog(),
              );
            },
          )
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NextClassCard(),
            SizedBox(height: 20),
            AcademicSummaryCard(),
            SizedBox(height: 24),
            TodayTimeline(),
            QuickAccessGrid(),
            SizedBox(height: 32),
            RecentAnnouncementsList(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}