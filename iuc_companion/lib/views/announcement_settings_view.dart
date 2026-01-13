import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/announcement_viewmodel.dart';

class AnnouncementSettingsView extends StatelessWidget {
  const AnnouncementSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AnnouncementViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Duyuru Kaynakları")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: vm.sources.length,
        itemBuilder: (context, index) {
          final source = vm.sources[index];
          return ListTile(
            title: Text(source.name),
            subtitle: Text("Kategori ID: ${source.categoryId}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => vm.removeSource(source),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, AnnouncementViewModel vm) {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Kaynak Ekle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "İsim (Örn: Müh. Fak.)")),
              TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: "Site Key")),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: "Kategori ID (Genel: 1, Öğr: 3)")),
              const SizedBox(height: 10),
              const Text(
                "İpucu: Site Key'i bulmak için tarayıcıda ilgili sitenin geliştirici konsolunu (F12) açın, Ağ (Network) sekmesinde 'f_getNotices' isteğini aratın.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && keyCtrl.text.isNotEmpty) {
                vm.addSource(nameCtrl.text, keyCtrl.text, int.tryParse(catCtrl.text) ?? 1);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }
}