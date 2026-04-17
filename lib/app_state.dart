import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'services/storage_service.dart';
import 'services/translate_service.dart';

class AppState extends ChangeNotifier {
  final StorageService storage;
  AppState(this.storage);

  late Map<EbookId, Ebook> ebooks;
  EbookId activeEbook = EbookId.city;
  int currentBook = 0;
  int currentChapter = 0;

  List<Bookmark> bookmarks = [];
  List<JournalEntry> journal = [];
  List<GlossaryEntry> glossary = [];

  double fontScale = 1.0;
  bool dark = false;
  String? geminiKey;

  int navIndex = 0; // 0 read, 1 quote, 2 bookmarks, 3 journal, 4 glossary
  bool showToc = false;

  Ebook get current => ebooks[activeEbook]!;
  BookSection get currentSection => current.sections[currentBook];
  Chapter get currentChapterObj => currentSection.chapters[currentChapter];

  Future<void> loadAll() async {
    final cityRaw = await rootBundle.loadString('assets/city.json');
    final citySections = (jsonDecode(cityRaw) as List)
        .whereType<Map<String, dynamic>>()
        .map(BookSection.fromJson)
        .toList();

    final imitationRaw = await rootBundle.loadString('assets/imitation.json');
    final imitationSections = (jsonDecode(imitationRaw) as List)
        .whereType<Map<String, dynamic>>()
        .map(BookSection.fromJson)
        .toList();

    ebooks = {
      EbookId.city: Ebook(
        id: EbookId.city,
        title: 'The City of God',
        author: 'Saint Augustine',
        sections: citySections,
      ),
      EbookId.imitation: Ebook(
        id: EbookId.imitation,
        title: 'The Imitation of Christ',
        author: 'Thomas à Kempis',
        sections: imitationSections,
      ),
    };

    activeEbook = storage.loadActiveEbook();
    if (!ebooks.containsKey(activeEbook)) activeEbook = EbookId.city;
    final pos = storage.loadPosition(activeEbook);
    currentBook = pos.book;
    currentChapter = pos.chapter;
    _clampPosition();

    // drop legacy entries pointing at removed ebooks (if any)
    bookmarks = storage.loadBookmarks().where((b) => ebooks.containsKey(b.ebook)).toList();
    journal = storage.loadJournal().where((j) => ebooks.containsKey(j.ebook)).toList();
    glossary = storage.loadGlossary();
    fontScale = storage.loadFontScale();
    dark = storage.loadDark();
    geminiKey = storage.loadGeminiKey();
    TranslateService.setApiKey(geminiKey);
    notifyListeners();
  }

  void _clampPosition() {
    final sections = current.sections;
    if (currentBook < 0 || currentBook >= sections.length) currentBook = 0;
    final chapters = sections[currentBook].chapters;
    if (currentChapter < 0 || currentChapter >= chapters.length) {
      currentChapter = 0;
    }
  }

  Future<void> setGeminiKey(String v) async {
    geminiKey = v.trim().isEmpty ? null : v.trim();
    await storage.saveGeminiKey(v);
    TranslateService.setApiKey(geminiKey);
    notifyListeners();
  }

  Future<void> goTo(EbookId id, int b, int c) async {
    if (id != activeEbook) {
      activeEbook = id;
      await storage.saveActiveEbook(id);
    }
    currentBook = b;
    currentChapter = c;
    _clampPosition();
    await storage.savePosition(id, currentBook, currentChapter);
    navIndex = 0;
    showToc = false;
    notifyListeners();
  }

  /// Switch the active ebook, restoring the last-read position for it.
  Future<void> switchEbook(EbookId id) async {
    if (!ebooks.containsKey(id) || id == activeEbook) return;
    activeEbook = id;
    await storage.saveActiveEbook(id);
    final pos = storage.loadPosition(id);
    currentBook = pos.book;
    currentChapter = pos.chapter;
    _clampPosition();
    navIndex = 0;
    showToc = false;
    notifyListeners();
  }

