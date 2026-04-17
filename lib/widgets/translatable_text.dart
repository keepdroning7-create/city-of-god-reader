import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translate_service.dart';

/// Paragraph of text where each word can be long-pressed
/// to show its contextual Polish translation.
class TranslatableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final void Function(String word, TranslationResult result)? onTranslated;
  const TranslatableText({
    super.key,
    required this.text,
    this.style,
    this.onTranslated,
  });

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  final List<LongPressGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final re = RegExp(r"[A-Za-z'’\-]+|[^A-Za-z'’\-]+");
    final spans = <InlineSpan>[];

    for (final m in re.allMatches(widget.text)) {
      final t = m.group(0)!;
      final isWord = RegExp(r'[A-Za-z]').hasMatch(t);
      if (isWord) {
        final rec = LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 350))
          ..onLongPress = () => _onLongPress(t);
        _recognizers.add(rec);
        spans.add(TextSpan(text: t, recognizer: rec));
      } else {
        spans.add(TextSpan(text: t));
      }
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }

  void _onLongPress(String raw) {
    final clean = raw.replaceAll(RegExp(r"[^A-Za-z'’\-]"), '').trim();
    if (clean.isEmpty) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TranslationSheet(
        word: clean,
        context: widget.text,
        onTranslated: widget.onTranslated,
      ),
    );
  }
}

class _TranslationSheet extends StatefulWidget {
  final String word;
  final String context;
  final void Function(String word, TranslationResult result)? onTranslated;
  const _TranslationSheet({
    required this.word,
    required this.context,
    this.onTranslated,
  });

  @override
  State<_TranslationSheet> createState() => _TranslationSheetState();
}

class _TranslationSheetState extends State<_TranslationSheet> {
  TranslationResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await TranslateService.translate(
        word: widget.word,
        context: widget.context,
      );
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
      widget.onTranslated?.call(widget.word, r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1CFC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('EN',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
              )),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(widget.word,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    )),
              ),
              if (_result?.ipa != null) ...[
                const SizedBox(width: 10),
                Text(_result!.ipa!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontFamily: 'Georgia',
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E6E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('US',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFD1CFC9)),
          const SizedBox(height: 16),
          const Text('PL',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: accent,
              )),
          const SizedBox(height: 4),
          if (_loading)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                SizedBox(width: 10),
                Text('Translating with paragraph context…',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              ],
            ),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (_result != null) ...[
            Text(_result!.translation,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Georgia',
                  color: accent,
                  fontWeight: FontWeight.w600,
                )),
            if (_result!.note != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result!.note!,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1A1A1A),
                        height: 1.45)),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Text(
            _result != null
                ? 'Source: ${_result!.source}'
                : 'Source: Google Gemini (2.5 Flash) — translated with full paragraph context',
            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}
