import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/course_planning_viewmodel.dart';
import '../../../data/models/planning_types.dart';

class PlanningStatusHUD extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final double collapsedHeight;
  final double expandedHeight;

  const PlanningStatusHUD({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.collapsedHeight,
    required this.expandedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CoursePlanningViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color stateColor;
    String headerText;
    IconData statusIcon;

    if (vm.conflictMessages.isNotEmpty) {
      stateColor = colorScheme.error;
      headerText = "ÇAKIŞMA MEVCUT";
      statusIcon = Icons.error_outline;
    } else if (vm.isLimitExceeded) {
      stateColor = colorScheme.tertiary;
      headerText = "LİMİT AŞIMI";
      statusIcon = Icons.warning_amber_rounded;
    } else if (vm.studentStatus != StudentStatus.successful) {
      stateColor = colorScheme.tertiary;
      headerText = vm.studentStatus == StudentStatus.probation
          ? "SINAMALI ÖĞRENCİ"
          : "BAŞARISIZ DURUM";
      statusIcon = Icons.info_outline;
    } else {
      stateColor = colorScheme.primary;
      headerText = "PLAN ONAYLANDI";
      statusIcon = Icons.check_circle_outline;
    }

    final isDark = theme.brightness == Brightness.dark;
    final baseBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);


    final glassColor = Color.alphaBlend(
      stateColor.withValues(alpha: 0.12),
      baseBg.withValues(alpha: 0.85),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      left: 0,
      right: 0,
      bottom: 0,
      height: isExpanded ? expandedHeight : collapsedHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: stateColor.withValues(alpha: 0.3), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: stateColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(statusIcon, color: stateColor, size: 24),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: stateColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${vm.totalCredits} Kredi / ${vm.totalEcts.toStringAsFixed(1)} AKTS",
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                              color: theme.iconTheme.color?.withValues(alpha: 0.5),
                              size: 28,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        _buildSectionHeader(context, "DURUM ANALİZİ"),
                        ...vm.appliedRules.map((rule) => _buildRuleItem(context, rule)),

                        const SizedBox(height: 24),

                        _buildSectionHeader(context, "SEÇİLEN DERSLER (${vm.selectedCourses.length})"),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: vm.selectedCourses.isEmpty
                                ? [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text("Henüz ders seçilmedi.", style: theme.textTheme.bodySmall),
                              )
                            ]
                                : vm.selectedCourses.map((c) {
                              final isLast = c == vm.selectedCourses.last;
                              return Column(
                                children: [
                                  ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      c.course.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text("${c.course.code} • ${c.course.ects} AKTS"),
                                    trailing: c.hasConflict
                                        ? Icon(Icons.warning_amber_rounded, color: colorScheme.error)
                                        : Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                                  ),
                                  if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withValues(alpha: 0.5)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (vm.conflictMessages.isNotEmpty) ...[
                          _buildSectionHeader(context, "ÇAKIŞMA RAPORU", color: colorScheme.error),
                          ...vm.conflictMessages.map((msg) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: colorScheme.error, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(msg,
                                      style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13, fontWeight: FontWeight.w500)
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 24),
                        ],

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: color ?? Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, PlanningRule rule) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bg;
    Color border;
    IconData icon;
    Color iconColor;

    if (rule.isWarning) {
      bg = colorScheme.errorContainer.withValues(alpha: 0.4);
      border = colorScheme.error.withValues(alpha: 0.3);
      icon = Icons.warning_amber_rounded;
      iconColor = colorScheme.error;
    } else if (rule.isSuccess) {
      bg = colorScheme.primaryContainer.withValues(alpha: 0.4);
      border = colorScheme.primary.withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
      iconColor = colorScheme.primary;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
      border = Colors.transparent;
      icon = Icons.info_outline_rounded;
      iconColor = theme.iconTheme.color!.withValues(alpha: 0.7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rule.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(rule.value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: iconColor)),
                  ],
                ),
                if (rule.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(rule.reason, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}