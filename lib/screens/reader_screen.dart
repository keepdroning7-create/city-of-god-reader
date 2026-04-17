import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/translatable_text.dart';

class ReaderScreen extends StatefulWidget {
  final AppState state;
  const ReaderScreen({super.key, required this.state});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _journalOpen = false;
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final section = s.currentSection;
    final chapter = s.currentChapterObj;
    const accent = Color(0xFF7C2D12);
    final textColor = s.dark ? const Color(0xFFE8E6E1) : const Color(0xFF1A1A1A);

    return ListView(
      key: ValueKey('read-${s.activeEbook.name}-${s.currentBook}-${s.currentChapter}'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
      children: [
        InkWell(
          onTap: () => _showSectionPicker(s),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  displayBookTitle(section.title).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF888888)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showChapterPicker(s),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'Chapter ${chapter.num}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 24, color: accent),
              ],
            ),
          ),
        ),
        if (chapter.title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            chapter.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFD1CFC9), height: 1),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Tip: long-press any word for a contextual Polish translation.',
            style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 16),
        for (final p in chapter.paragraphs) ...[
          TranslatableText(
            text: p,
            style: TextStyle(
              fontSize: 17 * s.fontScale,
              fontFamily: 'Georgia',
              height: 1.6,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
        ],
        const SizedBox(height: 12),
        _journalOpen ? _journalDraft(s) : _journalButton(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(
              label: 'Previous',
              icon: Icons.chevron_left,
              leading: true,
              enabled: s.hasPrev,
              onTap: s.hasPrev ? s.prev : null,
            ),
            _navBtn(
              label: 'Next',
              icon: Icons.chevron_right,
              leading: false,
              enabled: s.hasNext,
              onTap: s.hasNext ? s.next : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showSectionPicker(AppState s) {
    const accent = Color(0xFF7C2D12);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1CFC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('JUMP TO BOOK',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888888))),
            const Divider(color: Color(0xFFD1CFC9), height: 16),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: s.current.sections.length,
                itemBuilder: (_, i) {
                  final sec = s.current.sections[i];
                  final selected = i == s.currentBook;
                  return ListTile(
                    dense: true,
                    selected: selected,
                    selectedTileColor: const Color(0xFFFEF2F2),
                    leading: SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.bold,
                          color: selected ? accent : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                    title: Text(
                      displayBookTitle(sec.title),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: selected ? accent : null,
                      ),
                    ),
                    subtitle: Text(
                      '${sec.chapters.length} chapters',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      s.goTo(s.activeEbook, i, 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterPicker(AppState s) {
    const accent = Color(0xFF7C2D12);
    final section = s.currentSection;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1CFC9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${displayBookTitle(section.title).toUpperCase()} — CHAPTERS',
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888888)),
              ),
              const Divider(color: Color(0xFFD1CFC9), height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: section.chapters.length,
                  itemBuilder: (_, i) {
                    final c = section.chapters[i];
                    final selected = i == s.currentChapter;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: const Color(0xFFFEF2F2),
                      leading: SizedBox(
                        width: 40,
                        child: Text(
                          c.num,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.bold,
                            color: selected ? accent : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                      title: Text(
                        c.title.isNotEmpty ? c.title : 'Chapter ${c.num}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? accent : null,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        s.goTo(s.activeEbook, s.currentBook, i);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _journalButton() {
    const accent = Color(0xFF7C2D12);
    return OutlinedButton.icon(
      onPressed: () => setState(() => _journalOpen = true),
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.edit_note, size: 18),
      label: const Text(
        'ADD REFLECTION TO JOURNAL',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _journalDraft(AppState s) {
    const accent = Color(0xFF7C2D12);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2).withOpacity(0.5),
        border: Border.all(color: accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _draft,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'What stirred you in this chapter?',
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
                  _journalOpen = false;
                  _draft.clear();
                }),
                child: const Text('CANCEL',
                    style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _draft.text.trim().isEmpty
                    ? null
                    : () async {
                        await s.addJournal(_draft.text);
                        if (!mounted) return;
                        setState(() {
                          _journalOpen = false;
                          _draft.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to journal')),
                        );
                      },
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: const Text('SAVE',
                    style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required String label,
    required IconData icon,
    required bool leading,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final color = enabled ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
            color: enabled ? const Color(0xFFD1CFC9) : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading) Icon(icon, size: 16),
          if (leading) const SizedBox(width: 4),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
          if (!leading) const SizedBox(width: 4),
          if (!leading) Icon(icon, size: 16),
        ],
      ),
    );
  }
}
