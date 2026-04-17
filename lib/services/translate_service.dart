import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationResult {
  final String translation;
  final String? note;
  final String? ipa;
  final String source;

  TranslationResult({
    required this.translation,
    this.note,
    this.ipa,
    required this.source,
  });
}

class TranslateService {
  // Default shared key baked into the app so end users don't need their own.
  // Users can override in Menu → Klucz Gemini. Keep watch on quota/abuse.
  static const String _defaultKey = 'AIzaSyAi4zlKCdcNOtvrqyG9GSpPY3QOJ1S4SPU';

  static final Map<String, TranslationResult> _cache = {};
  static String? _userKey;

  static void setApiKey(String? key) {
    _userKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  static String? get _effectiveKey =>
      (_userKey != null && _userKey!.isNotEmpty) ? _userKey : _defaultKey;

  static bool get hasKey =>
      _effectiveKey != null && _effectiveKey!.isNotEmpty;

  /// Contextual EN→PL translation via Gemini. [context] should be the full
  /// surrounding paragraph so the model can disambiguate senses from the book.
  /// Returns {translation, optional note explaining the sense in context}.
  static Future<TranslationResult> translate({
    required String word,
    required String context,
    String bookTitle = 'Państwo Boże (The City of God) — Święty Augustyn',
  }) async {
    final ctxHash = context.hashCode;
    final key = '${word.toLowerCase()}|$ctxHash';
    final cached = _cache[key];
    if (cached != null) return cached;

    final effective = _effectiveKey;
    if (effective == null || effective.isEmpty) {
      throw Exception(
          'No Gemini key. Open menu → Gemini Key.');
    }

    final prompt = '''
Jesteś ekspertem od teologii łacińskiej i klasyki patrystycznej oraz fonetyki angielskiej (General American).
Tłumaczysz słowo z dzieła "$bookTitle" (tekst angielski tłumaczony z łaciny Marcusa Dodsa).

ZADANIE: Dla wskazanego słowa zwróć:
1) najtrafniejsze polskie tłumaczenie (1-3 słowa), wybrane w kontekście dokładnie TEGO fragmentu książki (teologia Augustyna, a nie ogólne znaczenie słownikowe),
2) krótką notę (max 1 zdanie po polsku) wyjaśniającą, dlaczego tu taki sens,
3) amerykańską transkrypcję IPA (General American), z ukośnikami, np. /ˈsʌbstəns/.

Słowo: "$word"

Kontekst (akapit, w którym słowo występuje):
"""
$context
"""

Zwróć CZYSTY JSON (bez markdowna, bez komentarzy) dokładnie w schemacie:
{"pl": "<tłumaczenie>", "note": "<nota lub pusty string>", "ipa": "/<amerykańska transkrypcja IPA>/"}
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$effective',
    );
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    });

    final resp = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      throw Exception('Gemini HTTP ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (((data['candidates'] as List?)?.first
            as Map<String, dynamic>?)?['content']?['parts']?[0]?['text'] ??
        '')
        .toString()
        .trim();

    if (text.isEmpty) throw Exception('Empty model response');

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // fallback: wrap as translation only
      parsed = {'pl': text, 'note': ''};
    }

    final ipaRaw = (parsed['ipa'] ?? '').toString().trim();
    final result = TranslationResult(
      translation: (parsed['pl'] ?? '').toString().trim(),
      note: (parsed['note'] ?? '').toString().trim().isEmpty
          ? null
          : (parsed['note']).toString().trim(),
      ipa: ipaRaw.isEmpty ? null : ipaRaw,
      source: 'Google Gemini 2.5 Flash (paragraph context)',
    );
    if (result.translation.isEmpty) {
      throw Exception('Brak pola "pl" w odpowiedzi');
    }
    _cache[key] = result;
    return result;
  }
}
