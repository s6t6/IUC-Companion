import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import '../data/models/course.dart';
import '../data/repositories/university_repository.dart';
import 'course_detail_view.dart';

class CurriculumView extends StatefulWidget {
  const CurriculumView({super.key});

  @override
  State<CurriculumView> createState() => _CurriculumViewState();
}

class _CurriculumViewState extends State<CurriculumView> {
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: "Ders ara...",
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.hintColor,
            ),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        )
            : const Text("Müfredat"),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onSurface),
            onPressed: viewModel.loadCourses,
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSearching
          ? _buildSearchResults(viewModel)
          : _buildSemesterList(viewModel),
    );
  }

  Widget _buildSearchResults(HomeViewModel viewModel) {
    final allCourses = [
      ...viewModel.coursesBySemester.values.expand((e) => e),
      ...viewModel.removedCourses
    ].where((course) =>
    course.name.toLowerCase().contains(_searchQuery) ||
        course.code.toLowerCase().contains(_searchQuery))
        .toList();

    if (allCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              "Sonuç bulunamadı",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allCourses.length,
      itemBuilder: (context, index) => _buildCourseItem(context, allCourses[index]),
    );
  }

  Widget _buildSemesterList(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (viewModel.errorMessage != null) {
      return Center(
          child: Text(viewModel.errorMessage!,
              style: TextStyle(color: colorScheme.error)));
    }

    final semesters = viewModel.sortedSemesters;
    final hasRemoved = viewModel.removedCourses.isNotEmpty;
    final itemCount = semesters.length + (hasRemoved ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < semesters.length) {
          final semester = semesters[index];
          final courses = viewModel.coursesBySemester[semester]!;
          return _buildSemesterGroup(context, semester, courses);
        }
        else {
          return _buildSemesterGroup(
              context,
              "Kaldırılan Dersler",
              viewModel.removedCourses,
              isRemovedSection: true
          );
        }
      },
    );
  }

  Widget _buildSemesterGroup(BuildContext context, String title, List<Course> courses, {bool isRemovedSection = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double totalEcts = courses.fold(0, (sum, item) => sum + item.ects);
    final double totalCredit = courses.fold(0, (sum, item) => sum + item.credit);

    final headerColor = isRemovedSection ? colorScheme.error : colorScheme.primary;
    final containerColor = isRemovedSection ? colorScheme.errorContainer.withOpacity(0.3) : colorScheme.surfaceContainer;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isRemovedSection ? colorScheme.error.withOpacity(0.2) : theme.dividerColor.withOpacity(0.5)
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: !isRemovedSection,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRemovedSection ? colorScheme.error : colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            "${courses.length}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRemovedSection ? colorScheme.onError : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isRemovedSection ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
        subtitle: isRemovedSection
            ? const Text("Müfredattan çıkarılmış dersler")
            : Text(
          "${totalCredit.toStringAsFixed(0)} Kredi • ${totalEcts.toStringAsFixed(0)} AKTS",
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        children: courses.map((course) => _buildCourseItem(context, course)).toList(),
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          course.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: null,
            color: course.isRemoved ? theme.disabledColor : null,
          ),
        ),
        subtitle: Row(
          children: [
            Hero(
              tag: 'course_code_${course.code}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  course.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: course.isRemoved ? theme.disabledColor : colorScheme.primary,
                  ),
                ),
              ),
            ),
            Text(
              " • ${course.credit} Kr • ${course.ects} AKTS",
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                  fontSize: 11
              ),
            ),
          ],
        ),
        trailing: course.isRemoved
            ? Icon(Icons.archive_outlined, size: 18, color: theme.disabledColor)
            : course.isMandatory
            ? Tooltip(message: "Zorunlu", child: Icon(Icons.lock_outline, size: 18, color: colorScheme.outline))
            : const Tooltip(message: "Seçmeli", child: Icon(Icons.check_circle_outline, size: 18, color: Colors.green)),
        onTap: () {
          final repository = context.read<UniversityRepository>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (routeContext) => ChangeNotifierProvider(
                create: (_) => CourseDetailViewModel(repository),
                child: CourseDetailView(courseSummary: course),
              ),
            ),
          );
        },
      ),
    );
  }
}