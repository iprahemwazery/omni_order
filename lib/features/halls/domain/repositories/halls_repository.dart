import '../../../../domain/models/hall.dart';
import '../../../../domain/models/summaries.dart';

abstract interface class HallsRepository {
  Future<List<Hall>> getHalls();

  Future<int> addHall(Hall hall);

  Future<void> updateHall(Hall hall);

  Future<void> deleteHall(int id);

  Future<HallDailyReport> getHallDailyReport(int hallId, DateTime date);
}
