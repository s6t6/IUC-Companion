import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/announcement_viewmodel.dart';
import '../data/models/announcement_source.dart';

class AnnouncementSettingsView extends StatelessWidget {
  const AnnouncementSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AnnouncementViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Duyuru Kaynakları")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => _SourceEditorDialog(viewModel: vm),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Yeni Ekle"),
      ),
      body: vm.sources.isEmpty
          ? Center(
          child: Text("Henüz kaynak eklenmemiş.",
              style: TextStyle(color: theme.disabledColor)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.sources.length,
        separatorBuilder: (ctx, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final source = vm.sources[index];
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5))),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  source.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(source.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("ID: ${source.categoryId}",
                  style: TextStyle(color: theme.hintColor)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: "Düzenle",
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => _SourceEditorDialog(
                        viewModel: vm,
                        existingSource: source,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: colorScheme.error),
                    tooltip: "Sil",
                    onPressed: () => _confirmDelete(context, vm, source),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AnnouncementViewModel vm,
      AnnouncementSource source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kaynağı Sil"),
        content: Text("${source.name} kaynağını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.removeSource(source);
              Navigator.pop(ctx);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }
}

class _SourceEditorDialog extends StatefulWidget {
  final AnnouncementViewModel viewModel;
  final AnnouncementSource? existingSource;

  const _SourceEditorDialog({required this.viewModel, this.existingSource});

  @override
  State<_SourceEditorDialog> createState() => _SourceEditorDialogState();
}

class _SourceEditorDialogState extends State<_SourceEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _keyCtrl;
  late final TextEditingController _catCtrl;

  bool get isEditing => widget.existingSource != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingSource?.name ?? "");
    _keyCtrl = TextEditingController(text: widget.existingSource?.siteKey ?? "");
    _catCtrl = TextEditingController(
        text: widget.existingSource?.categoryId.toString() ?? "1");
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isEditing ? Icons.edit : Icons.add_link,
                      color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? "Kaynağı Düzenle" : "Yeni Kaynak Ekle",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _nameCtrl,
                label: "Kaynak İsmi",
                hint: "Örn: Müh. Fak.",
                icon: Icons.label_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _keyCtrl,
                label: "Site Key",
                hint: "Web sitesinden alınan kod",
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _catCtrl,
                label: "Kategori ID",
                hint: "Genel: 1, Öğrenci: 3",
                icon: Icons.category_outlined,
                isNumber: true,
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: const Icon(Icons.help_outline, size: 20),
                  title: const Text("Site Key ve ID Nasıl Bulunur?",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        "1. Tarayıcıda ilgili üniversite sayfasını açın.\n"
                            "2. F12 ile Geliştirici Konsolunu açın.\n"
                            "3. Ağ (Network) sekmesine gelin.\n"
                            "4. Sayfadaki duyuruları yenileyin.\n"
                            "5. 'f_getNotices' isteğini bulun.\n"
                            "6. İstek detaylarında 'siteKey' ve 'categoryId' değerlerini göreceksiniz.",
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(isEditing ? "Güncelle" : "Ekle"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _save() async {
    bool success;
    if (isEditing) {
      success = await widget.viewModel.updateSourceFromInput(
        widget.existingSource!,
        _nameCtrl.text,
        _keyCtrl.text,
        _catCtrl.text,
      );
    } else {
      success = await widget.viewModel.addSourceFromInput(
        _nameCtrl.text,
        _keyCtrl.text,
        _catCtrl.text,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}