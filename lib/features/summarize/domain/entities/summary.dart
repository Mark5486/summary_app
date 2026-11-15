import '../../../../core/summarizer/extractive_summarizer.dart';

export '../../../../core/summarizer/extractive_summarizer.dart'
    show SummaryResult;

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
