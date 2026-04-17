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
  static const String _model = 'claude-opus-4-7';
  static const String _endpoint =
      'https://api.anthropic.com/v1/messages';

  static final Map<String, TranslationResult> _cache = {};
  static String? _userKey;

  static void setApiKey(String? key) {
    _userKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  static bool get hasKey => _userKey != null && _userKey!.isNotEmpty;

  /// Contextual EN→PL translation via Claude. [context] should be the full
  /// surrounding paragraph so the model can disambiguate senses from the book.
  static Future<TranslationResult> translate({
    required String word,
    required String context,
    String bookTitle = 'Państwo Boże (The City of God) — Święty Augustyn',
  }) async {
    final ctxHash = context.hashCode;
    final key = '${word.toLowerCase()}|$ctxHash';
    final cached = _cache[key];
    if (cached != null) return cached;

    final apiKey = _userKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
          'Brak klucza Claude API. Otwórz menu → Claude Key i wklej klucz z console.anthropic.com.');
    }

    final system =
        'Jesteś ekspertem od teologii łacińskiej i klasyki patrystycznej oraz fonetyki '
        'angielskiej (General American). Tłumaczysz słowo z dzieła "$bookTitle" '
        '(tekst angielski tłumaczony z łaciny Marcusa Dodsa). '
        'Odpowiadasz TYLKO czystym JSON-em, bez markdowna ani komentarzy, '
        'w schemacie: {"pl": "<tłumaczenie>", "note": "<nota lub pusty string>", "ipa": "/<amerykańska transkrypcja IPA>/"}.';

    final userPrompt = '''
ZADANIE: Dla wskazanego słowa zwróć:
1) najtrafniejsze polskie tłumaczenie (1-3 słowa), wybrane w kontekście dokładnie TEGO fragmentu książki (teologia Augustyna, a nie ogólne znaczenie słownikowe),
2) krótką notę (max 1 zdanie po polsku) wyjaśniającą, dlaczego tu taki sens,
3) amerykańską transkrypcję IPA (General American), z ukośnikami, np. /ˈsʌbstəns/.

Słowo: "$word"

Kontekst (akapit, w którym słowo występuje):
"""
$context
"""

Zwróć CZYSTY JSON dokładnie w schemacie:
{"pl": "<tłumaczenie>", "note": "<nota lub pusty string>", "ipa": "/<amerykańska transkrypcja IPA>/"}''';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'system': system,
      'messages': [
        {
          'role': 'user',
          'content': userPrompt,
        }
      ],
    });

    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Claude HTTP ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final contentList = data['content'] as List? ?? const [];
    final text = contentList
        .whereType<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => (b['text'] ?? '').toString())
        .join()
        .trim();

    if (text.isEmpty) throw Exception('Pusta odpowiedź modelu');

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
    } catch (_) {
      parsed = {'pl': text, 'note': ''};
    }

    final ipaRaw = (parsed['ipa'] ?? '').toString().trim();
    final result = TranslationResult(
      translation: (parsed['pl'] ?? '').toString().trim(),
      note: (parsed['note'] ?? '').toString().trim().isEmpty
          ? null
          : (parsed['note']).toString().trim(),
      ipa: ipaRaw.isEmpty ? null : ipaRaw,
      source: 'Claude Opus 4.7 (paragraph context)',
    );
    if (result.translation.isEmpty) {
      throw Exception('Brak pola "pl" w odpowiedzi');
    }
    _cache[key] = result;
    return result;
  }

  static String _extractJson(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return s;
  }
}
