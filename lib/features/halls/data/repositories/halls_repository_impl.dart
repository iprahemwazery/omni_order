import '../../../../domain/models/hall.dart';
import '../../../../domain/models/summaries.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/halls_repository.dart';

class HallsRepositoryImpl implements HallsRepository {
  const HallsRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Hall>> getHalls() => _storeRepository.getHalls();

  @override
  Future<int> addHall(Hall hall) => _storeRepository.addHall(hall);

  @override
  Future<void> updateHall(Hall hall) => _storeRepository.updateHall(hall);

  @override
  Future<void> deleteHall(int id) => _storeRepository.deleteHall(id);

  @override
  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date) =>
      _storeRepository.getHallDailyReport(hallId, date);
}
