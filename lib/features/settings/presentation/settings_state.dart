import 'package:equatable/equatable.dart';

import '../../../../domain/models/store_settings.dart';

/// حالة إعدادات المتجر.
class SettingsState extends Equatable {
  const SettingsState({
    this.settings = StoreSettings.empty,
    this.loading = false,
    this.error,
  });

  final StoreSettings settings;
  final bool loading;
  final String? error;

  SettingsState copyWith({
    StoreSettings? settings,
    bool? loading,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [settings, loading, error];
}
