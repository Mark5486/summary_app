import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// حالة الثيم — يتبع النظام افتراضيًا.
class ThemeState extends Equatable {
  final ThemeMode mode;

  const ThemeState({this.mode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? mode}) =>
      ThemeState(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
