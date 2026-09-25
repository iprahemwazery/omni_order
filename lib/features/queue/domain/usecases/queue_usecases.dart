import '../../../../domain/models/queue_entry.dart';
import '../repositories/queue_repository.dart';

class GetQueueEntriesUseCase {
  const GetQueueEntriesUseCase(this._repository);

  final QueueRepository _repository;

  Future<List<QueueEntry>> call() => _repository.getQueueEntries();
}

class GetWaitingQueueUseCase {
  const GetWaitingQueueUseCase(this._repository);

  final QueueRepository _repository;

  Future<List<QueueEntry>> call() async {
    final entries = await _repository.getQueueEntries();
    return entries
        .where((entry) => entry.status == QueueStatus.waiting)
        .toList(growable: false);
  }
}

class AddQueueEntryUseCase {
  const AddQueueEntryUseCase(this._repository);

  final QueueRepository _repository;

  Future<int> call(QueueEntry entry) {
    final normalized = _normalizeEntry(entry);
    _validateEntry(normalized);
    return _repository.addQueueEntry(normalized);
  }
}

class UpdateQueueEntryStatusUseCase {
  const UpdateQueueEntryStatusUseCase(this._repository);

  final QueueRepository _repository;

  Future<void> call({required int id, required QueueStatus status}) async {
    if (id <= 0) throw ArgumentError('معرف العنصر مطلوب.');
    final entries = await _repository.getQueueEntries();
    QueueEntry? current;
    for (final entry in entries) {
      if (entry.id == id) {
        current = entry;
        break;
      }
    }
    if (current == null) {
      throw StateError('العنصر غير موجود في قائمة الانتظار.');
    }
    _validateTransition(current.status, status);
    return _repository.updateQueueEntryStatus(id, status);
  }
}

class DeleteQueueEntryUseCase {
  const DeleteQueueEntryUseCase(this._repository);

  final QueueRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف العنصر مطلوب.');
    return _repository.deleteQueueEntry(id);
  }
}

QueueEntry _normalizeEntry(QueueEntry entry) => entry.copyWith(
  customerName: entry.customerName.trim(),
  customerPhone: entry.customerPhone.trim(),
  note: entry.note.trim(),
);

void _validateEntry(QueueEntry entry) {
  if (entry.customerName.isEmpty) {
    throw ArgumentError('اسم العميل مطلوب.');
  }
  if (entry.partySize <= 0) {
    throw ArgumentError('عدد الأشخاص يجب أن يكون أكبر من صفر.');
  }
}

void _validateTransition(QueueStatus current, QueueStatus next) {
  if (current == next) return;
  final allowed = switch (current) {
    QueueStatus.waiting =>
      next == QueueStatus.seating || next == QueueStatus.cancelled,
    QueueStatus.seating =>
      next == QueueStatus.done || next == QueueStatus.cancelled,
    QueueStatus.done || QueueStatus.cancelled => false,
  };
  if (!allowed) {
    throw StateError('لا يمكن تغيير حالة العنصر إلى الحالة المطلوبة.');
  }
}
