import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

class QuoteScreen extends StatefulWidget {
  final AppState state;
  const QuoteScreen({super.key, required this.state});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = '';
  String _meta = '';
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _pick();
  }

  void _pick() {
    final rng = Random();
    final sections = widget.state.current.sections;
    String? text;
    String? meta;
    for (var i = 0; i < 50 && text == null; i++) {
      if (sections.isEmpty) break;
      final b = sections[rng.nextInt(sections.length)];
      if (b.chapters.isEmpty) continue;
      final c = b.chapters[rng.nextInt(b.chapters.length)];
      if (c.paragraphs.isEmpty) continue;
      final p = c.paragraphs[rng.nextInt(c.paragraphs.length)];
      if (p.trim().length < 20) continue;
      text = p.replaceFirst(RegExp(r'^\d+\.\s*'), '');
      meta = '${displayBookTitle(b.title)}, Chapter ${c.num}';
    }
    setState(() {
      _quote = text ?? 'Hardships pass with time; let us learn patience.';
      _meta = meta ?? 'Daily Quote';
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    return Container(
      color: const Color(0xFFE8E6E1),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: accent),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    '"$_quote"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: accent,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _meta,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pick,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(
                                  fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saved
                              ? null
                              : () async {
                                  await widget.state
                                      .addJournal('"$_quote" — $_meta');
                                  setState(() => _saved = true);
                                },
                          style: FilledButton.styleFrom(backgroundColor: accent),
                          icon: const Icon(Icons.edit_note, size: 14),
                          label: Text(_saved ? 'SAVED' : 'TO JOURNAL',
                              style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: '"$_quote" — $_meta'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        child: const Icon(Icons.share, size: 14),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Positioned(
              top: -12,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'QUOTE OF THE DAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
