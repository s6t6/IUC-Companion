import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transcript_viewmodel.dart';
import '../data/models/course.dart';
import 'widgets/grade_dropdown.dart';

class TranscriptView extends StatelessWidget {
  const TranscriptView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notlarımı Düzenle"),
      ),
      body: Selector<TranscriptViewModel, bool>(
        selector: (_, vm) => vm.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final vm = Provider.of<TranscriptViewModel>(context, listen: false);

          if (vm.errorMessage != null) {
            return Center(
                child: Text(vm.errorMessage!,
                    style: TextStyle(color: colorScheme.error)));
          }

          return Selector<TranscriptViewModel, List<String>>(
            selector: (_, vm) => vm.sortedSemesters,
            shouldRebuild: (prev, next) => prev != next,
            builder: (context, semesters, _) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  final courses = vm.coursesBySemester[semester]!;
                  return _SemesterCard(semester: semester, courses: courses);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final String semester;
  final List<Course> courses;

  const _SemesterCard({required this.semester, required this.courses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final vm = Provider.of<TranscriptViewModel>(context, listen: false);
    final totals = vm.getSemesterTotals(semester);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      elevation: 0,
      color: theme.cardColor,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          semester,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        subtitle: Text(
          "${totals.credit.toStringAsFixed(0)} Kredi • ${totals.ects.toStringAsFixed(0)} AKTS",
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        children: courses.map((course) {
          return _CourseRow(course: course);
        }).toList(),
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;

  const _CourseRow({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRemoved = course.isRemoved;

    return Selector<TranscriptViewModel, String?>(
      selector: (_, vm) => vm.savedGrades[course.code],
      builder: (context, currentGrade, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isRemoved ? theme.disabledColor : null,
                          decoration: isRemoved ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        course.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isRemoved ? theme.disabledColor : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${course.credit} Kredi / ${course.ects} AKTS",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: GradeDropdown(
                    value: currentGrade,
                    items: context.read<TranscriptViewModel>().letterGrades,
                    onChanged: (val) {
                      context.read<TranscriptViewModel>().saveGrade(course.code, val);
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}