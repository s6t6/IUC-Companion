import 'package:flutter/material.dart';
import '../../../data/models/planning_types.dart';

class SimpleWeeklyCalendar extends StatelessWidget {
  final Function(String day) onGetLayout;
  final Function(String courseCode) onGetColor;
  final Function(CourseOffering offering) onCourseTap;
  final double bottomPadding;

  const SimpleWeeklyCalendar({
    super.key,
    required this.onGetLayout,
    required this.onGetColor,
    required this.onCourseTap,
    this.bottomPadding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];

    return PageView.builder(
      controller: PageController(viewportFraction: 0.95),
      itemCount: days.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: _buildDayColumn(context, days[index]),
        );
      },
    );
  }

  Widget _buildDayColumn(BuildContext context, String day) {
    final List<VisualTimeSlot> slots = onGetLayout(day);
    const double hourHeight = 80.0;
    const double pixelsPerMinute = hourHeight / 60.0;
    const int startHour = 8;
    const int endHour = 21;
    const int totalMinutes = (endHour - startHour) * 60;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Gün Başlığı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const Divider(height: 1),

        // Zaman Çizelgesi
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: totalMinutes * pixelsPerMinute,
              child: Stack(
                children: [
                  // Saat Çizgileri
                  for (int h = startHour; h <= endHour; h++)
                    Positioned(
                      top: (h - startHour) * 60 * pixelsPerMinute,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text("$h:00",
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outline,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: theme.dividerColor.withOpacity(0.3))),
                        ],
                      ),
                    ),

                  // Ders Blokları
                  ...slots.map((slot) {
                    final top = (slot.startMinute - (startHour * 60)) * pixelsPerMinute;
                    final height = slot.duration * pixelsPerMinute;

                    final safeTop = top < 0 ? 0.0 : top;

                    return Positioned(
                      top: safeTop + 1,
                      height: height - 2,
                      left: 55 + (slot.layoutLeft * 280),
                      width: (slot.layoutWidth * 270),
                      child: _buildCourseBlock(context, slot),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseBlock(BuildContext context, VisualTimeSlot slot) {
    final offering = slot.source;
    final theme = Theme.of(context);

    // Rengi ViewModel'den al
    final baseColor = onGetColor(offering.course.code);

    // Kontrast yazı rengi hesapla
    final textColor = ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: () => onCourseTap(offering),
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offering.course.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              "${offering.course.code} • ${slot.source.schedule.first.location}",
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}