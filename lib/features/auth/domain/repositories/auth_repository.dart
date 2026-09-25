import '../../../../domain/models/admin.dart';

abstract interface class AuthRepository {
  Future<List<Admin>> getAdmins();
  Future<Admin?> getAdminByUsername(String username);
  Future<int> addAdmin(Admin admin);
  Future<void> updateAdmin(Admin admin);
  Future<void> deleteAdmin(int id);
}
