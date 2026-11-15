import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart'
    show PdfDocument, PdfImage, pdfrxFlutterInitialize;

import '../../errors/exceptions.dart';
import 'pdf_text_cleaning.dart';

class PdfExtractResult {
  final String text;
  final int pageCount;

  final int pagesRead;
  final bool pageLimitReached;
  final bool charLimitReached;

  const PdfExtractResult({
    required this.text,
    required this.pageCount,
    required this.pagesRead,
    required this.pageLimitReached,
    required this.charLimitReached,
  });
}

class PdfTextService {
  PdfTextService._();

  static const int maxPages = 50;
  static const int maxChars = 200000;
  static const int maxFileSizeBytes = 20 * 1024 * 1024;

  static const int ocrMaxPages = 10;

  static const double ocrRenderScale = 2.0;

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await pdfrxFlutterInitialize();
    _initialized = true;
  }

  static Future<PdfExtractResult> extract(
    Uint8List bytes, {
    void Function(int done, int total)? onProgress,
  }) async {
    await ensureInitialized();
    final doc = await PdfDocument.openData(bytes, sourceName: 'document.pdf');
    try {
      final pageCount = doc.pages.length;
      final total = math.min(pageCount, maxPages);
      final buffer = StringBuffer();

      for (var i = 0; i < total; i++) {
        final raw = await doc.pages[i].loadText();
        if (raw != null && raw.fullText.isNotEmpty) {
          buffer.writeln(raw.fullText);
        }
        onProgress?.call(i + 1, total);

        await Future<void>.delayed(Duration.zero);
      }

      final cleaned = PdfTextCleaner.clean(buffer.toString());
      final charLimitReached = cleaned.length > maxChars;

      return PdfExtractResult(
        text: charLimitReached ? cleaned.substring(0, maxChars) : cleaned,
        pageCount: pageCount,
        pagesRead: total,
        pageLimitReached: pageCount > maxPages,
        charLimitReached: charLimitReached,
      );
    } on BesbasaException {
      rethrow;
    } catch (e) {
      throw PdfOpenException(e.toString());
    } finally {
      await doc.dispose();
    }
  }

  static Future<List<Uint8List>> renderPagesToPng(
    Uint8List bytes, {
    int maxPages = ocrMaxPages,
    double scale = ocrRenderScale,
    void Function(int done, int total)? onProgress,
  }) async {
    await ensureInitialized();
    final doc = await PdfDocument.openData(bytes, sourceName: 'document.pdf');
    final results = <Uint8List>[];
    try {
      final total = math.min(doc.pages.length, maxPages);
      for (var i = 0; i < total; i++) {
        final page = doc.pages[i];
        final fullWidth = (page.width * scale).round().toDouble();
        final fullHeight = (page.height * scale).round().toDouble();
        final image = await page.render(
          fullWidth: fullWidth,
          fullHeight: fullHeight,
        );
        if (image != null) {
          final png = await _encodePng(image);
          if (png != null) results.add(png);
          image.dispose();
        }
        onProgress?.call(i + 1, total);
        await Future<void>.delayed(Duration.zero);
      }
    } catch (e) {
      throw PdfOpenException(e.toString());
    } finally {
      await doc.dispose();
    }
    return results;
  }

  static Future<Uint8List?> _encodePng(PdfImage image) async {
    final rgba = kIsWeb ? image.pixels : _bgraToRgba(image.pixels);
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    try {
      final codec = await descriptor.instantiateCodec();
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          return data?.buffer.asUint8List();
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
      buffer.dispose();
    }
  }

  static Uint8List _bgraToRgba(Uint8List bgra) {
    final rgba = Uint8List(bgra.length);
    for (var i = 0; i + 3 < bgra.length; i += 4) {
      rgba[i] = bgra[i + 2];
      rgba[i + 1] = bgra[i + 1];
      rgba[i + 2] = bgra[i];
      rgba[i + 3] = bgra[i + 3];
    }
    return rgba;
  }
}
