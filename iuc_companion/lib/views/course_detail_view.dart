import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/course_detail_viewmodel.dart';
import '../data/models/course.dart';
import '../di/locator.dart';
import '../data/repositories/university_repository.dart';

class CourseDetailView extends StatelessWidget {
  final Course courseSummary;

  const CourseDetailView({Key? key, required this.courseSummary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourseDetailViewModel(locator<UniversityRepository>()),
      child: _CourseDetailContent(courseSummary: courseSummary),
    );
  }
}

class _CourseDetailContent extends StatefulWidget {
  final Course courseSummary;

  const _CourseDetailContent({required this.courseSummary});

  @override
  State<_CourseDetailContent> createState() => _CourseDetailContentState();
}

class _CourseDetailContentState extends State<_CourseDetailContent> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<CourseDetailViewModel>(context, listen: false)
            .loadCourseDetail(widget.courseSummary.code));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CourseDetailViewModel>(context);
    final detail = viewModel.detail;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3, // 3 Sekme: Genel, İçerik, Kazanımlar
      child: Scaffold(
        appBar: AppBar(
          title: Hero(
            tag: 'course_code_${widget.courseSummary.code}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                widget.courseSummary.code,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: "Genel"),
              Tab(text: "İçerik"),
              Tab(text: "Kazanımlar"),
            ],
          ),
        ),
        body: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.errorMessage != null
            ? Center(child: Text(viewModel.errorMessage!, style: TextStyle(color: colorScheme.error)))
            : detail == null
            ? const Center(child: Text("Veri yok"))
            : TabBarView(
          children: [
            _buildGeneralTab(context, detail),
            _buildContentTab(context, detail),
            _buildOutcomesTab(context, detail),
          ],
        ),
      ),
    );
  }

  // 1. Sekme: Genel Bilgiler
  Widget _buildGeneralTab(BuildContext context, dynamic detail) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          detail.baseInfo.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(context, Icons.person, "Eğitmen", detail.instructor),
        _buildInfoRow(context, Icons.language, "Dil", detail.language),
        _buildInfoRow(context, Icons.credit_card, "Kredi", "${detail.baseInfo.credit}"),
        _buildInfoRow(context, Icons.school, "AKTS", "${detail.baseInfo.ects}"),
        _buildInfoRow(context, Icons.class_, "Teori / Uygulama",
            "${detail.baseInfo.theory} Saat / ${detail.baseInfo.practice} Saat"),
      ],
    );
  }

  // 2. Sekme: İçerik ve Amaç
  Widget _buildContentTab(BuildContext context, dynamic detail) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle(context, "Dersin Amacı"),
        Text(
          detail.aim.isEmpty ? "Belirtilmemiş" : detail.aim,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Divider(height: 30),
        _buildSectionTitle(context, "Ders İçeriği"),
        Text(
          detail.content.isEmpty ? "Belirtilmemiş" : detail.content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Divider(height: 30),
        _buildSectionTitle(context, "Kaynaklar"),
        Text(
          detail.resources.isEmpty ? "Belirtilmemiş" : detail.resources,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  // 3. Sekme: Öğrenme Çıktıları
  Widget _buildOutcomesTab(BuildContext context, dynamic detail) {
    final theme = Theme.of(context);

    if (detail.outcomes.isEmpty) {
      return Center(
        child: Text("Kazanım bilgisi girilmemiş.", style: theme.textTheme.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: detail.outcomes.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.tertiaryContainer,
            foregroundColor: theme.colorScheme.onTertiaryContainer,
            child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(
            detail.outcomes[index],
            style: theme.textTheme.bodyMedium,
          ),
        );
      },
    );
  }

  // Yardımcı Widgetlar
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)
                ),
                Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}