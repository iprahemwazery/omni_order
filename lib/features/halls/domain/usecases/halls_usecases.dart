import '../../../../domain/models/hall.dart';
import '../../../../domain/models/summaries.dart';
import '../repositories/halls_repository.dart';

class GetHalls {
  const GetHalls(this._repository);

  final HallsRepository _repository;

  Future<List<Hall>> call({bool activeOnly = false}) async {
    final halls = await _repository.getHalls();
    if (!activeOnly) return halls;
    return halls.where((hall) => hall.isActive).toList(growable: false);
  }
}

class AddHall {
  const AddHall(this._repository);

  final HallsRepository _repository;

  Future<int> call(Hall hall) {
    _validateHall(hall);
    return _repository.addHall(hall.copyWith(name: hall.name.trim()));
  }
}

class UpdateHall {
  const UpdateHall(this._repository);

  final HallsRepository _repository;

  Future<void> call(Hall hall) {
    _validateHall(hall, requireId: true);
    return _repository.updateHall(hall.copyWith(name: hall.name.trim()));
  }
}

class DeleteHall {
  const DeleteHall(this._repository);

  final HallsRepository _repository;

  Future<void> call(int hallId) {
    _requirePositiveId(hallId);
    return _repository.deleteHall(hallId);
  }
}

class ToggleHallActive {
  const ToggleHallActive(this._repository);

  final HallsRepository _repository;

  Future<void> call(Hall hall) {
    if (hall.id == null) {
      throw ArgumentError.value(hall.id, 'id', 'is required');
    }
    return _repository.updateHall(hall.copyWith(isActive: !hall.isActive));
  }
}

class GetHallDailyReport {
  const GetHallDailyReport(this._repository);

  final HallsRepository _repository;

  Future<HallDailyReport> call(int hallId, DateTime date) {
    _requirePositiveId(hallId);
    return _repository.getHallDailyReport(
      hallId,
      DateTime(date.year, date.month, date.day),
    );
  }
}

void _validateHall(Hall hall, {bool requireId = false}) {
  if (requireId) _requirePositiveId(hall.id ?? 0);
  if (hall.name.trim().isEmpty) {
    throw ArgumentError.value(hall.name, 'name', 'must not be empty');
  }
  if (hall.capacity < 0) {
    throw ArgumentError.value(hall.capacity, 'capacity', 'is invalid');
  }
}

void _requirePositiveId(int id) {
  if (id <= 0) {
    throw ArgumentError.value(id, 'id', 'must be greater than zero');
  }
}
