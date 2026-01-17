import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'theme_selection_view.dart';
import 'silent_mode_settings_view.dart';
import 'schedule_correction_view.dart';
import 'profile_view.dart';
import 'about_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline, color: colorScheme.primary),
            title: const Text("Profil Detayları"),
            subtitle: const Text("Bölüm ve transkript bilgileri"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
            title: const Text("Tema"),
            subtitle: Text(themeVM.currentPreset.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeVM.currentPreset.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeSelectionView()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.do_not_disturb_on_outlined, color: colorScheme.primary),
            title: const Text("Otomatik Sessiz Mod"),
            subtitle: const Text("Konum ve Ders Programı ayarları"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SilentModeSettingsView()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.edit_calendar, color: colorScheme.primary),
            title: const Text("Ders Programını Düzenle"),
            subtitle: const Text("Hatalı veya eksik dersleri düzeltin"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScheduleCorrectionView()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Hakkında"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutView()),
              );
            },
          ),
        ],
      ),
    );
  }
}