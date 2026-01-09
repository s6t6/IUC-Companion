import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/academic_calendar_viewmodel.dart';
import '../data/models/course.dart';
import '../utils/semester_helper.dart';

class CourseSelectionView extends StatefulWidget {
  const CourseSelectionView({super.key});

  @override
  State<CourseSelectionView> createState() => _CourseSelectionViewState();
}

class _CourseSelectionViewState extends State<CourseSelectionView> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AcademicCalendarViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredCourses = vm.availableCourses.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    final Map<String, List<Course>> grouped = {};
    for (var c in filteredCourses) {
      final sem = c.semester.isEmpty ? "Diğer" : c.semester;
      if (!grouped.containsKey(sem)) grouped[sem] = [];
      grouped[sem]!.add(c);
    }

    final sortedSemesters = SemesterHelper.sortSemesters(grouped.keys);

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
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = "");
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: filteredCourses.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedSemesters.length,
        itemBuilder: (context, index) {
          final semester = sortedSemesters[index];
          final courses = grouped[semester]!;
          courses.sort((a, b) => a.code.compareTo(b.code));

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
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
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
            top: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
          ),
          color: isActive ? courseColor.withOpacity(0.05) : null,
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
        color: color.withOpacity(0.1),
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
          Icon(Icons.search_off, size: 64, color: theme.disabledColor.withOpacity(0.3)),
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