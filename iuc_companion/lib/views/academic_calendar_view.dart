import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/academic_calendar_viewmodel.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/local/app_database.dart';
import 'widgets/academic/simple_weekly_calendar.dart';
import 'course_selection_view.dart';
import 'calendar_course_detail_view.dart';

class AcademicCalendarView extends StatelessWidget {
  const AcademicCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final uniRepo = Provider.of<UniversityRepository>(context, listen: false);
    final schedRepo = Provider.of<ScheduleRepository>(context, listen: false);

    return Consumer<UniversityRepository>(
        builder: (context, uRepo, child) {
          return ChangeNotifierProvider(
            create: (ctx) => AcademicCalendarViewModel(
                uRepo,
                schedRepo,
                Provider.of<AppDatabase>(ctx, listen: false)
            ),
            child: const _AcademicCalendarContent(),
          );
        }
    );
  }
}

class _AcademicCalendarContent extends StatelessWidget {
  const _AcademicCalendarContent();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AcademicCalendarViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Akademik Takvim"),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.calendarOfferings.isEmpty
          ? _buildEmptyState(context)
          : SimpleWeeklyCalendar(
        onGetLayout: (day) => vm.getLayoutForDay(day),
        onGetColor: (code) => vm.getCourseColor(code),
        onCourseTap: (offering) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarCourseDetailView(
                course: offering.course,
                scheduleItems: offering.schedule,
                color: vm.getCourseColor(offering.course.code),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const CourseSelectionView(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.edit_calendar),
        label: const Text("Ders Düzenle"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          const Text("Takviminizde ders görünmüyor."),
          const SizedBox(height: 8),
          const Text("Aşağıdaki butonu kullanarak ders ekleyebilirsiniz."),
        ],
      ),
    );
  }
}