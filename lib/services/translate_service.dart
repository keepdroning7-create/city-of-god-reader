import 'dart:convert';
import 'dart:math';
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

  // Ordered list of models to try. If one is overloaded / rate-limited we
  // fall through to the next before giving up.
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-flash-latest',
    'gemini-2.0-flash',
    'gemini-2.0-flash-001',
  ];

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
3) amerykańską transkrypcję IPA (General American), z ukośnikami, np. /ˈsʌbstəns/. TO POLE JEST WYMAGANE - ZAWSZE wypełnij.

Słowo: "$word"

Kontekst (akapit, w którym słowo występuje):
"""
$context
"""

Zwróć CZYSTY JSON (bez markdowna, bez komentarzy) dokładnie w schemacie:
{"pl": "<tłumaczenie>", "note": "<nota lub pusty string>", "ipa": "/<amerykańska transkrypcja IPA>/"}
''';

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

    // Try each model up to 2 passes, with exponential backoff between passes.
    // This rides out short 503 / 429 spikes without hanging the UI forever.
    Object? lastError;
    int? lastStatus;
    String? lastBody;
    for (var pass = 0; pass < 2; pass++) {
      for (final model in _models) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$effective',
        );
        try {
          final resp = await http
              .post(uri,
                  headers: {'Content-Type': 'application/json'}, body: body)
              .timeout(const Duration(seconds: 20));

          if (resp.statusCode == 200) {
            final result = _parseResponse(resp.body, model: model);
            _cache[key] = result;
            return result;
          }

          lastStatus = resp.statusCode;
          lastBody = resp.body;
          // 503 (overloaded) / 429 (rate limit) → try next model
          if (resp.statusCode == 503 ||
              resp.statusCode == 429 ||
              resp.statusCode == 500) {
            continue;
          }
          // 4xx other than 429 → not worth retrying (bad key, bad request…)
          throw Exception('Gemini HTTP ${resp.statusCode}: ${resp.body}');
        } catch (e) {
          lastError = e;
          // timeout / network error → try next model
          continue;
        }
      }
      // Backoff between passes (1s, 2s)
      if (pass == 0) {
        await Future.delayed(Duration(seconds: pow(2, pass).toInt()));
      }
    }

    if (lastStatus != null) {
      throw Exception(
          'Wszystkie modele Gemini niedostępne (ostatni status HTTP $lastStatus). '
          'Spróbuj za chwilę. Szczegóły: $lastBody');
    }
    throw Exception(
        'Nie udało się połączyć z Gemini: ${lastError ?? "unknown error"}');
  }

  static TranslationResult _parseResponse(String respBody, {required String model}) {
    final data = jsonDecode(respBody) as Map<String, dynamic>;
    final text = (((data['candidates'] as List?)?.first
            as Map<String, dynamic>?)?['content']?['parts']?[0]?['text'] ??
        '')
        .toString()
        .trim();

    if (text.isEmpty) throw Exception('Empty model response');

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
      source: 'Google Gemini ($model) — paragraph context',
    );
    if (result.translation.isEmpty) {
      throw Exception('Brak pola "pl" w odpowiedzi');
    }
    return result;
  }

  static String _extractJson(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return s;
  }
}
