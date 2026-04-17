class Chapter {
  final String num;
  final String title;
  final List<String> paragraphs;

  Chapter({required this.num, required this.title, required this.paragraphs});

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        num: (j['num'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        paragraphs:
            ((j['paragraphs'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class BookSection {
  final String title;
  final List<Chapter> chapters;

  BookSection({required this.title, required this.chapters});

  factory BookSection.fromJson(Map<String, dynamic> j) => BookSection(
        title: (j['title'] ?? '').toString(),
        chapters: ((j['chapters'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Chapter.fromJson)
            .toList(),
      );
}

enum EbookId { city }

class Ebook {
  final EbookId id;
  final String title;
  final String author;
  final List<BookSection> sections;

  Ebook({
    required this.id,
    required this.title,
    required this.author,
    required this.sections,
  });
}

class Bookmark {
  final EbookId ebook;
  final int book;
  final int chapter;
  final String label;
  final int createdAt;

  Bookmark({
    required this.ebook,
    required this.book,
    required this.chapter,
    required this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'ebook': ebook.name,
        'book': book,
        'chapter': chapter,
        'label': label,
        'createdAt': createdAt,
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        ebook: EbookId.values.firstWhere((e) => e.name == j['ebook'],
            orElse: () => EbookId.city),
        book: (j['book'] as num).toInt(),
        chapter: (j['chapter'] as num).toInt(),
        label: j['label']?.toString() ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class GlossaryEntry {
  final String word;
  final String translation;
  final String? ipa;
  final String? note;
  final int createdAt;

  GlossaryEntry({
    required this.word,
    required this.translation,
    this.ipa,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'translation': translation,
        'ipa': ipa,
        'note': note,
        'createdAt': createdAt,
      };

  factory GlossaryEntry.fromJson(Map<String, dynamic> j) => GlossaryEntry(
        word: j['word']?.toString() ?? '',
        translation: j['translation']?.toString() ?? '',
        ipa: (j['ipa'] as String?)?.trim().isEmpty == true
            ? null
            : j['ipa']?.toString(),
        note: (j['note'] as String?)?.trim().isEmpty == true
            ? null
            : j['note']?.toString(),
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class JournalEntry {
  final String id;
  final EbookId ebook;
  final int book;
  final int chapter;
  final String text;
  final int createdAt;

  JournalEntry({
    required this.id,
    required this.ebook,
    required this.book,
    required this.chapter,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ebook': ebook.name,
        'book': book,
        'chapter': chapter,
        'text': text,
        'createdAt': createdAt,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id']?.toString() ?? '',
        ebook: EbookId.values.firstWhere((e) => e.name == j['ebook'],
            orElse: () => EbookId.city),
        book: (j['book'] as num).toInt(),
        chapter: (j['chapter'] as num).toInt(),
        text: j['text']?.toString() ?? '',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );
}

/// Prettifies the raw section title from the source (e.g. "BOOK I",
/// "THE FIRST BOOK") to a nicely title-cased English label.
String displayBookTitle(String raw) {
  if (raw.isEmpty) return '';
  final s = raw.trim();
  final m = RegExp(r'^BOOK\s+([IVXLC]+)', caseSensitive: false).firstMatch(s);
  if (m != null) return 'Book ${m.group(1)}';
  final m2 = RegExp(r'^THE\s+BOOK\s+([IVXLC]+)', caseSensitive: false).firstMatch(s);
  if (m2 != null) return 'Book ${m2.group(1)}';
  const ordinals = {
    'THE FIRST BOOK': 'Book I',
    'THE SECOND BOOK': 'Book II',
    'THE THIRD BOOK': 'Book III',
    'THE FOURTH BOOK': 'Book IV',
  };
  if (ordinals.containsKey(s.toUpperCase())) return ordinals[s.toUpperCase()]!;
  // Fallback: Title Case every word
  return s
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
