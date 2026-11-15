import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/summary_model.dart';

abstract class HistoryLocalDataSource {
  Future<List<SummaryModel>> loadAll();

  Future<void> save(SummaryModel model);

  Future<void> delete(String id);

  Future<void> clearAll();
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final LocalStorageService storage;

  static const int maxEntries = 50;

  const HistoryLocalDataSourceImpl(this.storage);

  @override
  Future<List<SummaryModel>> loadAll() async {
    try {
      final raw = storage.getString(StorageKeys.history);
      if (raw == null || raw.isEmpty) return const [];

      final list = await compute(_parseHistory, raw);

      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

      var needsRewrite = false;
      for (var i = 0; i < list.length; i++) {
        if (list[i].originalText.length > SummaryModel.maxStoredChars) {
          list[i] = list[i].trimmedForStorage();
          needsRewrite = true;
        }
      }
      if (needsRewrite) {
        await _writeAll(list);
      }

      return list;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(SummaryModel model) async {
    try {
      final all = await loadAll();

      final updated = [
        model,
        ...all.where((e) => e.id != model.id),
      ].take(maxEntries).toList();
      await _writeAll(updated);
    } catch (_) {}
  }

  @override
  Future<void> delete(String id) async {
    try {
      final all = await loadAll();
      final updated = all.where((e) => e.id != id).toList();
      await _writeAll(updated);
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    try {
      await storage.remove(StorageKeys.history);
    } catch (_) {}
  }

  static List<SummaryModel> _parseHistory(String raw) =>
      (jsonDecode(raw) as List<dynamic>)
          .map((e) => SummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<void> _writeAll(List<SummaryModel> models) async {
    final json = await compute(_encodeHistory, models);
    await storage.setString(StorageKeys.history, json);
  }

  static String _encodeHistory(List<SummaryModel> models) =>
      jsonEncode(models.map((m) => m.toJson()).toList());
}
