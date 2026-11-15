import '../../../../core/summarizer/extractive_summarizer.dart';

/// موديل التخزين — نفس حقول Summary لكن قابل للتحويل JSON محليًا.
class SummaryModel {
  final String id;
  final int createdAtMs;
  final String originalText;
  final List<String> points;
  final String explanation;
  final List<String> keywords;
  final int originalWordCount;
  final int summaryWordCount;

  const SummaryModel({
    required this.id,
    required this.createdAtMs,
    required this.originalText,
    required this.points,
    required this.explanation,
    required this.keywords,
    required this.originalWordCount,
    required this.summaryWordCount,
  });

  /// ⚡ السجل بيخزن أول 300 حرف من النص الأصلي بس — النص الكامل مش
  /// محتاجينه بعد التلخيص، وده بيخلي التخزين خفيف وسريع (ريفيو:
  /// كان التخزين بينفخ من 0.4 لـ 3.4 ميجا ويقرّب من حد localStorage).
  static const int maxStoredChars = 300;

  static String _trimForStorage(String text) => text.length <= maxStoredChars
      ? text
      : '${text.substring(0, maxStoredChars)}…';

  /// نسخة مقصوصة للتخزين — بتتستخدم في تنظيف الإدخالات القديمة.
  SummaryModel trimmedForStorage() => SummaryModel(
        id: id,
        createdAtMs: createdAtMs,
        originalText: _trimForStorage(originalText),
        points: points,
        explanation: explanation,
        keywords: keywords,
        originalWordCount: originalWordCount,
        summaryWordCount: summaryWordCount,
      );

  factory SummaryModel.fromSummary(String id, DateTime createdAt,
      String originalText, SummaryResult result) {
    return SummaryModel(
      id: id,
      createdAtMs: createdAt.millisecondsSinceEpoch,
      originalText: _trimForStorage(originalText),
      points: result.points,
      explanation: result.explanation,
      keywords: result.keywords,
      originalWordCount: result.originalWordCount,
      summaryWordCount: result.summaryWordCount,
    );
  }

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      id: json['id'] as String,
      createdAtMs: json['createdAtMs'] as int,
      originalText: json['originalText'] as String? ?? '',
      points:
          (json['points'] as List<dynamic>? ?? const []).cast<String>().toList(),
      explanation: json['explanation'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(),
      originalWordCount: json['originalWordCount'] as int? ?? 0,
      summaryWordCount: json['summaryWordCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAtMs': createdAtMs,
        'originalText': originalText,
        'points': points,
        'explanation': explanation,
        'keywords': keywords,
        'originalWordCount': originalWordCount,
        'summaryWordCount': summaryWordCount,
      };

  /// بحث نصي بسيط في الأصل والنقاط والشرح — محلي بالكامل.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (originalText.toLowerCase().contains(q)) return true;
    if (explanation.toLowerCase().contains(q)) return true;
    for (final p in points) {
      if (p.toLowerCase().contains(q)) return true;
    }
    for (final k in keywords) {
      if (k.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
