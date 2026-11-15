import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';
import '../models/summary_model.dart';

/// تنفيذ مستودع السجل — واجهة الدومين فوق التخزين المحلي.
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource localDataSource;

  const HistoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<SummaryModel>> getAll() => localDataSource.loadAll();

  @override
  Future<SummaryModel?> latest() async {
    // loadAll بترجّع الأحدث أولًا — أول عنصر هو آخر ملخص.
    final all = await localDataSource.loadAll();
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<void> save(SummaryModel model) => localDataSource.save(model);

  @override
  Future<void> delete(String id) => localDataSource.delete(id);

  @override
  Future<void> clearAll() => localDataSource.clearAll();
}
