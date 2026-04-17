import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class StorageService {
  static const _activeEbookKey = 'active_ebook';
  static const _bookmarksKey = 'app_bookmarks_v1';
  static const _journalKey = 'app_journal_v1';
  static const _fontScaleKey = 'app_font_scale';
  static const _darkKey = 'app_dark';
  static const _geminiKey = 'app_gemini_key';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Position per ebook
  Future<void> savePosition(EbookId ebook, int book, int chapter) async {
    await _prefs.setInt('book_${ebook.name}', book);
    await _prefs.setInt('chapter_${ebook.name}', chapter);
  }

  ({int book, int chapter}) loadPosition(EbookId ebook) {
    return (
      book: _prefs.getInt('book_${ebook.name}') ?? 0,
      chapter: _prefs.getInt('chapter_${ebook.name}') ?? 0,
    );
  }

  Future<void> saveActiveEbook(EbookId ebook) =>
      _prefs.setString(_activeEbookKey, ebook.name);

  EbookId loadActiveEbook() {
    final s = _prefs.getString(_activeEbookKey);
    return EbookId.values.firstWhere((e) => e.name == s,
        orElse: () => EbookId.city);
  }

  // Bookmarks
  List<Bookmark> loadBookmarks() {
    final raw = _prefs.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Bookmark.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBookmarks(List<Bookmark> items) async {
    await _prefs.setString(
        _bookmarksKey, jsonEncode(items.map((b) => b.toJson()).toList()));
  }

  // Journal
  List<JournalEntry> loadJournal() {
    final raw = _prefs.getString(_journalKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(JournalEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveJournal(List<JournalEntry> items) async {
    await _prefs.setString(
        _journalKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  // Settings
  double loadFontScale() => _prefs.getDouble(_fontScaleKey) ?? 1.0;
  Future<void> saveFontScale(double v) => _prefs.setDouble(_fontScaleKey, v);

  bool loadDark() => _prefs.getBool(_darkKey) ?? false;
  Future<void> saveDark(bool v) => _prefs.setBool(_darkKey, v);

  String? loadGeminiKey() {
    final v = _prefs.getString(_geminiKey);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  Future<void> saveGeminiKey(String v) =>
      _prefs.setString(_geminiKey, v.trim());
}
