import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class TocScreen extends StatelessWidget {
  final AppState state;
  const TocScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    final sections = state.current.sections;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        const Text(
          'CONTENTS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
            color: Color(0xFF888888),
          ),
        ),
        const Divider(color: Color(0xFFD1CFC9), height: 20),
        for (var bIdx = 0; bIdx < sections.length; bIdx++) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Text(
              displayBookTitle(sections[bIdx].title),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: Color(0xFF888888),
              ),
            ),
          ),
          for (var cIdx = 0; cIdx < sections[bIdx].chapters.length; cIdx++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => state.goTo(state.activeEbook, bIdx, cIdx),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1CFC9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            sections[bIdx].chapters[cIdx].num,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.bold,
                              color: accent.withOpacity(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sections[bIdx].chapters[cIdx].title.isNotEmpty
                                    ? sections[bIdx].chapters[cIdx].title
                                    : 'Chapter ${sections[bIdx].chapters[cIdx].num}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Open',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ]
      ],
    );
  }
}
