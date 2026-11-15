import '../../../../core/summarizer/extractive_summarizer.dart';

export '../../../../core/summarizer/extractive_summarizer.dart'
    show SummaryResult;

/// كيان الملخص — نقاط قليلة + شرح مبسط + النص الأصلي للعرض والبحث.
class Summary {
  final String id;
  final DateTime createdAt;
  final String originalText;
  final SummaryResult result;

  const Summary({
    required this.id,
    required this.createdAt,
    required this.originalText,
    required this.result,
  });
}
