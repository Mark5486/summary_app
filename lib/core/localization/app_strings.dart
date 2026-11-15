import 'package:flutter/material.dart';

/// كل نصوص التطبيق عربي + إنجليزي.
/// الاستخدام: AppStrings.of(context).summarize
///
/// الاختيار بيحصل من لغة الـ MaterialApp الحالية — اللي بتتحكم فيها
/// LocaleCubit وبتتحفظ محليًا. العربي هو الافتراضي.
class AppStrings {
  final Locale locale;

  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  bool get isArabic => locale.languageCode == 'ar';

  // ───────────────────────── التطبيق ─────────────────────────
  String get appName => isArabic ? 'ببساطة' : 'Besbasa';
  String get appTagline =>
      isArabic ? 'أي منهج… ببساطة شديدة' : 'Any material… made simple';

  // ───────────────────────── التبويبات ─────────────────────────
  String get tabSummarize => isArabic ? 'تلخيص' : 'Summarize';
  String get tabHistory => isArabic ? 'السجل' : 'History';
  String get tabSettings => isArabic ? 'الإعدادات' : 'Settings';

  // ───────────────────────── شاشة التلخيص ─────────────────────────
  String get inputHint =>
      isArabic ? 'الصق النص هنا… أو افتح ملف أو صوّر صفحة' : 'Paste text here… or open a file or capture a page';
  String get summarizeButton => isArabic ? 'لخّصه ببساطة' : 'Summarize simply';
  String get clearButton => isArabic ? 'مسح' : 'Clear';
  String get openFile => isArabic ? 'ملف' : 'File';
  String get camera => isArabic ? 'كاميرا' : 'Camera';
  String get words => isArabic ? 'كلمة' : 'words';
  String get textTruncated => isArabic
      ? 'النص كبير جدًا — اتحمّل أول 200 ألف حرف بس عشان السرعة'
      : 'Text is too large — only the first 200,000 characters were loaded';
  String get pointsTitle => isArabic ? 'أهم النقاط' : 'Key points';
  String get explanationTitle => isArabic ? 'شرح مبسط' : 'Simple explanation';
  String get copySummary => isArabic ? 'نسخ الملخص' : 'Copy summary';
  String get copied => isArabic ? 'تم النسخ ✓' : 'Copied ✓';
  String get compressionLabel => isArabic ? 'الاختصار' : 'Compression';
  String get originalLabel => isArabic ? 'الأصل' : 'Original';

  // ───────────────────────── النتيجة على الهوم ─────────────────────────
  String get resultTitle => isArabic ? 'النتيجة' : 'Result';
  String get savedToHistory =>
      isArabic ? 'محفوظ في السجل ✓' : 'Saved to history ✓';
  String get lastSummaryTitle =>
      isArabic ? 'آخر ملخص من السجل' : 'Last summary from history';
  String get removeFromHome =>
      isArabic ? 'مسح من الهوم' : 'Clear from home';

  String get inputTooShort => isArabic
      ? 'النص قصير أوي — محتاج 30 كلمة على الأقل عشان ألخصه بمعنى.'
      : 'The text is too short — at least 30 words are needed to summarize meaningfully.';

  String get invalidFile => isArabic
      ? 'الملف ده مش ملف نصي ولا PDF — الملفات الثنائية (Word/صور/ضغط) مش مدعومة أوفلاين.'
      : 'This is not a text or PDF file — binary files (Word/images/archives) are not supported offline.';

  String get fileTooLarge => isArabic
      ? 'الملف أكبر من 20 ميجا — جرّب ملف أصغر.'
      : 'The file is larger than 20 MB — try a smaller file.';

  String get pdfOpenFailed => isArabic
      ? 'مقدرتش أفتح ملف الـ PDF — الملف ممكن يكون بايظ أو محمي بكلمة سر.'
      : 'Could not open the PDF — it may be corrupted or password-protected.';

  // ───────────────────────── بطاقة معلومات الملف ─────────────────────────
  String pdfExtracted(int words, int pages) {
    if (isArabic) {
      if (pages == 1) return 'تم استخراج $words كلمة من صفحة واحدة';
      return 'تم استخراج $words كلمة من $pages صفحة';
    }
    return pages == 1
        ? 'Extracted $words words from 1 page'
        : 'Extracted $words words from $pages pages';
  }