  bool get hasNext {
    final sections = current.sections;
    return currentBook < sections.length - 1 ||
        currentChapter < sections[currentBook].chapters.length - 1;
  }

  bool get hasPrev => currentBook > 0 || currentChapter > 0;

  Future<void> next() async {
    final sections = current.sections;
    if (currentChapter < sections[currentBook].chapters.length - 1) {
      currentChapter++;
    } else if (currentBook < sections.length - 1) {
      currentBook++;
      currentChapter = 0;
    }
    await storage.savePosition(activeEbook, currentBook, currentChapter);
    notifyListeners();
  }

  Future<void> prev() async {
    if (currentChapter > 0) {
      currentChapter--;
    } else if (currentBook > 0) {
      currentBook--;
      currentChapter = current.sections[currentBook].chapters.length - 1;
    }
    await storage.savePosition(activeEbook, currentBook, currentChapter);
    notifyListeners();
  }

  bool isCurrentBookmarked() {
    return bookmarks.any((b) =>
        b.ebook == activeEbook &&
        b.book == currentBook &&
        b.chapter == currentChapter);
  }

  Future<void> toggleBookmark() async {
    if (isCurrentBookmarked()) {
      bookmarks.removeWhere((b) =>
          b.ebook == activeEbook &&
          b.book == currentBook &&
          b.chapter == currentChapter);
    } else {
      final ch = currentChapterObj;
      final label = ch.title.isNotEmpty ? ch.title : 'Chapter ${ch.num}';
      bookmarks.insert(
          0,
          Bookmark(
            ebook: activeEbook,
            book: currentBook,
            chapter: currentChapter,
            label: label,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));
    }
    await storage.saveBookmarks(bookmarks);
    notifyListeners();
  }

  Future<void> removeBookmark(int idx) async {
    bookmarks.removeAt(idx);
    await storage.saveBookmarks(bookmarks);
    notifyListeners();
  }

  Future<void> addJournal(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    journal.insert(
        0,
        JournalEntry(
          id: '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey()}',
          ebook: activeEbook,
          book: currentBook,
          chapter: currentChapter,
          text: trimmed,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
    await storage.saveJournal(journal);
    notifyListeners();
  }

  Future<void> removeJournal(String id) async {
    journal.removeWhere((e) => e.id == id);
    await storage.saveJournal(journal);
    notifyListeners();
  }

  Future<void> upsertGlossary({
    required String word,
    required String translation,
    String? ipa,
    String? note,
  }) async {
    final key = word.trim().toLowerCase();
    if (key.isEmpty || translation.trim().isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existingIdx =
        glossary.indexWhere((g) => g.word.toLowerCase() == key);
    final entry = GlossaryEntry(
      word: word.trim(),
      translation: translation.trim(),
      ipa: (ipa == null || ipa.trim().isEmpty) ? null : ipa.trim(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      createdAt: now,
    );
    if (existingIdx >= 0) {
      glossary.removeAt(existingIdx);
    }
    glossary.insert(0, entry);
    await storage.saveGlossary(glossary);
    notifyListeners();
  }

  Future<void> removeGlossary(String word) async {
    final key = word.toLowerCase();
    glossary.removeWhere((g) => g.word.toLowerCase() == key);
    await storage.saveGlossary(glossary);
    notifyListeners();
  }

  Future<void> clearGlossary() async {
    glossary.clear();
    await storage.saveGlossary(glossary);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v.clamp(0.8, 1.6);
    await storage.saveFontScale(fontScale);
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    dark = v;
    await storage.saveDark(v);
    notifyListeners();
  }

  void setNav(int i) {
    navIndex = i;
    showToc = false;
    notifyListeners();
  }

  void openToc() {
    showToc = true;
    notifyListeners();
  }

  void closeToc() {
    showToc = false;
    notifyListeners();
  }
}
