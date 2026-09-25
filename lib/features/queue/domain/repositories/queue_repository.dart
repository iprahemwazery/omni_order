import '../../../../domain/models/queue_entry.dart';

abstract interface class QueueRepository {
  Future<List<QueueEntry>> getQueueEntries();

  Future<int> addQueueEntry(QueueEntry entry);

  Future<void> updateQueueEntryStatus(int id, QueueStatus status);

  Future<void> deleteQueueEntry(int id);
}
