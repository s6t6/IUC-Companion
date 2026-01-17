import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simulation_viewmodel.dart';
import '../data/models/course.dart';
import 'widgets/grade_dropdown.dart';
class SimulationView extends StatelessWidget {
  const SimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SimulationViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("GPA Simülasyonu"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onSurface),
            tooltip: "Sıfırla",
            onPressed: () {
              viewModel.resetSimulation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Simülasyon sıfırlandı.")),
              );
            },
          )
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context, viewModel),
            const SizedBox(height: 24),
            _buildCategoryCard(
              context,
              viewModel,
              title: "Tamamlanan Dersler",
              courses: viewModel.passedCourses,
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
            ),
            _buildCategoryCard(
              context,
              viewModel,
              title: "Tekrar Edilen Dersler",
              courses: viewModel.retakeCourses,
              icon: Icons.refresh,
              iconColor: Colors.orange,
            ),
            _buildCategoryCard(
              context,
              viewModel,
              title: "İlk Kez Alınan / Gelecek",
              courses: viewModel.futureCourses,
              icon: Icons.arrow_forward,
              iconColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SimulationViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "SİMÜLE EDİLEN ORTALAMA",
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vm.calculatedGPA.toStringAsFixed(2),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getGpaColor(vm.calculatedGPA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${vm.totalCredits} Kredi Hesaplanıyor",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (vm.calculatedGPA != vm.realGPA)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Gerçek Ortalamanız: ${vm.realGPA.toStringAsFixed(2)}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      SimulationViewModel vm, {
        required String title,
        required List<Course> courses,
        required IconData icon,
        required Color iconColor,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (courses.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: theme.cardColor,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, color: iconColor),
        title: Text(
          "$title (${courses.length})",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        children: courses.map((course) {
          return _buildCourseRow(context, vm, course);
        }).toList(),
      ),
    );
  }

  Widget _buildCourseRow(
      BuildContext context, SimulationViewModel vm, Course course) {
    final currentGrade = vm.currentGrades[course.code];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  ),
                ),
                Text(
                  course.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${course.credit} Kredi",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: GradeDropdown(
              value: currentGrade,
              items: vm.letterGrades,
              onChanged: (val) {
                vm.updateGrade(course.code, val);
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getGpaColor(double gpa) {
    if (gpa >= 3.5) return Colors.green;
    if (gpa >= 3.0) return Colors.blue;
    if (gpa >= 2.0) return Colors.orange;
    return Colors.red;
  }
}