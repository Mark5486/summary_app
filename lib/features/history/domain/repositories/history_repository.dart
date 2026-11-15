import '../../data/models/summary_model.dart';

abstract class HistoryRepository {
  Future<List<SummaryModel>> getAll();

  Future<SummaryModel?> latest();

  Future<void> save(SummaryModel model);

  Future<void> delete(String id);

  Future<void> clearAll();
}
