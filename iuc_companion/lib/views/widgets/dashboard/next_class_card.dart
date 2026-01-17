import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../viewmodels/schedule_viewmodel.dart';
import '../../academic_calendar_view.dart';

class NextClassCard extends StatelessWidget {
  const NextClassCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final scheduleVM = Provider.of<ScheduleViewModel>(context);
    final nextClass = homeVM.nextClass;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!homeVM.hasRawSchedule) {
      return _buildCard(
        context,
        color: colorScheme.surfaceContainer,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_file_outlined, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "Ders Programı Eksik",
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Derslerinizi takip etmek için programınızı yükleyin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );

                  if (result != null && result.files.single.path != null) {
                    bool success = await scheduleVM.processAndSaveSchedule(File(result.files.single.path!));
                    if (success && context.mounted) {
                      Provider.of<HomeViewModel>(context, listen: false).loadCourses();
                    }
                  }
                },
                child: const Text("Program Yükle"),
              ),
            )
          ],
        ),
      );
    }

    if (!homeVM.hasActiveCourses) {
      return _buildCard(
        context,
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.playlist_remove, color: colorScheme.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              "Aktif Ders Seçilmedi",
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Takvimi görmek için Akademik Takvim'den bu dönem aldığınız dersleri seçin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AcademicCalendarView()),
                  ).then((_) {
                    homeVM.loadCourses();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error),
                  foregroundColor: colorScheme.error,
                ),
                child: const Text("Dersleri Seç"),
              ),
            )
          ],
        ),
      );
    }

    if (nextClass == null) {
      final bool isFreeDay = homeVM.isDayEmpty;
      final String title = isFreeDay ? "Bugün Boşsunuz!" : "Bugünlük bu kadar!";
      final String subtitle = isFreeDay
          ? "Bugün için planlanmış bir dersiniz yok. Tadını çıkarın."
          : "Bugünkü tüm derslerinizi tamamladınız. İyi istirahatler.";

      final IconData icon = isFreeDay ? Icons.weekend : Icons.nightlight_round;

      return _buildCard(
        context,
        gradient: LinearGradient(
          colors: [colorScheme.tertiary, colorScheme.tertiary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final timeStatus = homeVM.nextClassStatusText;
    final statusColor = homeVM.nextClassStatusColor;
    final endTimeStr = homeVM.nextClassEndTimeStr;

    return _buildCard(
      context,
      gradient: LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                            nextClass.time,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          timeStatus,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w800)
                      ),
                      if (timeStatus == "Şu an İşleniyor")
                        Text(
                            endTimeStr,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)
                        )
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                nextClass.courseName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: _buildDetailChip(Icons.location_on, nextClass.location.isEmpty ? "Belirsiz" : nextClass.location),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: _buildDetailChip(Icons.person, nextClass.instructor),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {Color? color, Gradient? gradient, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}