import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

class JournalScreen extends StatefulWidget {
  final AppState state;
  const JournalScreen({super.key, required this.state});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _open = false;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    final s = widget.state;
    final section = s.currentSection;
    final chapter = s.currentChapterObj;
    final contextLabel =
        '${displayBookTitle(section.title)} · Chapter ${chapter.num}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'SPIRITUAL JOURNAL',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
              ),
            ),
            if (s.journal.isNotEmpty)
              TextButton(
                onPressed: () => _copyAll(s),
                child: const Text(
                  'COPY ALL',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
          ],
        ),
        const Divider(color: Color(0xFFD1CFC9), height: 20),
        if (!_open)
          OutlinedButton.icon(
            onPressed: () => setState(() => _open = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('NEW REFLECTION',
                style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2).withOpacity(0.5),
              border: Border.all(color: accent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Context: $contextLabel',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _text,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write your prayer, reflection, or resolution…',
                    hintStyle: TextStyle(color: Color(0x661A1A1A), fontFamily: 'Georgia'),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Georgia',
                    height: 1.5,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _open = false;
                        _text.clear();
                      }),
                      child: const Text('CANCEL',
                          style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    ),
                    FilledButton(
                      onPressed: () async {
                        if (_text.text.trim().isEmpty) return;
                        await s.addJournal(_text.text);
                        if (!mounted) return;
                        setState(() {
                          _open = false;
                          _text.clear();
                        });
                      },
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      child: const Text('SAVE',
                          style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (s.journal.isEmpty && !_open)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Column(
              children: [
                Icon(Icons.edit_note, size: 36, color: Color(0xFFAAAAAA)),
                SizedBox(height: 12),
                Text(
                  'Your journal is empty. Save your first reflection or a quote that moved you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                ),
              ],
            ),
          ),
        for (final e in s.journal) _entryCard(e, s),
      ],
    );
  }

  Widget _entryCard(JournalEntry e, AppState s) {
    final eb = s.ebooks[e.ebook]!;
    final sec = (e.book < eb.sections.length) ? eb.sections[e.book] : null;
    final ch = (sec != null && e.chapter < sec.chapters.length)
        ? sec.chapters[e.chapter]
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1CFC9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => s.goTo(e.ebook, e.book, e.chapter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${eb.title} · ${displayBookTitle(sec?.title ?? '')} · Chapter ${ch?.num ?? '?'}',
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmt(e.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFF888888),
                onPressed: () => s.removeJournal(e.id),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.text,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'Georgia',
              height: 1.5,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _copyAll(AppState s) async {
    final buf = StringBuffer('Spiritual Journal\n\n');
    for (final e in s.journal) {
      final eb = s.ebooks[e.ebook]!;
      final sec = (e.book < eb.sections.length) ? eb.sections[e.book] : null;
      final ch = (sec != null && e.chapter < sec.chapters.length)
          ? sec.chapters[e.chapter]
          : null;
      buf.writeln(_fmt(e.createdAt));
      buf.writeln('${eb.title} · ${displayBookTitle(sec?.title ?? '')} · Chapter ${ch?.num ?? '?'}');
      buf.writeln();
      buf.writeln(e.text);
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal copied to clipboard')),
    );
  }
}
