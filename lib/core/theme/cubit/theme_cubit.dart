import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/storage_keys.dart';
import '../../services/local_storage_service.dart';
import 'theme_state.dart';

/// بيدير الوضع الفاتح/الغامق وبيحفظه محليًا.
class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorageService storage;

  ThemeCubit(this.storage) : super(const ThemeState());

  /// تحميل الثيم المحفوظ قبل أول إطار — يمنع وميض الثيم الغلط.
  Future<void> ensureLoaded() async {
    final saved = storage.getString(StorageKeys.themeMode);
    switch (saved) {
      case 'light':
        emit(state.copyWith(mode: ThemeMode.light));
      case 'dark':
        emit(state.copyWith(mode: ThemeMode.dark));
      // null أو أي قيمة تانية → يتبع النظام (الحالة الافتراضية).
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(state.copyWith(mode: mode));
    final saved = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => null,
    };
    if (saved == null) {
      await storage.remove(StorageKeys.themeMode);
    } else {
      await storage.setString(StorageKeys.themeMode, saved);
    }
  }

  Future<void> toggle() => setMode(
        state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}
