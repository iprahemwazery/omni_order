import '../../../../domain/models/reservation.dart';

abstract interface class ReservationRepository {
  Future<List<Reservation>> getReservations();

  Future<int> createReservation(Reservation reservation);

  Future<void> updateReservationStatus(int id, ReservationStatus status);

  Future<void> deleteReservation(int id);
}
