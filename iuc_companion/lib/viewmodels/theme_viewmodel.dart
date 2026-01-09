import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color primaryColor;
  final Brightness brightness;

  final Color? customScaffoldColor;
  final Color? customSurfaceColor;
  final Color? customSecondaryColor;
  final Color? customOnSurfaceColor;

  ThemePreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.brightness,
    this.customScaffoldColor,
    this.customSurfaceColor,
    this.customSecondaryColor,
    this.customOnSurfaceColor,
  });

  ThemeData get themeData {
    final seedScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: customSecondaryColor,
      surface: customScaffoldColor ?? (brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF5F5F5)),
      onSurface: customOnSurfaceColor,
    );

    final colorScheme = seedScheme.copyWith(

      primary: primaryColor,
      secondary: customSecondaryColor ?? seedScheme.secondary,

      surface: customScaffoldColor ?? seedScheme.surface,

      surfaceContainer: customSurfaceColor ?? (brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white),

      onSurface: customOnSurfaceColor ?? seedScheme.onSurface,
    );

    final isDark = brightness == Brightness.dark;

    final semanticColors = SemanticColors(
      success: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      warning: isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
      info:    isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
      link:    isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0277BD),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [semanticColors],

      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainer,
      cardTheme: CardThemeData(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: customSurfaceColor ?? (brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
      ), dialogTheme: DialogThemeData(backgroundColor: colorScheme.surfaceContainer),
    );
  }
}

class ThemeViewModel extends ChangeNotifier {

  final List<ThemePreset> presets = [
    // 1. IUC Özel Tema
    ThemePreset(
      id: 'iuc_custom',
      name: "IUC",
      primaryColor: const Color(0xFFD4AF37),
      brightness: Brightness.dark,
      customScaffoldColor: const Color(0xFF0F151C),
      customSurfaceColor: const Color(0xFF1E2732),
      customSecondaryColor: const Color(0xFFF6C858),
      customOnSurfaceColor: const Color(0xFFE0E0E0),
    ),

    // 2. Standart Temalar
    ThemePreset(id: 'classic_light', name: "Klasik (Aydınlık)", primaryColor: Colors.indigo, brightness: Brightness.light),
    ThemePreset(id: 'classic_dark', name: "Klasik (Karanlık)", primaryColor: Colors.indigo, brightness: Brightness.dark),
    ThemePreset(id: 'ocean_blue', name: "Okyanus Mavisi", primaryColor: Colors.cyan, brightness: Brightness.light),
    ThemePreset(id: 'midnight_purple', name: "Gece Moru", primaryColor: Colors.deepPurple, brightness: Brightness.dark),
    ThemePreset(id: 'forest_green', name: "Orman Yeşili", primaryColor: Colors.teal, brightness: Brightness.dark),
    ThemePreset(id: 'sunset_orange', name: "Gün Batımı", primaryColor: Colors.deepOrange, brightness: Brightness.light),
  ];

  late ThemePreset _currentPreset;

  ThemePreset get currentPreset => _currentPreset;
  ThemeData get currentTheme => _currentPreset.themeData;

  ThemeViewModel() {
    _currentPreset = presets[0]; //Default IUC
    _loadTheme();
  }

  void setTheme(ThemePreset preset) {
    _currentPreset = preset;
    _saveTheme(preset.id);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('theme_id');

    if (savedId != null) {
      _currentPreset = presets.firstWhere(
              (p) => p.id == savedId,
          orElse: () => presets[1]
      );
    }
    notifyListeners();
  }

  Future<void> _saveTheme(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_id', id);
  }
}

class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color? success;
  final Color? warning;
  final Color? info;
  final Color? link;

  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.link,
  });

  @override
  SemanticColors copyWith({Color? success, Color? warning, Color? info, Color? link}) {
    return SemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      link: link ?? this.link,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      info: Color.lerp(info, other.info, t),
      link: Color.lerp(link, other.link, t),
    );
  }
}