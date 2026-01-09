import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/course.dart';
import '../data/models/schedule_item.dart';
import '../data/repositories/university_repository.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import 'course_detail_view.dart';

class CalendarCourseDetailView extends StatelessWidget {
  final Course course;
  final List<ScheduleItem> scheduleItems;
  final Color color;

  const CalendarCourseDetailView({
    super.key,
    required this.course,
    required this.scheduleItems,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final uniRepo = Provider.of<UniversityRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(course.code),
        backgroundColor: color.withOpacity(0.1),
      ),
      body: Column(
        children: [
          // 1. Üst Bilgi Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text("${course.credit} Kredi")),
                    const SizedBox(width: 8),
                    Chip(label: Text("${course.ects} AKTS")),
                  ],
                ),
              ],
            ),
          ),

          // 2. Detay Sayfasına Yönlendirme Butonu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Ders Detay Sayfasına Yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => CourseDetailViewModel(uniRepo),
                        child: CourseDetailView(courseSummary: course),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  side: BorderSide(color: theme.dividerColor),
                ),
                icon: const Icon(Icons.info_outline),
                label: const Text("Ders İçeriği ve Detaylarını Gör"),
              ),
            ),
          ),

          const Divider(height: 1),

          // 3. Program Listesi Başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Haftalık Program",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // 4. Program Listesi
          Expanded(
            child: scheduleItems.isEmpty
                ? const Center(child: Text("Bu dersin program bilgisi bulunamadı."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scheduleItems.length,
              itemBuilder: (context, index) {
                final item = scheduleItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.5)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.access_time_filled, color: color, size: 20),
                    ),
                    title: Text(
                      "${item.day} ${item.time}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(item.location.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14),
                                const SizedBox(width: 4),
                                Text(item.location),
                              ],
                            ),
                          ),
                        if(item.instructor.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(item.instructor, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}