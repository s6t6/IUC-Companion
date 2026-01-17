import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/school_event_service.dart';

class SilentModeSettingsViewModel extends ChangeNotifier {
  final SharedPreferences _prefs;

  int _selectedModeIndex = 0;
  bool _isLoading = true;

  int get selectedModeIndex => _selectedModeIndex;
  bool get isLoading => _isLoading;

  SilentModeSettingsViewModel(this._prefs) {
    _loadPreference();
  }

  void _loadPreference() {
    _selectedModeIndex = _prefs.getInt('silent_mode_preference') ?? 0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSilentMode(int newValue) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _prefs.setInt('silent_mode_preference', newValue);
      _selectedModeIndex = newValue;

      if (newValue == 0) {
        await SchoolEventService.stopService();
      } else {
        await SchoolEventService.startService();
      }
    } catch (e) {
      print("Error setting silent mode: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}