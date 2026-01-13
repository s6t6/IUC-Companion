import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/schedule_correction_viewmodel.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/university_repository.dart';
import '../data/models/schedule_item.dart';

class ScheduleCorrectionView extends StatelessWidget {
  const ScheduleCorrectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScheduleCorrectionViewModel(
        Provider.of<ScheduleRepository>(context, listen: false),
        Provider.of<UniversityRepository>(context, listen: false),
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ScheduleCorrectionViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ders Programını Düzenle"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseSearchSheet(context, vm),
        label: const Text("Ders Ekle"),
        icon: const Icon(Icons.add),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.groupedItems.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: vm.groupedItems.keys.length,
        itemBuilder: (context, index) {
          final courseCode = vm.groupedItems.keys.elementAt(index);
          final items = vm.groupedItems[courseCode]!;
          final courseName = items.first.courseName;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              backgroundColor:
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  "${items.length}",
                  style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                courseName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(courseCode),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever,
                    color: Colors.red),
                tooltip: "Dersi Sil",
                onPressed: () => _confirmDeleteCourse(
                    context, vm, courseCode, courseName),
              ),
              children: [
                ...items.map((item) => ListTile(
                  dense: true,
                  leading:
                  const Icon(Icons.access_time, size: 20),
                  title: Text("${item.day} ${item.time}"),
                  subtitle: Text(item.location.isEmpty
                      ? "Konum Yok"
                      : item.location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditorDialog(
                            context, vm,
                            courseCode: courseCode,
                            courseName: courseName,
                            existingItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: Colors.red),
                        onPressed: () => vm.deleteItem(item),
                      ),
                    ],
                  ),
                )),
                ListTile(
                  leading: Icon(Icons.add_circle_outline,
                      color: colorScheme.primary),
                  title: Text("Bu derse saat ekle",
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  onTap: () => _showEditorDialog(context, vm,
                      courseCode: courseCode,
                      courseName: courseName,
                      existingItem: null),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          const Text("Programınız boş görünüyor."),
        ],
      ),
    );
  }

  void _confirmDeleteCourse(BuildContext context,
      ScheduleCorrectionViewModel vm, String code, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dersi Sil"),
        content: Text(
            "$name ($code) dersini ve tüm saatlerini silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteCourse(code);
              Navigator.pop(ctx);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  // Ders Seçme
  void _showCourseSearchSheet(
      BuildContext parentContext, ScheduleCorrectionViewModel vm) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: vm,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer<ScheduleCorrectionViewModel>(
              builder: (context, vm, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "Ders Ara (Kod veya İsim)",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: vm.searchCourses,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: vm.filteredCourses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final course = vm.filteredCourses[index];
                          return ListTile(
                            title: Text(course.name),
                            subtitle: Text(course.code),
                            trailing: const Icon(Icons.add),
                            onTap: () {
                              Navigator.pop(context);
                              _showEditorDialog(parentContext, vm,
                                  courseCode: course.code,
                                  courseName: course.name,
                                  existingItem: null);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Düzenleme
  void _showEditorDialog(
      BuildContext context, ScheduleCorrectionViewModel vm,
      {required String courseCode,
        required String courseName,
        ScheduleItem? existingItem}) {
    final List<String> days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    String selectedDay = existingItem?.day.trim() ?? "Pazartesi";
    if (!days.contains(selectedDay)) selectedDay = "Pazartesi";

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 50);

    if (existingItem != null) {
      try {
        final regex = RegExp(r'(\d{1,2})[:.](\d{2})');
        final matches = regex.allMatches(existingItem.time).toList();

        if (matches.length >= 2) {
          startTime = TimeOfDay(
              hour: int.parse(matches[0].group(1)!),
              minute: int.parse(matches[0].group(2)!));
          endTime = TimeOfDay(
              hour: int.parse(matches[1].group(1)!),
              minute: int.parse(matches[1].group(2)!));
        }
      } catch (e) {
        print("Time parsing error: $e");
      }
    }

    final locCtrl = TextEditingController(text: existingItem?.location ?? "");
    final instrCtrl =
    TextEditingController(text: existingItem?.instructor ?? "");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingItem == null ? "Saat Ekle" : "Saati Düzenle"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(courseName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(courseCode,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: "Gün"),
                    items: days
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerButton(
                          label: "Başlangıç",
                          time: startTime,
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (t != null) setState(() => startTime = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerButton(
                          label: "Bitiş",
                          time: endTime,
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                );
                              },
                            );
                            if (t != null) setState(() => endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                      controller: locCtrl,
                      decoration:
                      const InputDecoration(labelText: "Konum / Sınıf")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: instrCtrl,
                      decoration: const InputDecoration(
                          labelText: "Eğitmen (Opsiyonel)")),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal")),
              FilledButton(
                onPressed: () {
                  final timeString =
                      "${_formatTime(startTime)}-${_formatTime(endTime)}";

                  final newItem = ScheduleItem(
                    id: existingItem?.id,
                    profileId: 0,
                    courseCode: courseCode,
                    courseName: courseName,
                    day: selectedDay,
                    time: timeString,
                    location: locCtrl.text,
                    instructor: instrCtrl.text,
                    semester: "Manuel",
                  );

                  vm.saveItem(newItem);
                  Navigator.pop(ctx);
                },
                child: const Text("Kaydet"),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h.$m";
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPressed;

  const _TimePickerButton(
      {required this.label, required this.time, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$h:$m", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Icon(Icons.access_time, size: 18),
          ],
        ),
      ),
    );
  }
}