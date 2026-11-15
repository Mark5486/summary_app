import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final String languageCode;

  const LocaleState({this.languageCode = 'ar'});

  bool get isArabic => languageCode == 'ar';

  LocaleState copyWith({String? languageCode}) =>
      LocaleState(languageCode: languageCode ?? this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
