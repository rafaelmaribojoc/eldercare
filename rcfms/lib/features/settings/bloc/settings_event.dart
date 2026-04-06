import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class ChangeTheme extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeTheme(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class ToggleEmailNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleEmailNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class TogglePushNotifications extends SettingsEvent {
  final bool enabled;

  const TogglePushNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}
