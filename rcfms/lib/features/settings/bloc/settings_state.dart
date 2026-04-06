import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool emailNotificationsEnabled;
  final bool pushNotificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.emailNotificationsEnabled = true,
    this.pushNotificationsEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? emailNotificationsEnabled,
    bool? pushNotificationsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }

  @override
  List<Object> get props =>
      [themeMode, emailNotificationsEnabled, pushNotificationsEnabled];
}
