import 'package:flutter/material.dart';
import 'app_state.dart';
import 'services/storage_service.dart';
import 'screens/reader_screen.dart';
import 'screens/quote_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/glossary_screen.dart';
import 'screens/toc_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  final state = AppState(storage);
  await state.loadAll();
  runApp(MyApp(state: state));
}

class MyApp extends StatelessWidget {
  final AppState state;
  const MyApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        const accent = Color(0xFF7C2D12);
        final light = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFDFBF7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent,
            brightness: Brightness.light,
          ),
          fontFamily: 'Helvetica Neue',
          dividerColor: const Color(0xFFD1CFC9),
        );
        final dark = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Helvetica Neue',
          dividerColor: const Color(0xFF333333),
        );
        return MaterialApp(
          title: 'The City of God',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
          home: Home(state: state),
        );
      },
    );
  }
}

class Home extends StatelessWidget {
  final AppState state;
  const Home({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    final eb = state.current;

    Widget body;
    if (state.showToc) {
      body = TocScreen(state: state);
    } else {
      switch (state.navIndex) {
        case 1:
          body = QuoteScreen(
            key: ValueKey('q-${state.activeEbook.name}'),
            state: state,
          );
          break;
        case 2:
          body = BookmarksScreen(state: state);
          break;
        case 3:
          body = JournalScreen(state: state);
          break;
        case 4:
          body = GlossaryScreen(state: state);
          break;
        default:
          body = ReaderScreen(state: state);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            state.dark ? const Color(0xFF121212) : const Color(0xFFFDFBF7),
        foregroundColor:
            state.dark ? const Color(0xFFE8E6E1) : const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        leading: state.navIndex == 0 && !state.showToc
            ? IconButton(
                icon: Icon(
                  state.isCurrentBookmarked()
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: state.isCurrentBookmarked() ? accent : null,
                ),
                onPressed: state.toggleBookmark,
                tooltip: state.isCurrentBookmarked()
                    ? 'Remove bookmark'
                    : 'Add bookmark',
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eb.title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            Text(
              eb.author.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFD1CFC9)),
        ),
      ),
      endDrawer: _drawer(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.navIndex.clamp(0, 4),
        onDestinationSelected: state.setNav,
        indicatorColor: accent.withOpacity(0.1),
        backgroundColor:
            state.dark ? const Color(0xFF1A1A1A) : Colors.white,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: accent),
            label: 'Read',
          ),
          const NavigationDestination(
            icon: Icon(Icons.format_quote_outlined),
            selectedIcon: Icon(Icons.format_quote, color: accent),
            label: 'Quote',
          ),
          NavigationDestination(
            icon: _badged(
                const Icon(Icons.bookmark_border), state.bookmarks.length),
            selectedIcon:
                _badged(const Icon(Icons.bookmark, color: accent), state.bookmarks.length),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: _badged(const Icon(Icons.edit_note_outlined), state.journal.length),
            selectedIcon:
                _badged(const Icon(Icons.edit_note, color: accent), state.journal.length),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: _badged(
                const Icon(Icons.translate), state.glossary.length),
            selectedIcon: _badged(
                const Icon(Icons.translate, color: accent),
                state.glossary.length),
            label: 'Glossary',
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _badged(Icon icon, int count) {
    if (count <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF7C2D12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _drawer(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    return Drawer(
      backgroundColor: state.dark ? const Color(0xFF1A1A1A) : Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MENU',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888888),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(color: Color(0xFFD1CFC9)),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Color(0xFF888888)),
                title: const Text('Contents'),
                onTap: () {
                  Navigator.of(context).pop();
                  state.openToc();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: Color(0xFF888888)),
                title: Text('Bookmarks (${state.bookmarks.length})'),
                onTap: () {
                  Navigator.of(context).pop();
                  state.setNav(2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Color(0xFF888888)),
                title: Text('Spiritual Journal (${state.journal.length})'),
                onTap: () {
                  Navigator.of(context).pop();
                  state.setNav(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate, color: Color(0xFF888888)),
                title: Text('Glossary (${state.glossary.length})'),
                onTap: () {
                  Navigator.of(context).pop();
                  state.setNav(4);
                },
              ),
              const Divider(color: Color(0xFFD1CFC9)),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4, bottom: 6),
                child: Text(
                  'LIBRARY',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              _ebookTile(context, EbookId.city),
              const SizedBox(height: 6),
              _ebookTile(context, EbookId.imitation),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFD1CFC9)),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4, bottom: 6),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1CFC9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields, size: 16, color: Color(0xFF888888)),
                    const SizedBox(width: 10),
                    const Text('Text size', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () =>
                          state.setFontScale(state.fontScale - 0.1),
                    ),
                    Text('${(state.fontScale * 100).round()}%',
                        style: const TextStyle(fontSize: 11)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          state.setFontScale(state.fontScale + 0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                secondary: Icon(state.dark ? Icons.light_mode : Icons.dark_mode,
                    color: const Color(0xFF888888)),
                title: Text(state.dark ? 'Light mode' : 'Dark mode'),
                value: state.dark,
                activeColor: accent,
                onChanged: state.setDark,
              ),
              const SizedBox(height: 8),
              _geminiKeyTile(context),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    const Divider(color: Color(0xFFD1CFC9)),
                    const SizedBox(height: 8),
                    Text(state.current.title,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Color(0xFF888888))),
                    Text(state.current.author,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Color(0xFF888888))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ebookTile(BuildContext context, EbookId id) {
    const accent = Color(0xFF7C2D12);
    final eb = state.ebooks[id];
    if (eb == null) return const SizedBox.shrink();
    final active = state.activeEbook == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await state.switchEbook(id);
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: active ? accent : const Color(0xFFD1CFC9),
                width: active ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
            color: active
                ? accent.withOpacity(0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.check_circle : Icons.menu_book_outlined,
                size: 18,
                color: active ? accent : const Color(0xFF888888),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eb.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w600,
                        color: active ? accent : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eb.author,
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _geminiKeyTile(BuildContext context) {
    const accent = Color(0xFF7C2D12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1CFC9)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.translate,
              size: 16,
              color: state.geminiKey == null
                  ? const Color(0xFFAAAAAA)
                  : accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gemini Key',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  state.geminiKey == null
                      ? 'default app key'
                      : 'custom key (•••${state.geminiKey!.substring(state.geminiKey!.length - 4)})',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showGeminiKeyDialog(context),
            child: Text(state.geminiKey == null ? 'SET' : 'CHANGE',
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGeminiKeyDialog(BuildContext ctx) {
    final controller = TextEditingController(text: state.geminiKey ?? '');
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get a key at aistudio.google.com/apikey (free tier). '
              'The key is stored locally in this browser.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: 'AIza…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () async {
                await state.setGeminiKey('');
                if (dctx.mounted) Navigator.of(dctx).pop();
              },
              child: const Text('CLEAR')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C2D12)),
              onPressed: () async {
                await state.setGeminiKey(controller.text);
                if (dctx.mounted) Navigator.of(dctx).pop();
              },
              child: const Text('SAVE')),
        ],
      ),
    );
  }
}
