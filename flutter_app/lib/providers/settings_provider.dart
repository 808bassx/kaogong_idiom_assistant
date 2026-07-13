import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _api;

  SettingsProvider(this._api);

  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _aiConfig = {};
  Map<String, dynamic> _aiHealth = {};
  List<Map<String, dynamic>> _prompts = [];
  Map<String, dynamic> _activePrompt = {};
  List<Map<String, dynamic>> _backups = [];
  List<String> _availableModels = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get settings => _settings;
  Map<String, dynamic> get aiConfig => _aiConfig;
  Map<String, dynamic> get aiHealth => _aiHealth;
  List<Map<String, dynamic>> get prompts => _prompts;
  Map<String, dynamic> get activePrompt => _activePrompt;
  List<Map<String, dynamic>> get backups => _backups;
  List<String> get availableModels => _availableModels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _api.getAllSettings();
      _aiConfig = await _api.getAIConfig();
      _aiHealth = await _api.getAIHealth();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      await _api.updateSetting(key, value);
      _settings[key] = value;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateAIConfig(Map<String, String> config) async {
    try {
      await _api.updateAIConfig(config);
      _aiConfig.addAll(config);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkAIHealth() async {
    try {
      _aiHealth = await _api.getAIHealth();
      notifyListeners();
    } catch (e) {
      _aiHealth = {};
      notifyListeners();
    }
  }

  Future<void> loadModels(String engine) async {
    try {
      _availableModels = await _api.getAIModels(engine);
      notifyListeners();
    } catch (e) {
      _availableModels = [];
      notifyListeners();
    }
  }

  // ===== Prompt =====

  Future<void> loadPrompts() async {
    try {
      _prompts = await _api.getPrompts();
      _activePrompt = await _api.getActivePrompt();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createPrompt(String name, String content) async {
    try {
      await _api.createPrompt(name, content);
      await loadPrompts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePrompt(int id, Map<String, dynamic> data) async {
    try {
      await _api.updatePrompt(id, data);
      await loadPrompts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePrompt(int id) async {
    try {
      await _api.deletePrompt(id);
      await loadPrompts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> activatePrompt(int id) async {
    try {
      await _api.activatePrompt(id);
      await loadPrompts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetDefaultPrompt() async {
    try {
      await _api.resetDefaultPrompt();
      await loadPrompts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== Backup =====

  Future<void> loadBackups() async {
    try {
      _backups = await _api.listBackups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> backupDatabase() async {
    try {
      final result = await _api.backupDatabase();
      await loadBackups();
      return result['message'];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
