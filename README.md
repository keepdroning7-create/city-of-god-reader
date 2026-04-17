# O Naśladowaniu — Flutter

Czytnik e-booków *O naśladowaniu Chrystusa* (Tomasz à Kempis) oraz *Państwo Boże* (św. Augustyn) z:

- **Długie przytrzymanie słowa** → tłumaczenie EN → PL (MyMemory API, bez klucza)
- **Zakładki** na poziomie rozdziału z powrotem jednym tapnięciem
- **Dziennik duchowy** z refleksjami przypisanymi do rozdziału
- **Cytat dnia** z zapisem do dziennika i udostępnianiem
- **Spis treści**, regulacja wielkości tekstu, tryb ciemny

## Setup

Wymagany Flutter SDK ≥ 3.19. Jeśli nie masz, zainstaluj: https://docs.flutter.dev/get-started/install/windows

W tym folderze (`flutter_app/`):

```bash
flutter create .            # generuje platformy (android/, ios/, windows/...) bez nadpisywania lib/
flutter pub get
flutter run                 # wybierz urządzenie / emulator
```

Dla web/Chromium:

```bash
flutter run -d chrome
```

Do zbudowania paczki Windows:

```bash
flutter build windows
```

## Jak działa tłumaczenie

W trybie Czytaj przytrzymaj dowolne słowo ~350 ms — pojawi się arkusz z oryginalnym słowem i jego tłumaczeniem na polski. Wyniki są cache'owane w pamięci procesu dla szybszych powtórnych wywołań. API: `https://api.mymemory.translated.net/get` (fair-use, bez klucza).

## Struktura

- `lib/main.dart` — boot, shell nawigacyjny, drawer z ustawieniami
- `lib/app_state.dart` — `ChangeNotifier` z pozycją, zakładkami, dziennikiem
- `lib/widgets/translatable_text.dart` — akapit z per-słowo long-pressem
- `lib/services/translate_service.dart` — klient MyMemory
- `lib/services/storage_service.dart` — `SharedPreferences`
- `lib/screens/*.dart` — Reader / Quote / Bookmarks / Journal / TOC
- `assets/kempis.json`, `assets/city.json` — teksty (kopie z `src/`)
