import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/hall.dart';
import '../../../domain/models/summaries.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/halls_usecases.dart';

class HallsState {
  final List<Hall> halls;
  final bool loading;
  final String? error;

  const HallsState({this.halls = const [], this.loading = false, this.error});

  HallsState copyWith({List<Hall>? halls, bool? loading, String? error}) {
    return HallsState(
      halls: halls ?? this.halls,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class HallsCubit extends Cubit<HallsState> {
  HallsCubit(
    this._repository, {
    GetHalls? getHalls,
    AddHall? addHall,
    UpdateHall? updateHall,
    DeleteHall? deleteHall,
    ToggleHallActive? toggleHallActive,
    GetHallDailyReport? getHallDailyReport,
  }) : _getHalls = getHalls,
       _addHall = addHall,
       _updateHall = updateHall,
       _deleteHall = deleteHall,
       _toggleHallActive = toggleHallActive,
       _getHallDailyReport = getHallDailyReport,
       super(const HallsState());

  final StoreRepository _repository;
  final GetHalls? _getHalls;
  final AddHall? _addHall;
  final UpdateHall? _updateHall;
  final DeleteHall? _deleteHall;
  final ToggleHallActive? _toggleHallActive;
  final GetHallDailyReport? _getHallDailyReport;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final halls = await (_getHalls?.call() ?? _repository.getHalls());
      emit(HallsState(halls: halls));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل الصالات: $e'));
    }
  }

  Future<int> addHall(String name, {int capacity = 0}) async {
    final hall = Hall(name: name, capacity: capacity);
    final id = _addHall != null
        ? await _addHall(hall)
        : await _repository.addHall(hall);
    await init();
    return id;
  }

  Future<void> updateHall(Hall hall) async {
    if (_updateHall != null) {
      await _updateHall(hall);
    } else {
      await _repository.updateHall(hall);
    }
    await init();
  }

  Future<void> deleteHall(int id) async {
    if (_deleteHall != null) {
      await _deleteHall(id);
    } else {
      await _repository.deleteHall(id);
    }
    await init();
  }

  Future<void> toggleActive(Hall hall) async {
    if (_toggleHallActive != null) {
      await _toggleHallActive(hall);
    } else {
      await _repository.updateHall(hall.copyWith(isActive: !hall.isActive));
    }
    await init();
  }

  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date) async {
    return await (_getHallDailyReport?.call(hallId, date) ??
        _repository.getHallDailyReport(hallId, date));
  }
}
