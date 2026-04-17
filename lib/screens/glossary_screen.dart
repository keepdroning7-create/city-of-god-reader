import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class GlossaryScreen extends StatelessWidget {
  final AppState state;
  const GlossaryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    if (state.glossary.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 36, color: Color(0xFFAAAAAA)),
              SizedBox(height: 12),
              Text(
                'Słowniczek jest pusty. Przytrzymaj dowolne słowo w czytniku, aby zapisać jego tłumaczenie.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${state.glossary.length} ${_noun(state.glossary.length)}',
                  style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888888)),
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmClear(context),
                icon: const Icon(Icons.delete_sweep_outlined,
                    size: 16, color: Color(0xFF888888)),
                label: const Text(
                  'WYCZYŚĆ',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888888)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            itemCount: state.glossary.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final g = state.glossary[i];
              return _GlossaryCard(
                entry: g,
                accent: accent,
                onDelete: () => state.removeGlossary(g.word),
              );
            },
          ),
        ),
      ],
    );
  }

  String _noun(int n) {
    if (n == 1) return 'słowo';
    final last = n % 10;
    final lastTwo = n % 100;
    if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
      return 'słowa';
    }
    return 'słów';
  }

  void _confirmClear(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Wyczyścić słowniczek?'),
        content: const Text('Usunie wszystkie zapisane tłumaczenia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C2D12)),
            onPressed: () async {
              await state.clearGlossary();
              if (dctx.mounted) Navigator.of(dctx).pop();
            },
            child: const Text('USUŃ'),
          ),
        ],
      ),
    );
  }
}

class _GlossaryCard extends StatelessWidget {
  final GlossaryEntry entry;
  final Color accent;
  final VoidCallback onDelete;
  const _GlossaryCard({
    required this.entry,
    required this.accent,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1CFC9)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          entry.word,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (entry.ipa != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          entry.ipa!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E6E1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'US',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.translation,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  if (entry.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.note!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: const Color(0xFFAAAAAA),
              tooltip: 'Usuń',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
