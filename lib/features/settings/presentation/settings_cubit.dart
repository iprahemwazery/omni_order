import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/store_settings.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'settings_state.dart';

/// يدير إعدادات المتجر (الاسم، الهاتف، العملة).
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const SettingsState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final settings = await _repository.getSettings();
      emit(SettingsState(settings: settings));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل الإعدادات', e)));
    }
  }

  Future<void> saveSettings(StoreSettings settings) async {
    await _repository.saveSettings(settings);
    emit(state.copyWith(settings: settings));
  }
}
