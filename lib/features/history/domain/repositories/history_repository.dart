import '../../data/models/summary_model.dart';

/// واجهة مستودع السجل — طبقة الدومين (تعتمد على الموديل المشترك).
abstract class HistoryRepository {
  Future<List<SummaryModel>> getAll();

  /// آخر ملخص اتحفظ (الأحدث أولًا) — null لو السجل فاضي.
  /// بتغذّي قسم "آخر ملخص" على الهوم.
  Future<SummaryModel?> latest();

  Future<void> save(SummaryModel model);

  Future<void> delete(String id);

  Future<void> clearAll();
}
