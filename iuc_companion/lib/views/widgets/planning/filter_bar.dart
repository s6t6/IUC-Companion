import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/course_planning_viewmodel.dart';
import '../../../data/models/planning_types.dart';
import '../../../viewmodels/theme_viewmodel.dart';

class PlanningFilterBar extends StatelessWidget {
  const PlanningFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CoursePlanningViewModel>(context);
    final theme = Theme.of(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(context, vm, CourseFilter.all, "Hepsi"),
          _buildChip(context, vm, CourseFilter.failed, "Kalınanlar"),
          _buildChip(context, vm, CourseFilter.conditional, "Şartlı"),
          _buildChip(context, vm, CourseFilter.current, "Bu Dönem"),
          _buildChip(context, vm, CourseFilter.other, "Diğerleri"),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, CoursePlanningViewModel vm,
      CourseFilter filter, String label) {
    final isSelected = vm.isFilterActive(filter);
    final count = vm.getFilterCount(filter);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = theme.extension<SemanticColors>();

    Color baseColor;
    switch (filter) {
      case CourseFilter.failed:
        baseColor = semantics?.warning ?? colorScheme.error;
        break;
      case CourseFilter.conditional:
        baseColor = Colors.orange;
        break;
      case CourseFilter.current:
        baseColor = colorScheme.primary;
        break;
      case CourseFilter.other:
        baseColor = colorScheme.tertiary;
        break;
      case CourseFilter.all:
      default:
        baseColor = colorScheme.outline;
        break;
    }

    final Color bgColor = isSelected ? baseColor : Colors.transparent;
    final Color borderColor = isSelected ? Colors.transparent : baseColor.withValues(alpha: 0.5);
    final Color textColor = isSelected
        ? (ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark
        ? Colors.white
        : Colors.black)
        : (filter == CourseFilter.all ? colorScheme.onSurface : baseColor);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => vm.toggleFilter(filter),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: Center(
              child: Text(
                "$label ($count)",
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}