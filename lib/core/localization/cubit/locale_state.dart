import 'package:equatable/equatable.dart';

/// حالة اللغة — 'ar' افتراضي و 'en' بديل.
class LocaleState extends Equatable {
  final String languageCode;

  const LocaleState({this.languageCode = 'ar'});

  bool get isArabic => languageCode == 'ar';

  LocaleState copyWith({String? languageCode}) =>
      LocaleState(languageCode: languageCode ?? this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
