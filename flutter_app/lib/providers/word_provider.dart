import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../services/api_service.dart';

class WordProvider extends ChangeNotifier {
  final ApiService _api;

  WordProvider(this._api);

  List<WordModel> _words = [];
  List<WordModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  int _total = 0;
  int _currentPage = 1;
  String _currentTag = '全部';
  bool _favoriteOnly = false;
  List<Map<String, dynamic>> _tags = [];

  List<WordModel> get words => _words;
  List<WordModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  int get total => _total;
  int get currentPage => _currentPage;
  String get currentTag => _currentTag;
  bool get favoriteOnly => _favoriteOnly;
  List<Map<String, dynamic>> get tags => _tags;

  Future<void> loadWords({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _words = [];
    }

    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getWords(
        page: _currentPage,
        tag: _currentTag,
        favoriteOnly: _favoriteOnly,
      );
      if (refresh) {
        _words = response.words;
      } else {
        _words.addAll(response.words);
      }
      _total = response.total;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _words.length >= _total) return;
    _currentPage++;
    await loadWords();
  }

  Future<void> setTag(String tag) async {
    _currentTag = tag;
    await loadWords(refresh: true);
  }

  Future<void> setFavoriteOnly(bool value) async {
    _favoriteOnly = value;
    await loadWords(refresh: true);
  }

  Future<void> search(String keyword, {String type = 'keyword'}) async {
    if (keyword.isEmpty) {
      _searchResults = _words;
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final response = await _api.searchWords(
        keyword: keyword,
        searchType: type,
      );
      _searchResults = response.words;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<WordModel?> createWord(Map<String, dynamic> data) async {
    try {
      final word = await _api.createWord(data);
      _words.insert(0, word);
      _total++;
      notifyListeners();
      return word;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> toggleMaster(int id) async {
    try {
      final mastered = await _api.toggleMaster(id);
      final index = _words.indexWhere((w) => w.id == id);
      if (index >= 0) {
        _words[index] = WordModel(
          id: _words[index].id,
          word: _words[index].word,
          isMastered: mastered,
          tags: _words[index].tags,
          isFavorite: _words[index].isFavorite,
          reviewCount: _words[index].reviewCount,
          errorCount: _words[index].errorCount,
          notes: _words[index].notes,
        );
        notifyListeners();
      }
      return mastered;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFavorite(int id) async {
    try {
      final favorite = await _api.toggleFavorite(id);
      final index = _words.indexWhere((w) => w.id == id);
      if (index >= 0) {
        _words[index] = WordModel(
          id: _words[index].id,
          word: _words[index].word,
          isFavorite: favorite,
          tags: _words[index].tags,
          isMastered: _words[index].isMastered,
          reviewCount: _words[index].reviewCount,
          errorCount: _words[index].errorCount,
          notes: _words[index].notes,
        );
        notifyListeners();
      }
      return favorite;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadTags() async {
    try {
      _tags = await _api.getTags();
      notifyListeners();
    } catch (_) {}
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
