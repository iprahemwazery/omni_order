import '../../../../domain/models/reservation.dart';
import '../repositories/reservation_repository.dart';

class GetReservationsUseCase {
  const GetReservationsUseCase(this._repository);

  final ReservationRepository _repository;

  Future<List<Reservation>> call() => _repository.getReservations();
}

class GetReservationsByStatusUseCase {
  const GetReservationsByStatusUseCase(this._repository);

  final ReservationRepository _repository;

  Future<List<Reservation>> call([ReservationStatus? status]) async {
    final reservations = await _repository.getReservations();
    if (status == null) return reservations;
    return reservations
        .where((reservation) => reservation.status == status)
        .toList(growable: false);
  }
}

class CreateReservationUseCase {
  const CreateReservationUseCase(this._repository);

  final ReservationRepository _repository;

  Future<int> call(Reservation reservation) {
    final normalized = _normalizeReservation(reservation);
    _validateReservation(normalized);
    return _repository.createReservation(normalized);
  }
}

class UpdateReservationStatusUseCase {
  const UpdateReservationStatusUseCase(this._repository);

  final ReservationRepository _repository;

  Future<void> call({
    required int id,
    required ReservationStatus status,
  }) async {
    if (id <= 0) throw ArgumentError('معرف الحجز مطلوب.');
    final reservations = await _repository.getReservations();
    Reservation? current;
    for (final reservation in reservations) {
      if (reservation.id == id) {
        current = reservation;
        break;
      }
    }
    if (current == null) throw StateError('الحجز غير موجود.');
    _validateTransition(current.status, status);
    return _repository.updateReservationStatus(id, status);
  }
}

class DeleteReservationUseCase {
  const DeleteReservationUseCase(this._repository);

  final ReservationRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف الحجز مطلوب.');
    return _repository.deleteReservation(id);
  }
}

Reservation _normalizeReservation(Reservation reservation) =>
    reservation.copyWith(
      customerName: reservation.customerName.trim(),
      customerPhone: reservation.customerPhone.trim(),
      note: reservation.note.trim(),
    );

void _validateReservation(Reservation reservation) {
  if (reservation.tableId <= 0) {
    throw ArgumentError('رقم التربة مطلوب.');
  }
  if (reservation.tableNumber <= 0) {
    throw ArgumentError('رقم التربة مطلوب.');
  }
  if (reservation.customerName.isEmpty) {
    throw ArgumentError('اسم العميل مطلوب.');
  }
  if (reservation.partySize <= 0) {
    throw ArgumentError('عدد الأشخاص يجب أن يكون أكبر من صفر.');
  }
}

void _validateTransition(ReservationStatus current, ReservationStatus next) {
  if (current == next) return;
  final allowed = switch (current) {
    ReservationStatus.confirmed =>
      next == ReservationStatus.seated || next == ReservationStatus.cancelled,
    ReservationStatus.seated =>
      next == ReservationStatus.completed ||
          next == ReservationStatus.cancelled,
    ReservationStatus.cancelled || ReservationStatus.completed => false,
  };
  if (!allowed) {
    throw StateError('لا يمكن تغيير حالة الحجز إلى الحالة المطلوبة.');
  }
}
