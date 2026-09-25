import '../../../../domain/models/reservation.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/reservation_repository.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  const ReservationRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Reservation>> getReservations() =>
      _storeRepository.getReservations();

  @override
  Future<int> createReservation(Reservation reservation) =>
      _storeRepository.createReservation(reservation);

  @override
  Future<void> updateReservationStatus(int id, ReservationStatus status) =>
      _storeRepository.updateReservationStatus(id, status);

  @override
  Future<void> deleteReservation(int id) =>
      _storeRepository.deleteReservation(id);
}
