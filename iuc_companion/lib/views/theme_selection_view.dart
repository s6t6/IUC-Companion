import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/theme_viewmodel.dart';

class ThemeSelectionView extends StatelessWidget {
  const ThemeSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Tema Seçimi")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: themeVM.presets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final preset = themeVM.presets[index];
          final isSelected = preset.id == themeVM.currentPreset.id;

          final previewScheme = ColorScheme.fromSeed(
            seedColor: preset.primaryColor,
            brightness: preset.brightness,
          );

          return GestureDetector(
            onTap: () => themeVM.setTheme(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: previewScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? previewScheme.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildColorCircle(previewScheme.primary),
                  const SizedBox(width: 8),
                  _buildColorCircle(previewScheme.secondary),
                  const SizedBox(width: 8),
                  _buildColorCircle(previewScheme.tertiary),
                  const SizedBox(width: 8),
                  _buildColorCircle(previewScheme.surfaceContainerHighest),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: previewScheme.onSurface,
                          ),
                        ),
                        Text(
                          preset.brightness == Brightness.dark ? "Karanlık" : "Aydınlık",
                          style: TextStyle(
                            color: previewScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSelected)
                    Icon(Icons.check_circle, color: previewScheme.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
      ),
    );
  }
}