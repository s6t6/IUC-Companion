import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/academic_calendar_viewmodel.dart';
import '../data/models/course.dart';

class CourseSelectionView extends StatefulWidget {
  const CourseSelectionView({super.key});

  @override
  State<CourseSelectionView> createState() => _CourseSelectionViewState();
}

class _CourseSelectionViewState extends State<CourseSelectionView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AcademicCalendarViewModel>(context);
    final theme = Theme.of(context);

    final sortedSemesters = vm.sortedSemesters;
    final groupedCourses = vm.groupedAvailableCourses;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: "Ders Ara (Kod veya İsim)...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.hintColor),
            prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          ),
          onChanged: (val) => vm.updateSearchQuery(val),
        ),
        actions: [
          if (vm.searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                vm.updateSearchQuery("");
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: sortedSemesters.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedSemesters.length,
        itemBuilder: (context, index) {
          final semester = sortedSemesters[index];
          final courses = groupedCourses[semester] ?? [];

          return _buildSemesterGroup(context, vm, semester, courses);
        },
      ),
    );
  }

  Widget _buildSemesterGroup(BuildContext context, AcademicCalendarViewModel vm,
      String semester, List<Course> courses) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedCount = courses.where((c) => vm.isCourseActive(c.code)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${courses.length}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          semester,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: selectedCount > 0
            ? Text("$selectedCount ders seçili", style: TextStyle(color: colorScheme.primary, fontSize: 12))
            : null,
        children: courses.map((course) => _buildCourseItem(context, vm, course)).toList(),
      ),
    );
  }

  Widget _buildCourseItem(
      BuildContext context, AcademicCalendarViewModel vm, Course course) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = vm.isCourseActive(course.code);
    final courseColor = vm.getCourseColor(course.code);

    return InkWell(
      onTap: () => vm.toggleCourse(course),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          color: isActive ? courseColor.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? courseColor : Colors.transparent,
                border: Border.all(
                  color: isActive ? courseColor : theme.disabledColor,
                  width: 2,
                ),
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTag(context, course.code, isActive ? courseColor : theme.disabledColor),
                      const SizedBox(width: 8),
                      Text(
                        "${course.credit} Kredi / ${course.ects} AKTS",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.disabledColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "Ders bulunamadı.",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}