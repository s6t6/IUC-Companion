import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../course_planning_view.dart';
import '../../academic_calendar_view.dart';
import '../../../viewmodels/home_viewmodel.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hızlı Erişim", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildShortcutChip(
              context,
              icon: Icons.edit_calendar,
              label: "Ders Planla",
              backgroundColor: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CoursePlanningView()),
                );
              },
            ),
            _buildShortcutChip(
                context,
                icon: Icons.calendar_today,
                label: "Akademik Takvim",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AcademicCalendarView()),
                  ).then((_) {
                    homeViewModel.loadCourses();
                  });
                }
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutChip(BuildContext context, {
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar: Icon(icon, size: 18, color: iconColor ?? colorScheme.primary),
      label: Text(
          label,
          style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500
          )
      ),
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label özelliği yakında eklenecek.")),
        );
      },
    );
  }
}