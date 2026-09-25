import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/reservation.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/reservation_usecases.dart';

/// يدير حالة حجوزات الترابيزات.
class ReservationsCubit extends Cubit<ReservationsState> {
  ReservationsCubit({
    required StoreRepository repository,
    GetReservationsUseCase? getReservations,
    CreateReservationUseCase? createReservation,
    UpdateReservationStatusUseCase? updateReservationStatus,
    DeleteReservationUseCase? deleteReservation,
  }) : _repository = repository,
       _getReservations = getReservations,
       _createReservation = createReservation,
       _updateReservationStatus = updateReservationStatus,
       _deleteReservation = deleteReservation,
       super(const ReservationsState());

  final StoreRepository _repository;
  final GetReservationsUseCase? _getReservations;
  final CreateReservationUseCase? _createReservation;
  final UpdateReservationStatusUseCase? _updateReservationStatus;
  final DeleteReservationUseCase? _deleteReservation;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final reservations =
          await (_getReservations?.call() ?? _repository.getReservations());
      emit(state.copyWith(reservations: reservations, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addReservation(Reservation reservation) async {
    try {
      if (_createReservation != null) {
        await _createReservation(reservation);
      } else {
        await _repository.createReservation(reservation);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateStatus(int id, ReservationStatus status) async {
    try {
      if (_updateReservationStatus != null) {
        await _updateReservationStatus(id: id, status: status);
      } else {
        await _repository.updateReservationStatus(id, status);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteReservation(int id) async {
    try {
      if (_deleteReservation != null) {
        await _deleteReservation(id);
      } else {
        await _repository.deleteReservation(id);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

class ReservationsState {
  const ReservationsState({
    this.reservations = const [],
    this.loading = false,
    this.error,
  });

  final List<Reservation> reservations;
  final bool loading;
  final String? error;

  List<Reservation> get active => reservations
      .where((r) => r.status == ReservationStatus.confirmed)
      .toList();

  List<Reservation> get seated =>
      reservations.where((r) => r.status == ReservationStatus.seated).toList();

  ReservationsState copyWith({
    List<Reservation>? reservations,
    bool? loading,
    String? error,
  }) {
    return ReservationsState(
      reservations: reservations ?? this.reservations,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
