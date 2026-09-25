import '../../../../domain/models/admin.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Admin>> getAdmins() => _storeRepository.getAdmins();

  @override
  Future<Admin?> getAdminByUsername(String username) =>
      _storeRepository.getAdminByUsername(username);

  @override
  Future<int> addAdmin(Admin admin) => _storeRepository.addAdmin(admin);

  @override
  Future<void> updateAdmin(Admin admin) => _storeRepository.updateAdmin(admin);

  @override
  Future<void> deleteAdmin(int id) => _storeRepository.deleteAdmin(id);
}
