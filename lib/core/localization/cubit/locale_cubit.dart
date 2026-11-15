import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants/storage_keys.dart';
import '../../services/local_storage_service.dart';
import 'locale_state.dart';

/// بيبدّل لغة الواجهة (عربي/إنجليزي) وبيحفظها محليًا.
class LocaleCubit extends Cubit<LocaleState> {
  final LocalStorageService storage;

  LocaleCubit(this.storage) : super(const LocaleState());

  /// تحميل اللغة المحفوظة قبل أول إطار — يمنع لمعان اللغة الغلط.
  Future<void> ensureLoaded() async {
    final saved = storage.getString(StorageKeys.locale);
    if (saved == 'ar') {
      emit(const LocaleState(languageCode: 'ar'));
    } else if (saved == 'en') {
      emit(const LocaleState(languageCode: 'en'));
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'ar' && code != 'en') return;
    emit(state.copyWith(languageCode: code));
    await storage.setString(StorageKeys.locale, code);
  }

  Future<void> toggle() =>
      setLanguage(state.isArabic ? 'en' : 'ar');
}
