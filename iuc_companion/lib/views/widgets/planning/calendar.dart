import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/course_planning_viewmodel.dart';
import '../../../data/models/planning_types.dart';
import '../../../viewmodels/theme_viewmodel.dart';

class PlanningCalendar extends StatelessWidget {
  final double bottomPadding;

  const PlanningCalendar({super.key, required this.bottomPadding});


  //FIXME: pixel overflow hatası veriyor.
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CoursePlanningViewModel>(context);
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
          child: _buildDayColumn(context, vm, days[index]),
        );
      },
    );
  }

  Widget _buildDayColumn(
      BuildContext context, CoursePlanningViewModel vm, String day) {
    final slots = vm.getLayoutForDay(day);
    const double hourHeight = 80.0;
    const double pixelsPerMinute = hourHeight / 60.0;
    const int startHour = 8;
    const int endHour = 21;
    const int totalMinutes = (endHour - startHour) * 60;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
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
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPadding + 20),
            child: SizedBox(
              height: totalMinutes * pixelsPerMinute,
              child: Stack(
                children: [
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
                    final top =
                        (slot.startMinute - (startHour * 60)) * pixelsPerMinute;
                    final height = slot.duration * pixelsPerMinute;

                    return Positioned(
                      top: top + 1,
                      height: height - 2,
                      left: 55 + (slot.layoutLeft * 280),
                      width: (slot.layoutWidth * 270),
                      child: _buildCourseBlock(context, vm, slot, height - 2),
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

  Widget _buildCourseBlock(BuildContext context, CoursePlanningViewModel vm,
      VisualTimeSlot slot, double availableHeight) {
    final offering = slot.source;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = theme.extension<SemanticColors>();

    Color baseColor;
    switch (offering.status) {
      case CourseStatus.failedMustAttend:
      case CourseStatus.failedCanSkipAttendance:
        baseColor = semantics?.warning ?? colorScheme.error;
        break;
      case CourseStatus.conditional:
        baseColor = Colors.orange;
        break;
      case CourseStatus.passed:
        baseColor = semantics?.success ?? Colors.green;
        break;
      case CourseStatus.mandatoryNew:
        baseColor = colorScheme.primary;
        break;
      case CourseStatus.electiveNew:
        baseColor = colorScheme.tertiary;
        break;
      default:
        baseColor = colorScheme.outline;
    }

    final isSelected = offering.isSelected;

    // Arkapaln ve Yazı renkleri
    final Color bgColor = isSelected ? baseColor : baseColor.withOpacity(0.15);
    Color textColor;
    if (isSelected) {
      textColor =
      ThemeData.estimateBrightnessForColor(baseColor) == Brightness.dark
          ? Colors.white
          : Colors.black;
    } else {
      textColor = colorScheme.onSurface;
    }

    BoxBorder? border;
    if (isSelected) {
      if (offering.hasConflict) {
        border = Border.all(color: colorScheme.error, width: 2);
      } else {
        border = null;
      }
    } else {
      border = Border.all(color: baseColor.withOpacity(0.5), width: 1);
    }

    return GestureDetector(
      onTap: () => vm.toggleCourseSelection(offering),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (!isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: baseColor),
              ),

            Positioned.fill(
              left: isSelected ? 8 : 12,
              top: 6,
              right: 8,
              bottom: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool showDetails = constraints.maxHeight > 60;

                  return Column(
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
                        maxLines: showDetails ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showDetails) ...[
                        const SizedBox(height: 2),
                        Text(
                          offering.course.code,
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            if (offering.hasConflict && offering.isSelected)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high,
                      color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}