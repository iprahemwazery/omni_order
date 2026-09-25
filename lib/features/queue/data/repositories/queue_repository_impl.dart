import '../../../../domain/models/queue_entry.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  const QueueRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<QueueEntry>> getQueueEntries() =>
      _storeRepository.getQueueEntries();

  @override
  Future<int> addQueueEntry(QueueEntry entry) =>
      _storeRepository.addQueueEntry(entry);

  @override
  Future<void> updateQueueEntryStatus(int id, QueueStatus status) =>
      _storeRepository.updateQueueEntryStatus(id, status);

  @override
  Future<void> deleteQueueEntry(int id) =>
      _storeRepository.deleteQueueEntry(id);
}
