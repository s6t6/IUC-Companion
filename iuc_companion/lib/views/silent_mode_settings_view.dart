import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/school_zone_service.dart';
import '../data/local/app_database.dart';

class SilentModeSettingsView extends StatefulWidget {
  const SilentModeSettingsView({super.key});

  @override
  State<SilentModeSettingsView> createState() => _SilentModeSettingsViewState();
}

class _SilentModeSettingsViewState extends State<SilentModeSettingsView> {
  int _selectedModeIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModeIndex = prefs.getInt('silent_mode_preference') ?? 3;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(int? newValue) async {
    if (newValue == null) return;

    setState(() {
      _selectedModeIndex = newValue;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('silent_mode_preference', newValue);

    if (mounted) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      await SchoolZoneService(db).checkUserStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Otomatik Sessiz Mod"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Telefonunuzun ne zaman otomatik olarak sessize alınacağını seçin:",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          _buildOption(
            title: "Konum ve Ders Programı",
            subtitle: "Sadece kampüsteyken VE dersiniz varken sessize alır.",
            value: 3,
            icon: Icons.add_location_alt_outlined,
          ),

          _buildOption(
            title: "Sadece Ders Programı",
            subtitle: "Nerede olduğunuza bakmaksızın, ders saatlerinde sessize alır.",
            value: 2,
            icon: Icons.calendar_today_outlined,
          ),

          _buildOption(
            title: "Sadece Konum",
            subtitle: "Kampüse girdiğiniz an sessize alır.",
            value: 1,
            icon: Icons.location_on_outlined,
          ),

          const Divider(height: 30),

          _buildOption(
            title: "Kapalı",
            subtitle: "Otomatik sessize alma özelliği devre dışı kalır.",
            value: 0,
            icon: Icons.notifications_off_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedModeIndex == value;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: RadioListTile<int>(
        value: value,
        groupValue: _selectedModeIndex,
        onChanged: _updatePreference,
        activeColor: colorScheme.primary,
        secondary: Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey),
        title: Text(
            title,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            )
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
    );
  }
}