import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/queue_entry.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/queue_usecases.dart';

/// يدير حالة قائمة الانتظار.
class QueueCubit extends Cubit<QueueState> {
  QueueCubit({
    required StoreRepository repository,
    GetQueueEntriesUseCase? getQueueEntries,
    AddQueueEntryUseCase? addQueueEntry,
    UpdateQueueEntryStatusUseCase? updateQueueEntryStatus,
    DeleteQueueEntryUseCase? deleteQueueEntry,
  }) : _repository = repository,
       _getQueueEntries = getQueueEntries,
       _addQueueEntry = addQueueEntry,
       _updateQueueEntryStatus = updateQueueEntryStatus,
       _deleteQueueEntry = deleteQueueEntry,
       super(const QueueState());

  final StoreRepository _repository;
  final GetQueueEntriesUseCase? _getQueueEntries;
  final AddQueueEntryUseCase? _addQueueEntry;
  final UpdateQueueEntryStatusUseCase? _updateQueueEntryStatus;
  final DeleteQueueEntryUseCase? _deleteQueueEntry;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final entries =
          await (_getQueueEntries?.call() ?? _repository.getQueueEntries());
      emit(state.copyWith(entries: entries, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addEntry(QueueEntry entry) async {
    try {
      if (_addQueueEntry != null) {
        await _addQueueEntry(entry);
      } else {
        await _repository.addQueueEntry(entry);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateStatus(int id, QueueStatus status) async {
    try {
      if (_updateQueueEntryStatus != null) {
        await _updateQueueEntryStatus(id: id, status: status);
      } else {
        await _repository.updateQueueEntryStatus(id, status);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      if (_deleteQueueEntry != null) {
        await _deleteQueueEntry(id);
      } else {
        await _repository.deleteQueueEntry(id);
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

class QueueState {
  const QueueState({this.entries = const [], this.loading = false, this.error});

  final List<QueueEntry> entries;
  final bool loading;
  final String? error;

  List<QueueEntry> get waiting =>
      entries.where((e) => e.status == QueueStatus.waiting).toList();

  List<QueueEntry> get seating =>
      entries.where((e) => e.status == QueueStatus.seating).toList();

  QueueState copyWith({
    List<QueueEntry>? entries,
    bool? loading,
    String? error,
  }) {
    return QueueState(
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
