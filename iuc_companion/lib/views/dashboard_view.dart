import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/widgets/profile_selection_dialog.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../viewmodels/simulation_viewmodel.dart';
import '../data/models/schedule_item.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'course_planning_view.dart';
import 'test_schedule_linking_view.dart';
import 'academic_calendar_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {

    final homeViewModel = Provider.of<HomeViewModel>(context);
    final scheduleViewModel = Provider.of<ScheduleViewModel>(context);
    final simulationViewModel = Provider.of<SimulationViewModel>(context);

    final nextClass = homeViewModel.nextClass;

    // Helper
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String displayTitle = "Öğrenci";
    if (homeViewModel.activeProfileId != null && homeViewModel.savedProfiles.isNotEmpty) {
      try {
        final p = homeViewModel.savedProfiles.firstWhere((element) => element.id == homeViewModel.activeProfileId);
        displayTitle = p.profileName;
      } catch (_) {
        displayTitle = homeViewModel.departmentName;
      }
    } else if (homeViewModel.departmentName.isNotEmpty) {
      displayTitle = homeViewModel.departmentName;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Merhaba,", style: theme.textTheme.bodyMedium),
            Text(
              displayTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, size: 28, color: colorScheme.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ProfileSelectionDialog(),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sıradaki Ders Kartı
            _buildNextClassCard(context, homeViewModel, scheduleViewModel, nextClass),

            const SizedBox(height: 20),

            // Durum Kartları (Ortalama ve Kredi)
            Row(
              children: [
                Expanded(child: _buildStatusCard(
                    context,
                    icon: Icons.school,
                    label: "Ortalama",
                    value: simulationViewModel.isLoading
                        ? "..."
                        : simulationViewModel.realGPA.toStringAsFixed(2),
                    iconColor: Colors.orange
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusCard(
                    context,
                    icon: Icons.check_circle,
                    label: "Kredi",
                    value: simulationViewModel.isLoading
                        ? "..."
                        : "${simulationViewModel.realTotalCredits} Tamamlandı",
                    iconColor: Colors.blue
                )),
              ],
            ),

            const SizedBox(height: 24),
            Text("Hızlı Erişim", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Kısayollar
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
                        // Takvimden dönünce Dashboard'u güncelle (seçimler değişmiş olabilir)
                        homeViewModel.loadCourses();
                      });
                    }
                ),

                _buildShortcutChip(
                  context,
                  icon: Icons.developer_mode,
                  label: "Test: Eşleştirme",
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  iconColor: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TestScheduleLinkingView()),
                    );
                  },
                ),

                _buildShortcutChip(context, icon: Icons.restaurant, label: "Yemek Listesi"),
                _buildShortcutChip(context, icon: Icons.announcement, label: "Duyurular"),
              ],
            ),
          ],
        ),
      ),
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
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest.withOpacity(0.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label özelliği yakında eklenecek.")),
        );
      },
    );
  }

  Widget _buildNextClassCard(
      BuildContext context,
      HomeViewModel homeVM,
      ScheduleViewModel scheduleVM,
      ScheduleItem? nextClass
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Durum: Program Hiç Yüklenmemiş
    if (!homeVM.hasRawSchedule) {
      return _buildDashboardCard(
        context,
        color: colorScheme.surfaceContainer,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
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
                  bool success = await scheduleVM.pickAndUploadSchedule();
                  if (success && context.mounted) {
                    Provider.of<HomeViewModel>(context, listen: false).loadCourses();
                  }
                },
                child: const Text("Program Yükle"),
              ),
            )
          ],
        ),
      );
    }

    // 2. Durum: Program var ama bugün/şuan ders yok
    if (nextClass == null) {
      return _buildDashboardCard(
        context,
        gradient: LinearGradient(
          colors: [colorScheme.tertiary, colorScheme.tertiary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nightlight_round, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bugünlük bu kadar!",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "İyi istirahatler.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Durum: Sıradaki Ders Var
    String timeStatus = "Yaklaşıyor";
    Color statusColor = Colors.white.withOpacity(0.9);

    try {
      final now = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;

      final parts = nextClass.time.split('-')[0].replaceAll('.', ':').split(':');
      final startMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final diff = startMin - nowMin;

      if (diff <= 0) {
        timeStatus = "Şu an İşleniyor";
        statusColor = const Color(0xFF81C784);
      } else if (diff < 60) {
        timeStatus = "$diff dk sonra başlıyor";
        statusColor = const Color(0xFFFFB74D);
      } else {
        timeStatus = "Bugün ${nextClass.time}";
      }
    } catch (_) {}

    return _buildDashboardCard(
      context,
      gradient: LinearGradient(
        colors: [colorScheme.primary, colorScheme.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Stack(
        children: [
          // Dekoratif Arkaplan
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),

          // İçerik
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: Zaman ve Durum
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  Text(
                      timeStatus,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Ders İsmi
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

              // Alt Satır: Lokasyon ve Eğitmen
              Row(
                children: [
                  Flexible(
                    flex: 4,
                    child: _buildDetailChip(Icons.location_on, nextClass.location.isEmpty ? "Belirsiz" : nextClass.location),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: Colors.white.withOpacity(0.3)),
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

  Widget _buildDashboardCard(BuildContext context, {
    Color? color,
    Gradient? gradient,
    required Widget child
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
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

  Widget _buildStatusCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = theme.extension<SemanticColors>();

    final actualIconColor = label == "Ortalama"
        ? (semantics?.warning ?? iconColor)
        : (semantics?.info ?? iconColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: actualIconColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              )
          ),
        ],
      ),
    );
  }
}