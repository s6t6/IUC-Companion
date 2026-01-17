import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../../../data/models/schedule_item.dart';
import '../../calendar_course_detail_view.dart';

class TodayTimeline extends StatefulWidget {
  const TodayTimeline({super.key});

  @override
  State<TodayTimeline> createState() => _TodayTimelineState();
}

class _TodayTimelineState extends State<TodayTimeline> {
  final ScrollController _scrollController = ScrollController();

  final double _itemWidth = 140.0;
  final double _separatorWidth = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  @override
  void didUpdateWidget(covariant TodayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  void _scrollToCurrent() {
    if (!mounted || !_scrollController.hasClients) return;

    final homeVM = Provider.of<HomeViewModel>(context, listen: false);
    final classes = homeVM.todaysClasses;
    if (classes.isEmpty) return;

    int targetIndex = 0;

    for (int i = 0; i < classes.length; i++) {
      final status = _getClassStatus(classes[i]);
      if (status != _ClassStatus.past) {
        targetIndex = i;
        break;
      }
    }

    final double offset = targetIndex * (_itemWidth + _separatorWidth);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final theme = Theme.of(context);

    if (!homeVM.hasRawSchedule || !homeVM.hasActiveCourses) {
      return const SizedBox.shrink();
    }

    final todaysClasses = homeVM.todaysClasses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Text("Günün Programı", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (todaysClasses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.weekend, color: theme.hintColor),
                const SizedBox(width: 12),
                Text("Bugün dersiniz yok.", style: TextStyle(color: theme.hintColor)),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: todaysClasses.length,
              separatorBuilder: (ctx, i) => SizedBox(width: _separatorWidth),
              itemBuilder: (context, index) {
                final item = todaysClasses[index];
                final status = _getClassStatus(item);

                return _buildClassCard(context, item, status, homeVM);
              },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, ScheduleItem item, _ClassStatus status, HomeViewModel vm) {
    final theme = Theme.of(context);
    final timeParts = item.time.split('-');
    final start = timeParts.isNotEmpty ? timeParts[0] : "";

    Color backgroundColor;
    Color borderColor;
    double elevation;
    Color textColor;

    switch (status) {
      case _ClassStatus.past:
        backgroundColor = theme.colorScheme.surfaceContainer.withValues(alpha: 0.5);
        borderColor = Colors.transparent;
        elevation = 0;
        textColor = theme.disabledColor;
        break;
      case _ClassStatus.ongoing:
        backgroundColor = theme.colorScheme.primaryContainer;
        borderColor = theme.colorScheme.primary;
        elevation = 2;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case _ClassStatus.upcoming:
        backgroundColor = theme.colorScheme.surfaceContainerLow;
        borderColor = theme.dividerColor.withValues(alpha: 0.1);
        elevation = 0;
        textColor = theme.colorScheme.onSurface;
        break;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(context, item, vm),
      child: Container(
        width: _itemWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: borderColor,
              width: status == _ClassStatus.ongoing ? 2 : 1
          ),
          boxShadow: status == _ClassStatus.ongoing ? [
            BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == _ClassStatus.past
                        ? theme.disabledColor.withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                      start,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == _ClassStatus.past
                              ? theme.disabledColor
                              : theme.colorScheme.primary
                      )
                  ),
                ),
                if (status == _ClassStatus.ongoing)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
              ],
            ),
            const Spacer(),
            Text(
              item.courseName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                  color: textColor
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: status == _ClassStatus.past ? theme.disabledColor : theme.hintColor
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ScheduleItem item, HomeViewModel vm) {
    if (item.courseCode == null) return;

    final course = vm.getCourseByCode(item.courseCode!);
    final schedule = vm.getScheduleForCode(item.courseCode!);

    if (course != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalendarCourseDetailView(
            course: course,
            scheduleItems: schedule,
            color: _getColorForCourse(course.code),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ders detayları bulunamadı.")),
      );
    }
  }

  Color _getColorForCourse(String code) {
    final colors = [
      Colors.red, Colors.blue, Colors.green,
      Colors.orange, Colors.purple, Colors.teal,
      Colors.indigo, Colors.pink
    ];
    return colors[code.hashCode.abs() % colors.length];
  }

  _ClassStatus _getClassStatus(ScheduleItem item) {
    try {
      final now = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;

      final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
      final matches = regex.allMatches(item.time).toList();

      if (matches.length >= 2) {
        final startH = int.parse(matches[0].group(1)!);
        final startM = int.parse(matches[0].group(2)!);
        final endH = int.parse(matches[1].group(1)!);
        final endM = int.parse(matches[1].group(2)!);

        final startTotal = startH * 60 + startM;
        final endTotal = endH * 60 + endM;

        if (nowMin < startTotal) return _ClassStatus.upcoming;
        if (nowMin >= startTotal && nowMin < endTotal) return _ClassStatus.ongoing;
        return _ClassStatus.past;
      }
    } catch (_) {}
    return _ClassStatus.upcoming;
  }
}

enum _ClassStatus {
  past,
  ongoing,
  upcoming
}