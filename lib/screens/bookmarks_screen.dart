import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class BookmarksScreen extends StatelessWidget {
  final AppState state;
  const BookmarksScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    if (state.bookmarks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border, size: 36, color: Color(0xFFAAAAAA)),
              SizedBox(height: 12),
              Text(
                'No bookmarks yet. In reading mode, tap the bookmark icon at the top of the screen to save a chapter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      itemCount: state.bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final bm = state.bookmarks[i];
        final eb = state.ebooks[bm.ebook]!;
        final sec = (bm.book < eb.sections.length) ? eb.sections[bm.book] : null;
        final ch = (sec != null && bm.chapter < sec.chapters.length)
            ? sec.chapters[bm.chapter]
            : null;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => state.goTo(bm.ebook, bm.book, bm.chapter),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1CFC9)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${eb.title} · ${displayBookTitle(sec?.title ?? '')}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Chapter ${ch?.num ?? '?'} — ${bm.label}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtDate(bm.createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFF888888),
                    onPressed: () => state.removeBookmark(i),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
