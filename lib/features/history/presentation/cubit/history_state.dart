import 'package:equatable/equatable.dart';

import '../../data/models/summary_model.dart';

class HistoryState extends Equatable {
  final List<SummaryModel> entries;

  final String query;

  final String? toast;

  const HistoryState({this.entries = const [], this.query = '', this.toast});

  List<SummaryModel> get filtered {
    if (query.trim().isEmpty) return entries;
    return entries.where((e) => e.matches(query)).toList();
  }

  HistoryState copyWith({
    List<SummaryModel>? entries,
    String? query,
    String? toast,
    bool clearToast = false,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      query: query ?? this.query,
      toast: clearToast ? null : (toast ?? this.toast),
    );
  }

  @override
  List<Object?> get props => [entries, query, toast];
}
