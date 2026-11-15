# Besbasa | ببساطة

**Summarize any text in one tap — paste it, open a TXT or PDF file, or snap a photo of the page. You get a few key points and a simple explanation. Fully offline.**

![Flutter](https://img.shields.io/badge/Flutter-3.35%2B-02569B?logo=flutter&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20Web%20%7C%20Windows-4CAF50)
![Offline](https://img.shields.io/badge/Offline--first-100%25-FF7043)
[![CI](https://github.com/Mark5486/summary_app/actions/workflows/ci.yml/badge.svg)](https://github.com/Mark5486/summary_app/actions/workflows/ci.yml)

Besbasa is an offline-first text summarizer: it picks the most important sentences from your text and explains them simply — with no internet, no server, and no data ever leaving your device. Arabic and English supported.

## The Idea

Paste any long text (a lesson, an article, a report), open a `.txt` or `.pdf` file, or capture a page with the camera — Besbasa returns **a few key points** (the top 3–5 sentences) plus a **simple explanation** with the most frequent keywords. Everything happens inside the app.

## Features

- **Three input modes** — paste text, open TXT/CSV/MD files, read PDFs (with OCR fallback for scanned pages), or capture a page with the camera on mobile and web.
- **Extractive summarizer engine** — pure Dart, 100% offline: word-frequency scoring with sentence positions, length penalty, and an opening-sentence bonus; returns 3–5 points in the original order.
- **Original text preserved** — summary points show the sentence exactly as written, diacritics (تشكيل) and punctuation included.
- **Simple explanation** — the core idea plus the top keywords, written in the language of the text itself.
- **Reading history** — every summary is saved locally with instant search and one-tap delete.
- **Bilingual & responsive** — Arabic-first UI (RTL) with full English support, adaptive layout from phones to desktop windows, dark mode included.

## Libraries

| Package | Purpose |
|---|---|
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | State management with the Cubit pattern |
| [`get_it`](https://pub.dev/packages/get_it) | Dependency injection (Service Locator) |
| [`dartz`](https://pub.dev/packages/dartz) | Functional error handling with `Either` |
| [`equatable`](https://pub.dev/packages/equatable) | Value comparison for state objects |
| [`uuid`](https://pub.dev/packages/uuid) | IDs for saved summaries |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Local storage (history, theme, language) |
| [`file_picker`](https://pub.dev/packages/file_picker) | Picking TXT / PDF files |
| [`pdfrx`](https://pub.dev/packages/pdfrx) | PDF text extraction |
| [`camera`](https://pub.dev/packages/camera) | Camera capture for OCR |
| [`flutter_tesseract_ocr`](https://pub.dev/packages/flutter_tesseract_ocr) | On-device text recognition — fully offline, Arabic data bundled |
| [`path_provider`](https://pub.dev/packages/path_provider) | Temp files for OCR images |

## Architecture

The project follows **Clean Architecture** with every feature isolated in its own module:

```
lib/
├── core/
│   ├── summarizer/      # The extraction engine — pure Dart, no Flutter needed
│   ├── services/        # File reading, PDF pipeline, OCR, type detection
│   ├── localization/    # Arabic / English strings + locale cubit
│   ├── theme/           # Light & dark themes + theme cubit
│   ├── di/              # Service locator wiring
│   └── errors/          # Failures & exceptions
└── features/
    ├── summarize/       # Input, capture, and the result screen
    ├── history/         # Saved summaries + search
    └── settings/        # Theme & language
```

Each feature is internally split into: `presentation` (UI & state) ← `domain` (business logic) ← `data` (data sources & storage).

## Getting Started

```bash
# Requirements: Flutter 3.35 or newer (Dart 3.9+)
flutter pub get
flutter run
```

Supported platforms: **Android, Web, Windows**.

## Tests

```bash
flutter test
```

The suite covers the summarizer engine, file decoding (UTF-8 / UTF-16 / Windows-1256 with BOM handling), file-type detection, Cubits, and the PDF pipeline.

## CI

Every push runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml): `flutter analyze` (zero warnings enforced), `flutter test --coverage` (report available in Artifacts), and on pushes to `main` — debug APK + web builds as downloadable artifacts.
