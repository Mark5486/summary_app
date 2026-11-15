import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/history_usecases.dart';
import 'history_state.dart';

/// عقل شاشة السجل: تحميل + بحث + حذف + مسح الكل.
class HistoryCubit extends Cubit<HistoryState> {
  final GetHistoryUseCase getHistoryUseCase;
  final DeleteSummaryUseCase deleteSummaryUseCase;
  final ClearHistoryUseCase clearHistoryUseCase;

  HistoryCubit({
    required this.getHistoryUseCase,
    required this.deleteSummaryUseCase,
    required this.clearHistoryUseCase,
  }) : super(const HistoryState());

  /// تحميل السجل من التخزين المحلي — بينادى أول ما التبويب يفتح.
  Future<void> load() async {
    final result = await getHistoryUseCase();
    result.fold(
      (_) => emit(state.copyWith(entries: const [])),
      (entries) => emit(state.copyWith(entries: entries)),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> delete(String id) async {
    final result = await deleteSummaryUseCase(id);
    result.fold(
      // التخزين المحلي عمليًا ما بيرميش — Left يعني حاجة نادرة جدًا،
      // بنسيب الحالة زي ما هي بدل ما نكسر الواجهة.
      (_) {},
      (_) {
        // تحديث محلي متفائل — إحنا مصدر الحقيقة (التخزين) اتحذف منه بالفعل.
        final updated = state.entries.where((e) => e.id != id).toList();
        emit(state.copyWith(entries: updated, toast: 'deleted'));
      },
    );
  }

  Future<void> clearAll() async {
    await clearHistoryUseCase();
    emit(state.copyWith(entries: const [], query: '', toast: 'deleted'));
  }

  void consumeToast() => emit(state.copyWith(clearToast: true));
}
