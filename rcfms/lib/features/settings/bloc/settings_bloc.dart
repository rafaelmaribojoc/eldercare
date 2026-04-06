import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeTheme>(_onChangeTheme);
    on<ToggleEmailNotifications>(_onToggleEmailNotifications);
    on<TogglePushNotifications>(_onTogglePushNotifications);

    // Initial load
    add(const LoadSettings());
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      // Load local prefs
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString('theme_mode');
      if (themeName != null) {
        final themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeName,
          orElse: () => ThemeMode.light,
        );
        emit(state.copyWith(themeMode: themeMode));
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select('email_notifications_enabled')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final emailEnabled =
            response['email_notifications_enabled'] as bool? ?? true;
        // Keep the loaded theme mode
        emit(state.copyWith(
          emailNotificationsEnabled: emailEnabled,
          themeMode: state.themeMode,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading settings: $e');
      }
    }
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(themeMode: event.themeMode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', event.themeMode.toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving theme: $e');
      }
    }
  }

  Future<void> _onToggleEmailNotifications(
      ToggleEmailNotifications event, Emitter<SettingsState> emit) async {
    // Optimistic update
    emit(state.copyWith(emailNotificationsEnabled: event.enabled));

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'email_notifications_enabled': event.enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating email preference: $e');
      }
      // Revert on failure? For now, let's keep it optimistic.
    }
  }

  void _onTogglePushNotifications(
      TogglePushNotifications event, Emitter<SettingsState> emit) {
    emit(state.copyWith(pushNotificationsEnabled: event.enabled));
    // Persist push pref if needed
  }
}