  String txtLoaded(int words) => isArabic
      ? 'تم تحميل ملف نصي — $words كلمة'
      : 'Text file loaded — $words words';

  String ocrExtracted(int words) => isArabic
      ? 'تم استخراج $words كلمة بالـ OCR من صور الملف'
      : 'Extracted $words words via OCR from the file images';

  String get pdfPagesLimited => isArabic
      ? 'اتقرا أول 50 صفحة بس عشان السرعة'
      : 'Only the first 50 pages were read for speed';

  String get pdfCharLimited => isArabic
      ? 'اتلخص أول 200 ألف حرف بس عشان السرعة'
      : 'Only the first 200,000 characters are summarized for speed';

  String get scannedPdf => isArabic
      ? 'الملف ده PDF ممسوح ضوئيًا (صفحات صور) — مفيش نص جواه يتستخرج مباشرة.'
      : 'This PDF is scanned (image pages) — there is no text to extract directly.';

  String get runOcr => isArabic ? 'تشغيل OCR على صفحات الملف' : 'Run OCR on the pages';

  String get previewNote => isArabic
      ? 'معاينة أول 2000 حرف بس — التلخيص هيتم على النص الكامل.'
      : 'Preview of the first 2,000 characters — summarizing uses the full text.';

  String get filePickCancelled =>
      isArabic ? 'لغيت اختيار الملف.' : 'File selection cancelled.';

  String get noTextFound => isArabic
      ? 'مفيش نص واضح في الصورة — قرّب الكاميرا وحسّن الإضاءة وجرّب تاني.'
      : 'No clear text found in the image — move closer, improve lighting, and try again.';

  String get recognitionFailed => isArabic
      ? 'حصلت مشكلة في قراءة الصورة — جرّب تاني.'
      : 'Something went wrong reading the image — try again.';

  String get cameraNotSupported => isArabic
      ? 'التصوير مدعوم على الموبايل والويب بس — على ويندوز الصق النص أو افتح ملف.'
      : 'Camera is supported on mobile and web only — on Windows, paste text or open a file.';

  String get unexpected => isArabic
      ? 'حصل حاجة غير متوقعة — جرّب تاني.'
      : 'Something unexpected happened — try again.';

  String get emptyInput => isArabic
      ? 'اكتب أو الصق نص الأول 🙂'
      : 'Type or paste some text first 🙂';

  // ───────────────────────── شاشة الكاميرا ─────────────────────────
  String get captureTitle => isArabic ? 'صوّر الصفحة' : 'Capture page';
  String get captureButton => isArabic ? 'تصوير' : 'Capture';
  String get cameraPermissionDenied => isArabic
      ? 'صلاحية الكاميرا مرفوضة — افتح إعدادات النظام واسمح بيها.'
      : 'Camera permission denied — open system settings and allow it.';

  // ───────────────────────── السجل ─────────────────────────
  String get historyTitle => isArabic ? 'سجل الملخصات' : 'Summary history';
  String get searchHint => isArabic ? 'ابحث في السجل…' : 'Search history…';
  String get historyEmpty => isArabic
      ? 'لسه مفيش ملخصات — لخّص أول نص ودّي هيتحفظ هنا.'
      : 'No summaries yet — summarize your first text and it will be saved here.';
  String get noSearchResults =>
      isArabic ? 'مفيش نتائج للبحث ده.' : 'No results for this search.';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get deleted => isArabic ? 'اتحذف ✓' : 'Deleted ✓';
  String get clearAll => isArabic ? 'مسح الكل' : 'Clear all';
  String get clearAllConfirm => isArabic
      ? 'تمسح كل الملخصات المحفوظة؟'
      : 'Delete all saved summaries?';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get confirm => isArabic ? 'أيوه امسح' : 'Yes, delete';

  // ───────────────────────── الإعدادات ─────────────────────────
  String get settingsTitle => isArabic ? 'الإعدادات' : 'Settings';
  String get darkMode => isArabic ? 'الوضع الغامق' : 'Dark mode';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'الإنجليزية' : 'English';
}
