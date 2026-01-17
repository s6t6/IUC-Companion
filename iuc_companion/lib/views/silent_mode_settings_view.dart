import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/silent_mode_settings_viewmodel.dart';
import '../utils/permission_helper.dart';
import '../di/locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SilentModeSettingsView extends StatelessWidget {
  const SilentModeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SilentModeSettingsViewModel(locator<SharedPreferences>()),
      child: const _SilentModeSettingsContent(),
    );
  }
}

class _SilentModeSettingsContent extends StatelessWidget {
  const _SilentModeSettingsContent();

  Future<void> _handleModeChange(BuildContext context, SilentModeSettingsViewModel viewModel, int? newValue) async {
    if (newValue == null) return;
    if (newValue == viewModel.selectedModeIndex) return;

    if (newValue == 0) {
      await viewModel.setSilentMode(0);
      return;
    }

    bool hasPermissions = false;

    if (newValue == 1) {
      hasPermissions = await PermissionHelper.ensureLocationPermissions(context);
    }
    else if (newValue == 2) {
      hasPermissions = await PermissionHelper.ensureSchedulePermissions(context);
    }
    else if (newValue == 3) {
      bool locOk = await PermissionHelper.ensureLocationPermissions(context);
      if (locOk && context.mounted) {
        hasPermissions = await PermissionHelper.ensureSchedulePermissions(context);
      }
    }

    if (hasPermissions && context.mounted) {
      await viewModel.setSilentMode(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SilentModeSettingsViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Otomatik Sessiz Mod"),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RadioGroup<int>(
        groupValue: viewModel.selectedModeIndex,
        onChanged: (val) => _handleModeChange(context, viewModel, val),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              "Telefonunuzun ne zaman otomatik olarak sessize alınacağını seçin:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _buildOption(
              context,
              viewModel,
              title: "Konum ve Ders Programı",
              subtitle: "Sadece kampüsteyken VE dersiniz varken sessize alır.",
              value: 3,
              icon: Icons.add_location_alt_outlined,
            ),

            _buildOption(
              context,
              viewModel,
              title: "Sadece Ders Programı",
              subtitle: "Nerede olduğunuza bakmaksızın, ders saatlerinde sessize alır.",
              value: 2,
              icon: Icons.calendar_today_outlined,
            ),

            _buildOption(
              context,
              viewModel,
              title: "Sadece Konum",
              subtitle: "Kampüse girdiğiniz an sessize alır.",
              value: 1,
              icon: Icons.location_on_outlined,
            ),

            const Divider(height: 30),

            _buildOption(
              context,
              viewModel,
              title: "Kapalı (Varsayılan)",
              subtitle: "Otomatik sessize alma özelliği devre dışı.",
              value: 0,
              icon: Icons.notifications_off_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context,
      SilentModeSettingsViewModel viewModel, {
        required String title,
        required String subtitle,
        required int value,
        required IconData icon,
      }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = viewModel.selectedModeIndex == value;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: RadioListTile<int>(
        value: value,
        activeColor: colorScheme.primary,
        secondary: Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey),
        title: Text(title,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
    );
  }
}