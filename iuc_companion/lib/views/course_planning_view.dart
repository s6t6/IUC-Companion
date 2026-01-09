import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/course_planning_viewmodel.dart';
import '../data/repositories/university_repository.dart';
import '../data/repositories/schedule_repository.dart';

import 'widgets/planning/filter_bar.dart';
import 'widgets/planning/calendar.dart';
import 'widgets/planning/status_hud.dart';

class CoursePlanningView extends StatelessWidget {
  const CoursePlanningView({super.key});

  @override
  Widget build(BuildContext context) {
    final uniRepo = Provider.of<UniversityRepository>(context, listen: false);
    final schedRepo = Provider.of<ScheduleRepository>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => CoursePlanningViewModel(uniRepo, schedRepo),
      child: const _CoursePlanningContent(),
    );
  }
}

class _CoursePlanningContent extends StatefulWidget {
  const _CoursePlanningContent();

  @override
  State<_CoursePlanningContent> createState() => _CoursePlanningContentState();
}

class _CoursePlanningContentState extends State<_CoursePlanningContent> {
  bool _isHudExpanded = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CoursePlanningViewModel>(context);
    final theme = Theme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = viewModel.conflictMessages.isNotEmpty ? 140.0 : 115.0;
    final expandedHeight = screenHeight * 0.75;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Ders Planla"),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.isScheduleEmpty
          ? _buildEmptyState(context)
          : Stack(
        children: [
          Column(
            children: [
              const PlanningFilterBar(),
              Expanded(
                child: PlanningCalendar(
                  bottomPadding: collapsedHeight + 20,
                ),
              ),
            ],
          ),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isHudExpanded,
              child: GestureDetector(
                onTap: () => setState(() => _isHudExpanded = false),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isHudExpanded ? 0.6 : 0.0,
                  child: Container(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // 3. HUD Layer
          PlanningStatusHUD(
            isExpanded: _isHudExpanded,
            onToggle: () =>
                setState(() => _isHudExpanded = !_isHudExpanded),
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: colorScheme.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Program Bulunamadı",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ders planlaması yapabilmek için önce bir ders programı yüklemelisiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Geri Dön"),
            )
          ],
        ),
      ),
    );
  }
}